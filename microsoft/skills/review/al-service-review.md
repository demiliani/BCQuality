---
kind: action-skill
id: al-service-review
version: 1
title: AL service review
description: Reviews AL extensions of service management processes against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL service review

Reviews AL source changes against the `service` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain service`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: table extensions of service document, posted service document, `Service Ledger Entry`, `Warranty Ledger Entry` or `Service Contract Header`, or event subscribers to `Service-Post`, `Serv-Documents Mgt.`, `ServLedgEntries-Post` or `ServContractManagement`. Also review inputs that extend `Service Contract Line`, `Service Item`, `Service Item Line` or `Service Line`, or subscribe to `Serv-Posting Journals Mgt.`, `Service Item Line` or `Service Line`.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `service` articles:

- A subscriber to `OnAfterPostServiceDoc` declares a `PreviewMode` parameter, calls an external service directly or calls `Commit`, or code reads the posted service document with `Get` from an event raised before `Finalize` — `mirror-service-fields-and-follow-up-after-service-posting`.
- A field added to `Service Ledger Entry` is set by only some of the four `"ServLedgEntries-Post"` insert events when the input states it must be on all entries, or service or warranty ledger entries are modified after posting — `carry-service-fields-to-service-and-warranty-ledger-entries`.
- A subscriber to `OnBeforeServLedgerEntrySaleInsert` reads `Service Contract Line` or is meant to fill contract invoice entries, an `OnServLedgEntryToServiceLineOnBeforeServLineInsert` subscriber reads `ServiceLedgerEntry` instead of `ServiceLedgerEntryParm`, a contract-line value is copied only in `OnCreateServiceLedgerEntryOnBeforeServLedgEntryInsert` when prepaid contracts are in scope, a per-contract value is written to `Service Header` when invoices can be combined, or logic in `OnBeforeCreateInvoice` / `OnAfterCreateInvoice` is expected to run for batch contract invoicing — `service-contract-invoices-are-built-from-contract-service-ledger-entries`.
- A `Service Item` field is mirrored on item, resource or journal tables with no copy on `Service Item Line` and `Service Line`, or a posting subscriber looks up the service item by the order number — `carry-service-item-fields-through-service-item-lines-and-posting`.

Resolve layer conflicts per READ. When no service knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Service"`.
