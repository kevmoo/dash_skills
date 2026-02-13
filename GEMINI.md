# Authoring and Maintaining Skills

This repository contains a curated collection of "skills" for the Gemini CLI and
other AI agents. Skills are modular, self-contained packages that extend an
agent's capabilities with specialized knowledge and workflows.

## Skill Structure

Each skill is located in `.agent/skills/<skill-name>/` and must contain a
`SKILL.md` file.

```
.agent/skills/<skill-name>/
├── SKILL.md (required)
├── scripts/ (optional)
├── references/ (optional)
└── assets/ (optional)
```

### `SKILL.md`

The `SKILL.md` file is the heart of the skill. It contains:
1.  **YAML Frontmatter**: Metadata including `name` and `description`. The
    description is critical as it's used by the agent to decide when to trigger
    the skill.
2.  **Markdown Instructions**: Procedural knowledge, examples, and workflows.

## Authoring Guidelines

-   **Be Concise**: Agents have limited context windows. Focus on information
    the agent doesn't already have.
-   **Imperative Tone**: Use imperative or infinitive form for instructions
    (e.g., "Use `isA<T>()` for type checks" instead of "You should use...").
-   **80-Column Rule**: Wrap all text in `.md` files to **80 characters**. This
    improves readability in terminals and split-pane editors.
-   **Examples Over Explanations**: Provide clear, realistic code snippets or
    interaction examples.
-   **Tool Integration**: If a skill uses scripts in `scripts/`, explain how
    the agent should invoke them.

## Maintaining Skills

-   **Keep Descriptions Accurate**: The frontmatter `description` is the only
    thing the agent reads *before* activating the skill. Ensure it clearly
    states the "when to use" scenarios.
-   **Test Scripts**: Ensure all scripts in `scripts/` are executable and
    produce LLM-friendly output.
-   **Update References**: Move detailed documentation or large schemas to the
    `references/` folder to keep the main `SKILL.md` lean.

## Adding a New Skill

1.  Create the directory: `.agent/skills/<my-new-skill>/`.
2.  Add `SKILL.md` with appropriate frontmatter.
3.  Add the skill to the `Available Skills` table in the root `README.md`.
4.  (Optional) Package the skill using `package_skill.cjs` if distribution as
    a `.skill` file is needed.
