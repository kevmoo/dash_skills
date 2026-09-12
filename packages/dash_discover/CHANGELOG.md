## 0.1.0-wip

- Initial release of the Dash Meta-Skill Discovery Engine.
- Modular, object-oriented discovery rule architecture (`DiscoveryRule`, `FileDiscoveryRule`).
- Built-in `SkillTarget` model with explicit GitHub repository provenance and commit SHA tracking.
- Fast package context scanning and LLM outline prompt synthesis.
- Strengthened rule types: marked all rule classes `final`, introduced typed `RuleCategory`, `SkillLifecycle` (migration vs. hygiene vs. architecture), and `Confidence` metrics.
- Added `--category` and `--lifecycle` CLI filter flags to `dash_discover`.
- Removed synthetic `Priority` enum in favor of deterministic sorting by `SkillLifecycle`, `Confidence`, and affected file count.
