---
kind: action-skill
id: al-e-documents-review
version: 1
title: AL e-documents review
description: Reviews AL extensions of the E-Document Core app (formats, services and import) against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL e-documents review

Reviews AL source changes against the `e-documents` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain e-documents`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: enum extensions of `E-Document Format`, `Service Integration`, `E-Doc. Read into Draft`, `E-Doc. Proc. Customizations` or `Integration Action Type`; codeunits implementing `E-Document`, `IDocumentSender`, `IDocumentReceiver`, `IDocumentResponseHandler` or `IStructuredFormatReader`; subscribers to `EDoc PEPPOL BIS 3.0`, `E-Doc. Import`, `E-Doc. Export`, `E-Doc. Integration Management` or `E-Document Create Purch. Doc.`; table extensions of `E-Document`, `E-Document Service`, `E-Document Service Status`, `E-Doc. Service Supported Type`, `E-Document Purchase Header` or `E-Document Purchase Line`; or an app.json dependency on E-Document Core (e1d97edc-c239-46b4-8d84-6368bdf67c8b).

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `e-documents` articles:

- A subscriber to `OnAfterPostSalesDoc` or `OnAfterPostPurchaseDoc` builds an e-invoice file or writes it to a custom table instead of extending `E-Document Format`, an `E-Document` `Create` re-reads the posted record with `Get` instead of using the source record references or calls `Commit()`, or a new format value has no step that adds `E-Doc. Service Supported Type` rows — `add-an-e-document-format-through-the-format-enum`.
- An enum extension of the obsolete `E-Document Integration` enum or an implementation of its interface, an `IDocumentSender` that ignores a failed HTTP call without raising or logging an error, or connector code that writes its own send log, modifies `E-Document Service Status`, calls `Commit()` or schedules its own retry job — `connect-an-e-document-service-through-the-v2-integration-interfaces`.
- V1 import events such as `OnCreateNewPurchHdrOnBeforeRecRefInsert` used on a Version 2.0 import service, a field on `E-Document Purchase Header` or `E-Document Purchase Line` never copied to the purchase document, an `OnAfterProcessIncomingEDocument` subscriber without a `DesiredEndState` guard and `E-Document Link` lookup, or an `OnAfterCreatePEPPOLXMLDocument` subscriber that re-reads the posted document by number — `carry-custom-fields-through-e-document-export-and-import`.
- A blocking `Error` or `TestField` in `E-Document` `Create` meant to stop posting instead of in `Check`, or code that expects an `E-Document` record right after posting — `e-document-creation-runs-after-the-posting-commit`.

Resolve layer conflicts per READ. When no e-documents knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"E-documents"`.
