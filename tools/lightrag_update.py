#!/usr/bin/env python3
"""Bring the local LightRAG server (127.0.0.1:9621) up to date with the project's docs, re-indexing only what changed.

  python3 tools/lightrag_update.py            # upload new docs, re-index edited ones, drop deleted ones
  python3 tools/lightrag_update.py --dry-run  # only list what would happen

A doc counts as edited when its file is newer than its upload time in LightRAG; uploads are named after their path
with "/" replaced by "_" (docs/STORY_DESIGN.md -> docs_STORY_DESIGN.md). The answer cache is cleared at the end so
no stale answer is replayed. Indexing then runs in the background (a few minutes per doc on the local GPU).
"""
import glob
import json
import os
import sys
import time
import urllib.request
import uuid
from datetime import datetime

SERVER = "http://127.0.0.1:9621"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = ["README.md", "AGENTS.md", "TODO.md", "gdd.txt", "data/README.md", "assets/*/README.md",
           "docs/*.md", "docs/reviews/*.md", "docs/reviews/*/*.md", "docs/plans/*.md", "reports/consolidated/*.md"]


def call(method, path, body=None, content_type="application/json"):
    data = json.dumps(body).encode() if isinstance(body, (dict, list)) else body
    request = urllib.request.Request(SERVER + path, data=data, method=method, headers={"Content-Type": content_type})
    with urllib.request.urlopen(request, timeout=120) as response:
        return json.loads(response.read() or b"{}")


def indexed_docs():
    docs, page = {}, 1
    while True:
        reply = call("POST", "/documents/paginated", {"page": page, "page_size": 100})
        for doc in reply["documents"]:
            docs[doc["file_path"]] = doc
        if page >= reply.get("pagination", {}).get("total_pages", 1):
            return docs
        page += 1


def wait_idle():
    while call("GET", "/documents/pipeline_status").get("busy"):
        time.sleep(3)


def upload(path, name):
    boundary = uuid.uuid4().hex
    with open(os.path.join(ROOT, path), "rb") as f:
        body = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{name}\"\r\n"
                f"Content-Type: text/plain\r\n\r\n").encode() + f.read() + f"\r\n--{boundary}--\r\n".encode()
    return call("POST", "/documents/upload", body, f"multipart/form-data; boundary={boundary}")


def main():
    dry = "--dry-run" in sys.argv
    files = sorted({p for pattern in SOURCES for p in glob.glob(pattern, root_dir=ROOT)})
    names = {p.replace("/", "_"): p for p in files}
    docs = indexed_docs()
    new = [n for n in names if n not in docs]
    edited = [n for n in names if n in docs and os.path.getmtime(os.path.join(ROOT, names[n]))
              > datetime.fromisoformat(docs[n]["created_at"]).timestamp()]
    removed = [n for n in docs if n not in names]
    failed = [n for n in names if n in docs and docs[n]["status"] == "failed" and n not in edited]
    for label, group in [("new", new), ("edited", edited), ("removed", removed), ("failed before, retried", failed)]:
        for n in group:
            print(f"{label:24} {names.get(n, n)}")
    if not (new or edited or removed or failed):
        print("LightRAG is up to date.")
        return
    if dry:
        return
    stale = [docs[n]["id"] for n in edited + removed + failed]
    if stale:
        wait_idle()
        call("DELETE", "/documents/delete_document", {"doc_ids": stale, "delete_file": True})
        wait_idle()
    for n in new + edited + failed:
        upload(names[n], n)
    call("POST", "/documents/clear_cache", {})
    print(f"Queued {len(new) + len(edited) + len(failed)} upload(s), removed {len(removed)}; indexing continues in the "
          f"background ({SERVER}, or: curl -s {SERVER}/documents/status_counts).")


if __name__ == "__main__":
    try:
        main()
    except OSError as error:
        sys.exit(f"LightRAG not reachable at {SERVER} ({error}). Start it: systemctl --user start lightrag@summit")
