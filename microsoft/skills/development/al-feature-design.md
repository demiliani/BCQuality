---
kind: action-skill
id: al-feature-design
version: 4
title: AL feature design (experimental)
description: Turns a Business Central feature request into a knowledge-grounded design (objects, data flow, event subscriptions, lifecycle steps and tests) before any code is written.
inputs: [feature-request, repository]
outputs: [feature-design-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL feature design (experimental)

Produces a design for a new Business Central feature from a plain-language request. Where `al-development-plan` enriches a plan that already exists, this skill creates the design itself: which objects to create or extend, how data moves through standard processes, which events to subscribe to, which lifecycle steps are needed, and which tests prove it works. Every design element cites the BCQuality articles it rests on.

The skill is read-only. It does not write code, edit the target repository or generate files inside it. Its report is the input for the implementing agent and for a person who approves the design.

A non-empty `feature-request` is required. Return `not-applicable` when it is absent or does not describe a change to Business Central behavior. A readable `repository` is optional but recommended.

## Source

Read the BCQuality knowledge index once, using the external path supplied by Entry when present. Within the BCQuality checkout, read only the knowledge layers, `skills/`, `schemas/` and `tools/`; never read or search `evaluation/`, whose fixtures and examples would bias the design. If no index is available, use READ's path-based discovery across enabled layers; inability to read the corpus is `failed`, not `no-knowledge`. The index supplies candidate paths, keywords, titles and descriptions; it never substitutes for opening selected articles in full.

When a repository is supplied, inspect it read-only for `app.json` (target version, ID ranges, dependencies), existing table and page extensions of the objects the request names, existing event subscribers, permission sets, install and upgrade codeunits, and test apps. Reuse what exists; do not design a second object for a concern the app already covers. Without a repository, an object the request says already exists, such as an import routine or a field the lines "carry", is designed with `modify` and its plain name, and an open question asks for the real object; never invent its structure.

## Relevance

Apply READ's matching semantics using `bc-version` from `app.json` or the request, `technologies: [al]`, and `countries` and `application-area` from the request or repository. When a dimension cannot be resolved, list it in `context.unknown` and write `"unknown"` for `bc-version` or `[]` for a list dimension. READ admits conditionally applicable articles; keep one only when it changes a design decision, and state its condition in that article's `used-for`, for example "applies from BC24".

## Worklist

1. Copy the request verbatim into `summary.request`. In `summary.business-process`, restate it in one sentence and name the standard business process or first-party app it changes, such as sales posting, warehouse handling, journals or the Shopify Connector.
2. List the stages the request touches in that process: documents, posted documents, journals, ledger entries, archives, pages, reports, APIs, background work. A stage is **chosen** when the request requires it, or when an opened article requires it unless the request excludes it, such as mirroring a field on every `TransferFields` target. An article requires a stage when its Best Practice says the stage must be handled for the feature to work, such as mirroring a field on every `TransferFields` target; an article that only describes an option or a choice, such as which of two lines should win, does not choose the stage, and that choice becomes an open question. Design a stage chosen only by an article, and also raise an open question so the requester can exclude it; raise one question per group of such stages, such as all mirror targets of one field, not one per table. When neither the request nor an article settles a stage, do not design it; add an open question instead. When two articles pull in different directions, such as a stored ledger field against a related table, apply the condition each states and record the choice in the element's purpose. Most process articles describe several entry points into the same stage, such as manual entry and batch jobs, sales and purchase, refresh and planning, or several posting routines. Cover every entry point an opened article names for a chosen stage, or raise an open question for the ones the request may not need. For a feature that creates its own records rather than extending a standard process, the stages are the decisions its `feature-design` map lists, such as numbering, setup, pages and permissions; data-flow hops are needed only where data moves from one record to another.
3. Retrieve knowledge in two passes. Native reads of the index and articles are sufficient; READ's bounded-retrieval helpers are optional for this skill.
   - **Process pass.** Search the `feature-design` maps first: each one lists the decisions a kind of feature needs and links the articles for each, such as `plan-a-new-business-entity-end-to-end`. A request often needs several maps, such as a custom document with posting that is also printed and approved; open every map whose kind of feature the request contains, and follow a map's links to other maps. A map row that says it rests on judgment names a knowledge gap: design that decision without citing an article and name it in `unresolved`. Then search every domain whose articles describe a business process or a first-party app, taking the list of domains from the index rather than from this skill, using the process and stage names. Prefer articles that map a path or a mechanism, such as `plan-the-full-path-of-a-custom-sales-field`. Open the articles a map links for every decision the design takes.
   - **Cross-cutting pass.** Search for the concerns every feature carries: data modeling and field definitions, events and subscribers, setup and numbering, permissions, privacy and data classification, install and upgrade, UI, performance and testing.
4. Open every selected article in full, with the `.good.*` and `.bad.*` samples needed to make it concrete. In full means its frontmatter, Description, Best Practice and Anti Pattern; References may be skipped. Never cite an index row that was not opened. Resolve conflicts with READ's layer precedence and record losers in `suppressed`.
5. Keep the worklist focused: an article enters only when it changes a design decision, a guard, a test or an open question. Open an article because a map row or a search result matches a decision the request needs, not to browse a domain; when the worklist grows past about 30 articles, check each against that rule before opening more.

## Action

Build `design` from the opened knowledge:

- **objects** — one entry per object to create, extend, or modify when it already exists in the caller's own app, with fields for table extensions. Write the plain object name in `target`, without numbers or annotations. Apply field-mirroring rules exactly as the articles state them, such as the same field number and type on every `TransferFields` target.
- **data-flow** — one entry per hop the feature's data makes, naming the mechanism (`transferfields`, `event-copy`, `validate`, `user-entry`). Every stage chosen in Worklist step 2 must be reached by a hop.
- **subscriptions** — publisher, event and purpose, plus the guards the articles require, such as exiting on `PreviewMode`. Write the event name only in `event`, without its signature, and the publishing object in `publisher`. Name only events that appear in an opened article or its samples, or are confirmed in the repository's symbols, and never one that an opened article marks internal, OnPrem-only or obsolete. Never carry an event name, parameter, commit point or preview rule from one routine or document type to another by analogy, such as from sales posting to purchase or service posting; each routine needs its own article or goes to `unresolved`. An event the design needs but cannot confirm goes to `unresolved`; never invent an event name or signature.
- **lifecycle** — install, upgrade, setup, permission set, data classification and background-processing steps the feature needs.
- **dependencies** — every app the feature extends besides the base application, such as E-Document Core or the Shopify Connector, with the app id and publisher an opened article states. Leave the list empty when the feature extends only the base application.
- **tests** — Given/When/Then scenarios. Cover each data-flow hop at least once, by posting or running the process and reading the value back at the target, and cover each guard. Use the test-library guidance when it was selected. When an article says the standard process cannot be run from a test, for example because its codeunit is internal, test the subscriber's effect directly and say so in the test.

When an article states only what not to do, design the supported path it names, never the prohibition itself; if it names none, the element rests on judgment.

Every design element lists the knowledge paths it rests on. An element the request needs but no article supports keeps an empty `knowledge` list and is named in `unresolved` as not covered by BCQuality knowledge, so the reader knows it rests on the agent's judgment alone.

For each cited article, add a `knowledge` entry with `used-for` and the constraints it imposes, translated from its Best Practice and Anti Pattern without adding facts or weakening conditions. An article cited only because it settles routing or raises an open question stays in `knowledge`, with `used-for` saying so, and counts in `selected`. Put every fact the request leaves open in `open-questions`, with the ids of the objects, hops' targets or tests it affects; for a lifecycle step, which has no id, write `lifecycle:<concern>`, such as `lifecycle:setup`.

Before emitting, verify that every cited path and sample exists in the live BCQuality checkout and was opened during this run. If reference integrity cannot be established, return `failed`.

## Output

Return one `feature-design-report` conforming to [`schemas/feature-design-report.schema.json`](../../../schemas/feature-design-report.schema.json), as strict JSON with no surrounding commentary.

Set `summary.candidates` to the number of knowledge articles (`.md` files, including maps) opened in full, not counting samples or index rows, and `summary.selected` to the number cited in `knowledge`.

A gap is **material** when a chosen stage has no data-flow hop, or when the design needs an event it could not confirm. Unknown applicability dimensions, and elements that rest on the agent's judgment, are reported in `unresolved` but are not material.

`completed` requires at least one object, every chosen stage designed, every cited article opened, and no material gap. An element that rests on judgment keeps an empty `knowledge` list; do not attach a loosely related article to it. Open questions do not prevent `completed`; they are the questions a person must answer before implementation. `no-knowledge` means no BCQuality article applies to the request; emit no design rather than an unsupported one. Return `partial` when part of the request could be designed but material gaps remain, naming each gap. Retrieval or reference failures are `failed`.
