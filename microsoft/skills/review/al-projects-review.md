---
kind: action-skill
id: al-projects-review
version: 1
title: AL projects review
description: Reviews AL extensions of project (job) processes against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL projects review

Reviews AL source changes against the `projects` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain projects`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: table extensions of `Job Journal Line`, `Job Ledger Entry` or `Job Planning Line`, or event subscribers to `Job Transfer Line`, `Job Jnl.-Post Line` or `Job Post-Line`; code or subscribers touching `Job Create-Invoice`, `Job Planning Line Invoice`, `Job Calculate WIP`, `Job Task` WIP fields, WIP method enums, time sheet tables, `Time Sheet Management`, `Suggest Job Jnl. Lines`, `Move Time Sheets to Archive`, `Res. Journal Line`, `Res. Ledger Entry` or `Res. Jnl.-Post Line`. Also review inputs that extend `Purchase Line` together with `Job Ledger Entry`, create purchase lines with a `Job No.`, or extend `Res. Journal Line` or `Res. Ledger Entry`.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `projects` articles:

- A subscriber to `OnAfterJobLedgEntryInsert` modifies the `Job Ledger Entry`, code finds `Job Ledger Entry` rows after posting and modifies them, or a field added to `Job Journal Line` is expected on `Job Ledger Entry` with no subscriber to `OnAfterFromJnlLineToLedgEntry` or `OnBeforeJobLedgEntryInsert` — `carry-job-journal-fields-to-job-ledger-through-job-transfer-line`.
- A field added to `Purchase Line` or `Job Planning Line` is expected on `Job Ledger Entry`, but it is copied only through the journal-to-ledger hop, with no subscriber on the matching `Job Transfer Line` source event. Match only when the input states the value must come from that source — `carry-document-fields-to-job-journal-line-on-every-source-path`.
- A subscriber to `OnAfterCreateSalesInvoiceLines` finds the planning line by project and task and modifies the sales line, or code inserts a project `Sales Line` with `Job Contract Entry No.` left at 0 — `carry-job-planning-line-fields-to-project-sales-invoice-lines`.
- A subscriber to `OnAfterJobTaskCalcWIP` or later code modifies the recognized amounts on `Job Task`, an extension of `Job WIP Recognized Sales Type` or `Job WIP Recognized Costs Type` has no `OnBeforeCalcRecognizedSales` or `OnBeforeCalcRecognizedCosts` subscriber that sets `IsHandled`, or custom code posts project WIP to G/L outside `Job Post WIP to G/L` — `add-custom-project-wip-methods-through-the-recognition-events`.
- A subscriber to `OnAfterJobLedgEntryInsert` or `OnAfterResLedgEntryInsert` reads `Time Sheet Line` and modifies the new ledger entry, or a field on `Time Sheet Line` and `Job Ledger Entry` has no subscriber to `OnAfterTransferTimeSheetDetailToJobJnlLine` — `carry-time-sheet-fields-to-job-journal-through-suggest-lines`.
- Code sets `"Time Sheet Line".Posted`, changes `"Time Sheet Detail"."Posted Quantity"` or inserts `Time Sheet Posting Entry` outside `Res. Jnl.-Post Line`, a resource journal line for a time sheet resource is posted without the time sheet number, line and date, or a field on `Job Journal Line` and `Res. Ledger Entry` has no `OnAfterCopyResJnlLineFromJobJnlLine` subscriber — `time-sheet-posting-runs-in-res-jnl-post-line`.
- A time sheet archive table extension uses a different field number or type than the live table, or archive values are patched with `Modify` — `time-sheet-archive-copies-fields-by-field-number`.
- A journal line is created per time sheet line using the total quantity or without the time sheet date, lines that are not Approved are sent to a journal, or the resource is validated before `Time Sheet No.` is set — `time-sheet-hours-post-per-day-only-when-approved`.
- A custom field on `Purchase Line` and `Job Ledger Entry` has no `OnAfterFromPurchaseLineToJnlLine` and `OnAfterFromJnlLineToLedgEntry` subscribers, code creates purchase lines with `Type::Resource` and a `Job No.` to post project cost, or a sign-dependent calculation on resource ledger amounts runs in `OnAfterCopyFromResJnlLine` — `project-purchases-post-usage-only-for-item-and-gl-account-lines`.

Resolve layer conflicts per READ. When no projects knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Projects"`.
