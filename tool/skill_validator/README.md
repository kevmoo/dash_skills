# Skill Validator

This package is a helper tool to validate the skills defined in the `.agent/skills` directory.

It uses `dart_skills_lint` to enforce rules like relative paths, absolute paths, and trailing whitespace.

## Running Validation Locally

To run the validation tests locally, run:

```bash
dart test
```

This package is also run automatically in CI to ensure all skills meet the required standards.
