---
kind: action-skill
id: al-warehouse-review
version: 1
title: AL warehouse review
description: Reviews AL extensions of warehouse and transfer processes against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL warehouse review

Reviews AL source changes against the `warehouse` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain warehouse`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: table extensions of warehouse receipt, shipment, posted warehouse, `Warehouse Journal Line`, `Warehouse Entry`, `Transfer Header`, `Transfer Line` or posted and direct transfer tables, or event subscribers to `Sales Warehouse Mgt.`, `Purchases Warehouse Mgt.`, `Whse.-Post Shipment`, `Whse.-Post Receipt`, `WMS Management`, `Whse. Jnl.-Register Line`, `TransferOrder-Post Shipment`, `TransferOrder-Post Receipt` or `TransferOrder-Post Transfer`; code or subscribers touching `Warehouse Activity Line`, registered activity or movement tables, `Internal Movement Line`, posted inventory pick or put-away tables, `Create Pick`, `Create Put-away`, `Whse.-Activity-Register`, `Whse.-Activity-Post`, `Create Inventory Pick/Movement`, `Create Inventory Put-away`, `Whse. Item Tracking Line`, `Whse. Item Tracking FEFO`, `Item Tracking Code` warehouse tracking settings, `Lot No. Information` or `Bin Content`. Also review inputs that extend `Warehouse Request` or `Warehouse Source Filter`, or subscribe to `Whse.-Sales Release`, `Whse.-Purch. Release`, `Whse.-Transfer Release` or `Get Source Documents`. Also review inputs that subscribe to `Whse.-Post Shipment`, `Sales Whse. Post Shipment`, `Purch. Whse. Post Shipment`, `Transfer Whse. Post Shipment`, `Serv. Whse Post-Shipment` or `Whse.-Post Receipt`.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `warehouse` articles:

- A field on `Warehouse Shipment Header` is mirrored by number on `Posted Whse. Shipment Header` with no subscriber to `OnBeforePostedWhseShptHeaderInsert`, or a source-line field is copied to a warehouse receipt or shipment line in an `OnAfterCreate...` event followed by `Modify` — `carry-warehouse-document-fields-to-posted-warehouse-documents` or `carry-source-line-fields-to-warehouse-receipt-and-shipment-lines`, by target.
- A field with the same number exists on `Transfer Header` or `Transfer Line` and on a posted transfer table, but no subscriber to `OnAfterCopyFromTransferHeader` or `OnAfterCopyFromTransferLine` on that posted table assigns it, or a subscriber modifies a posted transfer document after posting — `posted-transfer-documents-copy-fields-one-by-one`.
- A subscriber to an end-of-transfer-posting event modifies `Item Ledger Entry` rows — `carry-transfer-line-fields-to-item-ledger`.
- A subscriber finds `Warehouse Entry` rows after posting and modifies them — `carry-fields-to-warehouse-entries-through-the-warehouse-journal-line`.
- A `Create Pick` subscriber to `OnBeforeWhseActivLineInsert` reads the warehouse shipment line to copy a custom field, a put-away subscriber reads `Warehouse Receipt Line` instead of `Posted Whse. Receipt Line`, or registered activity lines or warehouse entries are modified from `OnAfterRegisterWhseActivity` — `carry-fields-to-warehouse-picks-put-aways-and-registered-activities`.
- A field on `Registered Whse. Activity Line` is used for internal or inventory movements with no matching field on `Registered Invt. Movement Line`, or a `Whse.-Activity-Register` subscriber looks up `Internal Movement Line` — `carry-fields-through-warehouse-movements-and-internal-movements`.
- A field copied onto `Warehouse Activity Line` is expected on `Item Ledger Entry` with no copy from the source line to the item journal line, a subscriber to `OnBeforeNewWhseActivLineInsertFromPurchase` on the pick codeunit is meant for put-aways, or item ledger entries are modified from a `Whse.-Activity-Post` event — `inventory-picks-and-put-aways-post-through-the-source-document`.
- `Lot No.` or `Serial No.` is assigned directly on a `Warehouse Journal Line` for a warehouse-tracked item, `Reservation Entry` rows are added to a source line that already has a `Warehouse Shipment Line` without refreshing its warehouse tracking lines, or `Whse. Item Tracking Line` rows for warehouse journal lines swap the template and batch keys — `assign-lots-on-warehouse-documents-through-the-table-each-document-reads`.
- A subscriber to `OnAfterRegisterWhseActivity` writes lots back to the source line's `Reservation Entry`, `Lot No.` is set on a take line without the matching place line, lot quantity per bin is computed from `Item Ledger Entry`, or custom code sorts lots by expiration instead of using `Pick According to FEFO` — `lot-and-serial-on-warehouse-picks-come-from-whse-tracking-and-reach-warehouse-entries`.
- Warehouse logic decides the lot or serial requirement from the item tracking code or document-level flags instead of `GetWhseItemTrkgSetup`, or code changes `Lot Warehouse Tracking` or `SN Warehouse Tracking` after warehouse postings — `enable-lot-warehouse-tracking-before-relying-on-lots-in-wms-locations`.
- A per-lot status is copied onto `Warehouse Entry` and used to filter picks, pick lines are deleted after creation to drop lots, or lot exclusion subscribes only to `OnAfterIsItemTrackingBlocked` without guarding `OnBeforeValidateLotNo` or `OnCheckWhseItemTrkgLineOnBeforeTestTracking` — `exclude-lots-from-warehouse-picks-through-lot-no-information`.
- A `Get Source Documents` subscriber sets `SkipRecord` from a custom header field, `Warehouse Request` is inserted or modified outside the release codeunits, or a `Warehouse Request` field is filtered on but never assigned in `OnBeforeCreateWhseRequest` of each release codeunit in scope — `warehouse-requests-decide-which-source-documents-reach-warehouse-documents`.
- A field mirrored on warehouse shipment or receipt lines and on posted sales shipment or purchase receipt lines has no subscriber copying it to the source line during warehouse posting, a source-document subscriber assigns a custom field without setting `ModifyLine` or `ModifyHeader` to true, an `OnBeforeSalesLineModify` subscriber copies without checking `"Source Line No."`, sales-specific shipment events are subscribed on `Whse.-Post Shipment` instead of `Sales Whse. Post Shipment`, or posted lines or item ledger entries are modified after posting with warehouse values — `carry-warehouse-shipment-and-receipt-values-to-the-source-document-before-posting`.
- An `OnAfterPostWhseShipment` or `Whse.-Post Receipt` `OnAfterCode` subscriber modifies source, posted or ledger records, an `Error` in a per-document subscriber is meant to undo the whole warehouse shipment, or a subscriber calls `Commit` while commits are suppressed — `warehouse-shipment-and-receipt-posting-commits-per-source-document`.

Resolve layer conflicts per READ. When no warehouse knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Warehouse"`.
