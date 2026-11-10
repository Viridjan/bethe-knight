# Documentation cleanup — 2026-11-07

## Result

- 50 source reports/audits merged into four topic files; source paths, SHA-256 hashes and section destinations are recorded in [MANIFEST.json](MANIFEST.json).
- All 50 full source bodies are preserved, with relative Markdown links rebased. Original Markdown entry points remain compatibility redirects, including their original heading anchors.
- One current task list: [TODO](../../TODO.md). One current implementation ledger: [IMPLEMENTATION_STATUS](../../docs/IMPLEMENTATION_STATUS.md). Historical completed checklists and unapproved idea catalogues moved into Project history.
- Documentation and report indexes distinguish current authoring guidance, implementation evidence, proposals and historical prompts.
- README resource tuning was updated to the delivered 27/+17 and 4/8/3 values. Old first-crossing, sword-placement, public-Web and HUD descriptions are labelled historical or corrected using explicit later direction and delivery evidence.
- Review-only Godot sidecars are ignored; source asset metadata and all evidence files remain intact. No runtime scripts, tests, scenes, room files, sprites, licences, logs, JSON fixtures or captured images were edited or deleted.

## Resolved decisions

The designer resolved both questions: preserve normal physics/input precision and cadence, and retain the newer 30% completed-block stress rule. [DOCUMENT_CONFLICTS.md](../../docs/DOCUMENT_CONFLICTS.md) records the decisions; AGENTS.md, CODE_GUIDE.md and the tick plan now agree. The tick migration remains unimplemented; this cleanup changes documentation only.

## Checks

- Preserved all 50 merged source bodies and verified their recorded source hashes.
- Checked rebased outgoing Markdown file links from all 50 records: no missing targets.
- Checked current documentation/report navigation and compatibility targets.
- `git diff --check` passes.
- Change scope is documentation plus `.gitignore`; no gameplay test rerun is warranted by these edits. Historical passing test logs remain labelled with their original provenance.

Existing knowledge indexes are stale after this cleanup. No Graphify rebuild or LightRAG operation was run; LightRAG's output location remains unspecified.
