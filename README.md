# spec@proveo

Conventions and an installable [Claude Code skill](skills/spec/SKILL.md) for authoring the
diagrams that document a proveo codebase.

> Keeping the code and throwing away the prompts is the 2025 equivalent of throwing away the source and
> keeping the binary.
>
> — Tobi Lütke, https://x.com/tobi/status/2009788652218695727

Specifications live under a project's `_spec/` directory and are linked from the code they describe, so
a reader (human or agent) can jump from a source file to the diagram of how it works — and so diagrams
are caught when the code they describe changes. Three formats share one identity (the proveo palette
and six semantic roles):

| Format | Extension | For |
| --- | --- | --- |
| **PlantUML** | `.puml` | architecture, component, deployment, sequence, state |
| **Mermaid** | `.mmd` | lightweight flow/state/topology that renders inline in GitHub & IDEs |
| **Vega-Lite** | `.vega.json` | data charts — bars, lines, heatmaps |

This repo used to ship a Dockerized PlantUML renderer (`install.sh` → `spec` CLI → container). That
approach is retired: modern coding agents render diagrams themselves, so the leverage is a **skill**
that teaches the conventions and how to render, not a container to maintain. (The old tooling lives in
git history.)

## Install — how an agent consumes this repo

The repo carries a `SKILL.md` (under `skills/spec/`) **and** Claude Code plugin manifests
(`.claude-plugin/plugin.json` + a single-plugin `.claude-plugin/marketplace.json`). That gives four
install paths — pick by which agent and how widely you want it.

**1. `skills` CLI** — cross-agent, one command (Claude Code, Codex, Cursor, OpenCode, and many more):

```bash
npx skills add proveo-ca/spec                                  # into the current project
npx skills add proveo-ca/spec -g                               # for the user (global)
npx skills add proveo-ca/spec -s spec -a claude-code    # one skill, one agent
```

This is the [vercel-labs `skills` CLI](https://github.com/vercel-labs/skills) / [skills.sh](https://skills.sh)
ecosystem. It discovers the `skills/spec/SKILL.md` layout (and also honors the `.claude-plugin`
manifests below), writing into the agent's skills dir — `.claude/skills/` for Claude Code, or
`~/.claude/skills/` with `-g`. Note the verb is **`add`**: plain
`npx skills proveo-ca/spec` does not resolve — use `npx skills add proveo-ca/spec`.

**2. Claude Code plugin marketplace** — native to Claude Code:

```text
/plugin marketplace add proveo-ca/spec
/plugin install spec@proveo
```

(`proveo` is the marketplace name declared in `marketplace.json`; `spec` is the plugin.)

**3. Project-pinned** — best for a team repo, so every Claude Code agent that opens the project gets it.
Add to the consuming project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "proveo": { "source": { "source": "github", "repo": "proveo-ca/spec" } }
  },
  "enabledPlugins": { "spec@proveo": true }
}
```

**4. Manual** — no tooling. Claude Code auto-discovers any `SKILL.md` under `~/.claude/skills/`
(personal) or `<project>/.claude/skills/` (project), so clone and symlink (or copy) the skill dir:

```bash
git clone https://github.com/proveo-ca/spec.git
ln -s "$PWD/spec/skills/spec" ~/.claude/skills/spec   # or: cp -r
```

However it's installed, the `spec` skill auto-activates whenever you work under `_spec/`,
author/edit a `.puml` / `.mmd` / `.vega.json` diagram, maintain `SPEC:` references, or ask about the
proveo theme. **Agents none of the above cover** can consume the repo through [`llms.txt`](llms.txt) —
point them at it (or the raw GitHub files it links) for the conventions, theme URLs, and examples.

> Maintaining/distributing this skill? See [`PUBLISHING.md`](PUBLISHING.md) for the per-channel publish
> steps (skills.sh, Claude Code, OpenCode, cecli) and the prerequisite of hosting it at `proveo-ca/spec`.

## Theme delivery — hybrid

The identity theme is owned upstream at [`proveo-ca/identity`](https://github.com/proveo-ca/identity).
PlantUML can pull it remotely; Mermaid and Vega-Lite cannot, so they're vendored:

- **PlantUML** — remote include (auto-tracks upstream):
  ```puml
  !include https://raw.githubusercontent.com/proveo-ca/identity/main/proveo.puml
  ' dark: proveo-dark.puml
  ```
- **Mermaid / Vega-Lite** — vendor into the project's `_spec/themes/`:
  ```bash
  bash skills/spec/scripts/fetch-themes.sh   # run from the project root
  ```
  Then prepend `proveo.mermaid`'s `%%{init}%%` block to each `.mmd`, and use `proveo.vega.json` as a
  chart's `config`.

## The six roles

Color is semantic. Tag a node by role (`<<app>>` in PlantUML, `:::app` in Mermaid, category order in
Vega-Lite) and the color follows:

| Role | Meaning | Color |
| --- | --- | --- |
| `app` | first-party app / runtime service | `#005F7F` teal |
| `async` | queue / event-driven / background | `#CBDB2A` lime |
| `host` | host / platform / operator boundary | `#00BAC6` cyan |
| `cloud` | external / third-party / vendor | `#585858` slate |
| `db` | persistence / state store | `#E5E4E4` light |
| `error` | failure / destructive / dangerous | `#CB2000` red |

## Conventions (depth)

The full conventions live in the skill so an agent loads only what it needs:

- [references/plantuml.md](skills/spec/references/plantuml.md) — stereotypes, `ARROW_*` macros, Creole text, layout, validation gotchas, and the `SPEC:` reference lifecycle.
- [references/mermaid.md](skills/spec/references/mermaid.md) — `%%{init}%%` theming and role classes.
- [references/vega-lite.md](skills/spec/references/vega-lite.md) — config theming and palette ranges.
- [references/rendering.md](skills/spec/references/rendering.md) — install + validate + render for all three.

See [`llms.txt`](llms.txt) for the machine-readable index, and [`_spec/`](_spec/) for worked examples
in all three formats.

## SPEC references in code

Link a source file to its diagram on a single top-line comment (comma-separate multiple diagrams):

```ts
// SPEC: _spec/apps/web/model-grid/row-loading-lifecycle.puml
```

Every new `.puml` must be referenced from at least one source file; when source moves, move the
comment, not the diagram. The full lifecycle rules are in
[references/plantuml.md](skills/spec/references/plantuml.md).
