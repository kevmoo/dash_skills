# dash_discover

Meta-skill discovery engine for Dart and Flutter workspaces.

## Features

- **Object-Oriented Discovery Rules**: Modular rules that inspect package
  structure, dependencies, and file contents.
- **Skill Provenance & Drift Tracking**: Explicit metadata tracking upstream
  repository targets and commit SHAs.
- **Fast Package Scanning**: Lightweight pre-indexing of `lib/`, `test/`, and
  `bin/` directories.
- **Interactive & Batch CLI**: Run static scans, output JSON, or synthesize LLM
  evaluation prompts.

## Usage

```bash
# Run discovery scan on a target workspace
dart run dash_discover:dash_discover /path/to/repo

# List available rules
dart run dash_discover:dash_discover --list-rules
```
