# Stress implementation — 2026-11-05

Implemented persistent 0–250 stress in a separate progression service. Death adds
20; entering stamina exhaustion adds 5 once; ordinary kills remove 50, bosses 100,
and permanent collectible acquisitions 100. Reusable resource refills remain
refills, not permanent collectibles. Boss victories and duplicate pickup callbacks
are guarded; boss relief does not also award ordinary-monster relief.

Recovery targets at 0/50/100/150/200/250 are 100/90/80/75/70/65%, interpolated between
points. Existing water/climbing/stun recovery restrictions remain. The HUD shows
five bars, current stress and recovery percentage. Screenshots show 0, 125 and 250.

Saved runs include stress, exhaustion state and last successful save timestamp.
Continue after at least twelve hours removes up to 100, committing the new stress
and timestamp together before granting it. Failed writes do neither. Old saves
start at zero stress and receive no retroactive rest bonus. Real Continue flow,
repeat-load protection and failed IO are covered by the integration tests.

The Kraken condition-report API tests a full base energy bar, 250 stress and an
explicit supplied underwater capability. Boat integration and the actual Kraken
fight are still planned; the condition helper does not create that encounter.

Verification:

- `tests/stress.tscn`: 0 failures, no script/engine errors; see stress-tests.log.
- Full `tools/verify.sh`: all checks pass except the existing Jungle Falls story-bot
  traversal failure; see verification.log. The two previously edited jungle room
  files were left untouched. The broad runner includes smoke, web, catalogue,
  Ape/Guardian gameplay, editors, save regressions, Python, lint and benchmark checks.
- Catalogue/discoveries/Ape follow-up fixtures report shutdown resource leak warnings.
- `git diff --check`: clean. HUD inspected at empty, partial and full stress.

Capture uses disposable user data and is never a normal player save.
