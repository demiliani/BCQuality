---
name: al-feature-design
description: Experimental. Design a new Business Central AL feature from a plain-language request before any code exists - objects, data flow through standard processes, event subscriptions, lifecycle steps and tests, each citing BCQuality knowledge. Read-only. Use when the caller describes a feature to build, not code to review.
---

# AL feature design (experimental)

This is BCQuality's host-native adapter for designing a feature before
implementation. It is experimental and its contract may change. It contains no
routing or knowledge-selection policy: it translates the caller's request into
an Entry task context and executes the resulting dispatch.

The adapter is read-only. It never writes code, edits source, or implements
the feature. It writes design files into the caller's repository only when the
caller asks for them (step 7).

## Execute

1. Resolve `PLUGIN_ROOT` to the directory containing this plugin's root
   `plugin.json`. This file is `PLUGIN_ROOT/skills/al-feature-design/SKILL.md`;
   when the host does not expose the plugin root, resolve it two levels above
   this file.
2. Identify the feature request: the caller's description of what to build, a
   file that holds it, or an issue the caller pasted. If none is available,
   ask the caller what the feature should do. Do not invent requirements.
3. Build the `task-context` required by `PLUGIN_ROOT/skills/entry.md`:
   - Copy the caller's actual request verbatim into `goal`.
   - Set `inputs-available` to `feature-request`, plus `repository` when the
     caller's AL repository or app folder is readable. Pass the complete
     request text as `feature-request` and the repository path as
     `repository`; for a request in the caller's working directory, use that
     directory. Never pass `PLUGIN_ROOT` itself as the repository.
   - Set `technologies: [al]`.
   - Pass `bc-version`, `countries`, and `application-area` only when supplied
     or reliably determined from the request or repository.
   - If `BCQUALITY_ENABLED_LAYERS` is set, split its comma-separated value and
     pass the trimmed, non-empty entries as `enabled-layers`; otherwise omit the
     field. If `BCQUALITY_DISABLED_SKILLS` is set, pass its entries as
     `disabled-skills`; otherwise omit the field.
4. Read and execute `PLUGIN_ROOT/skills/entry.md` exactly as written, including
   its Preparation step. Resolve every repo-relative path Entry names against
   `PLUGIN_ROOT`. Run Preparation's index build as
   `pwsh PLUGIN_ROOT/tools/Build-KnowledgeIndex.ps1`; if `PLUGIN_ROOT` is
   inside the caller's repository, pass `-IndexPath` to a location outside it.
   With no caller repository, build it at its default location. If `pwsh` is unavailable or the build fails, continue with READ's path-based
   discovery; a failed build is not empty knowledge.
5. Follow Entry's dispatch. Invoke only the returned action skills, pass each
   dispatch entry's exact input subset, and read `PLUGIN_ROOT/skills/read.md`
   and `PLUGIN_ROOT/skills/do.md` on demand.
6. If Entry returns `no-match` or `failed`, return its dispatch record
   unchanged and stop.
7. Present each dispatched feature-design report as a readable document:
   - Save the report JSON, unchanged, to a temporary location outside the
     caller's repository.
   - Run `pwsh PLUGIN_ROOT/tools/ConvertTo-FeatureDesignMarkdown.ps1
     -ReportPath <saved report>` and show its Markdown output to the caller
     as it is. Do not rewrite, shorten or reorder it.
   - If the caller asked for files, write the Markdown and the JSON where
     they asked. These are the only files this adapter writes in their
     repository. When the caller asked only for files, writing them and
     naming them is enough; do not repeat the Markdown.
   - If `pwsh` is unavailable, present the report yourself in the same
     order: questions to answer, objects, data flow, event subscriptions,
     setup and lifecycle, tests, limits, numbered sources. Add nothing the
     report does not contain.
   - Tell the caller where the JSON is, for tools and pipelines that need it.

The internal `microsoft/skills/development/al-feature-design.md` action skill
selects the knowledge and builds the design. This adapter never selects
articles itself.

## Using the result

Have a person answer the report's open questions and approve the design. Then
give the design to the agent that implements it. After implementation, review
the change with `al-code-review`; the design is input to the work, not proof
that the result is correct.
