# Testing in this Repository

This repository is attempting to follow the 10 layers of testing described in
the "Skillify" [workflow for AI agents](https://x.com/i/status/2046876981711769720).
We aim to make every skill robust and self-contained with appropriate tests.

## Implemented Layers

Here are the layers currently implemented in this repository, with examples:

### Layer 1: SKILL.md (Contract)
Every skill in this repository has a `SKILL.md` file defining its contract, triggers, and rules.

### Layer 2: Deterministic Code (Scripts)
Some skills have deterministic scripts to handle precise work.
- **Example**: [interpret_coverage.dart](../.agent/skills/dart-test-coverage/scripts/interpret_coverage.dart)

### Layer 3: Unit Tests
We have unit tests for the deterministic scripts associated with skills.
- **Example**: [interpret_coverage_test.dart](../.agent/skills/dart-test-coverage/scripts/test/interpret_coverage_test.dart)

### Layer 8: Check Resolvable + DRY Audit (Partial)
We have a skill validator that checks for basic standards like path validity and
formatting. It does not check for reachability from a resolver or for duplicate
logic across skills.
- **Example**: [validate_skills_test.dart](skill_validator/test/validate_skills_test.dart)

## Unimplemented Layers

The following layers from the [Skillify workflow](https://x.com/i/status/2046876981711769720) are not yet implemented in this repository:

### Layer 4: Integration Tests
Tests that hit live endpoints and real data to catch bugs that unit tests might miss due to clean fixture data.

### Layer 5: LLM Evals
Uses a model to evaluate another model's output against a rubric for tasks that require judgment (e.g., "Is this summary useful?").

### Layer 6: Resolver Trigger
Entries in a routing table that teach the agent what skills exist and when to load them based on the task type.

### Layer 7: Resolver Eval
Tests to verify that intent phrases actually route to the correct skill and that triggers do not overlap ambiguously.

### Layer 9: E2E Smoke Test
Tests the full pipeline by asking the agent a question and verifying that it runs the correct script and returns the right answer.

### Layer 10: Brain Filing Rules
Rules that guide skills on where to write data in the knowledge base to maintain organization.

## How to Run Tests

### Running Skill Tests
Skill tests are colocated with the skills in their `scripts/` directory. To run tests for a specific skill:

1. Navigate to the skill's `scripts` directory:
   ```bash
   cd .agent/skills/dart-test-coverage/scripts
   ```
2. Run the tests:
   ```bash
   dart test
   ```

### Running the Skill Validator
The skill validator is a central tool that ensures all skills meet the required standards and also discovers and runs skill tests automatically.

To run the validator:
1. Navigate to the validator directory:
   ```bash
   cd tool/skill_validator
   ```
2. Run the tests:
   ```bash
   dart test
   ```
   This will run the validation checks and also discover and execute any tests found in skill `scripts/` directories.
