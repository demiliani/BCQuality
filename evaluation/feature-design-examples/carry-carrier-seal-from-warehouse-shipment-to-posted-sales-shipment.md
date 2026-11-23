# Feature design

> Warehouse staff enter a Carrier Seal No. on the warehouse shipment before posting it. The seal number must appear on the posted sales shipment and on the item ledger entries created by that shipment, including when the shipment is previewed.

**Result:** Complete design. **Business process:** Carry a seal number entered on the warehouse shipment through warehouse shipment posting (Whse.-Post Shipment and Sales Whse. Post Shipment) into sales posting, so it lands on the posted sales shipment and its item ledger entries, in both posting and posting preview. **Knowledge used:** 16 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. The mirroring rule adds Carrier Seal No. to Sales Invoice Header, Sales Cr.Memo Header, Return Receipt Header and Sales Header Archive as well as Sales Shipment Header. Should all of these carry the seal, or should any be excluded? _(affects: sales-invoice-header-ext, sales-cr-memo-header-ext, return-receipt-header-ext, sales-header-archive-ext, ship-and-invoice-mirrors-seal)_
2. Copy Document copies posted and archived headers back into Sales Header by TransferFields, so a copied document would inherit an old seal. Should the seal be cleared on the new sales header when a document is copied? _(affects: sales-header-ext, seal-posting-subscribers)_
3. Must users see or filter Carrier Seal No. as a column on Item Ledger Entries, or is it read only occasionally (for example for a trace or integration)? The answer decides between a stored field on Item Ledger Entry and a related table keyed by Entry No. _(affects: item-ledger-entry-ext, item-ledger-entries-page-ext, whse-shipment-posts-seal-to-item-ledger)_
4. Should Carrier Seal No. also be visible or editable on the sales order, or only filled from the warehouse shipment? If a user enters it on the order, the warehouse shipment value overwrites it at posting. _(affects: sales-header-ext, seal-posting-subscribers)_
5. Should the seal also appear on the posted warehouse shipment? That needs a subscriber to OnBeforePostedWhseShptHeaderInsert, and a reused posted header keeps the value from its first posting. _(affects: whse-shipment-header-ext)_
6. Warehouse shipments can also hold purchase return orders, transfer orders and service orders, each with its own posting event. Is the seal needed only for sales orders, or also for these sources? _(affects: seal-posting-subscribers)_
7. Must a warehouse shipment have a Carrier Seal No. before it can be posted, and what format or length does a seal number have (Code[20] is assumed)? _(affects: whse-shipment-header-ext, sales-header-ext, seal-posting-subscribers)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Warehouse Shipment Header | Holds the Carrier Seal No. that warehouse staff enter before posting the shipment. The warehouse routine copies only named header values to the sales header, so this field is carried by a subscriber, not by field number. | Carrier Seal No. (Code[20]): Set DataClassification on the field; a tableextension has no table-level value to inherit. Use the same field number as the sales cascade for consistency. | [2] [9] |
| 2 | extend | pageextension | Warehouse Shipment | Lets warehouse staff enter Carrier Seal No. on the warehouse shipment header. Tooltip text is defined on the table field and inherited from BC24 (runtime 13.0); on earlier targets the page control needs its own ToolTip. |  | [14] [15] |
| 3 | extend | tableextension | Sales Header | Conveyor field: the warehouse shipment value is written here just before Sales-Post runs, because Sales Shipment Header is a TransferFields of Sales Header, not of the warehouse shipment. | Carrier Seal No. (Code[20]): Same field number, type and length on every TransferFields target of Sales Header. | [2] [6] [8] [9] |
| 4 | extend | tableextension | Sales Shipment Header | Shows the seal on the posted sales shipment; filled by the standard TransferFields from Sales Header, no subscriber. | Carrier Seal No. (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification set on the field. | [6] [8] [2] |
| 5 | extend | tableextension | Sales Invoice Header | Mirror target of Sales Header required by the mirroring article unless the plan excludes it (see open question mirror-targets). | Carrier Seal No. (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification set on the field. | [6] [8] |
| 6 | extend | tableextension | Sales Cr.Memo Header | Mirror target of Sales Header required by the mirroring article unless the plan excludes it (see open question mirror-targets). | Carrier Seal No. (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification set on the field. | [6] [8] |
| 7 | extend | tableextension | Return Receipt Header | Mirror target of Sales Header required by the mirroring article unless the plan excludes it (see open question mirror-targets). | Carrier Seal No. (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification set on the field. | [6] [8] |
| 8 | extend | tableextension | Sales Header Archive | Archive mirror of Sales Header required by the mirroring article unless the plan excludes it (see open question mirror-targets). | Carrier Seal No. (Code[20]): Same field number, name, type and length as on Sales Header; Editable = false; DataClassification set on the field. | [6] [8] |
| 9 | extend | tableextension | Item Journal Line | Carries the seal from the sales header to the item ledger entry; Sales-Post builds the item journal line with field-by-field copy methods. | Carrier Seal No. (Code[20]) | [5] [2] |
| 10 | extend | tableextension | Item Ledger Entry | Stores the seal on item ledger entries created by the shipment, written when the entry is initialized during posting. Stored as a tableextension field only if users must see or filter it as a native list column; otherwise a related table keyed by Entry No. (see open question ile-storage). | Carrier Seal No. (Code[20]): Editable = false; set DataClassification. | [5] [11] [9] |
| 11 | create | codeunit | Carrier Seal Posting Subscribers | Event subscribers that copy the seal from the warehouse shipment header to the sales header before posting, and from the sales header through the item journal line to the item ledger entry during posting. |  | [2] [5] [16] |
| 12 | extend | pageextension | Posted Sales Shipment | Shows Carrier Seal No. on the posted sales shipment (read-only). |  | [7] [14] [15] |
| 13 | extend | pageextension | Item Ledger Entries | Shows Carrier Seal No. as a column on item ledger entries, if the stored-field option is chosen (see open question ile-storage). |  | [7] [11] [14] |

## 3. How the data flows

- **user** → **Warehouse Shipment Header.Carrier Seal No.**: entered by the user. Entered on the Warehouse Shipment page before posting or previewing. [2]
- **Warehouse Shipment Header.Carrier Seal No.** → **Sales Header.Carrier Seal No.**: copied in an event subscriber. In OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify on Sales Whse. Post Shipment, once per sales source document on the shipment, before Sales-Post runs; set ModifyHeader when the value changed. Runs in preview too, because the warehouse routine runs Sales-Post with preview set. [2] [3]
- **Sales Header.Carrier Seal No.** → **Sales Shipment Header.Carrier Seal No.**: standard TransferFields copy. Standard TransferFields in Sales-Post; same field number and type required. [6] [8] [2]
- **Sales Header.Carrier Seal No.** → **Sales Invoice Header, Sales Cr.Memo Header, Return Receipt Header, Sales Header Archive.Carrier Seal No.**: standard TransferFields copy. Standard TransferFields in posting and archiving; mirror targets pending open question mirror-targets. [6] [8]
- **Sales Header.Carrier Seal No.** → **Item Journal Line.Carrier Seal No.**: copied in an event subscriber. OnAfterCopyItemJnlLineFromSalesHeader on Item Journal Line, as Sales-Post builds the item journal line for each shipped line. [2] [5]
- **Item Journal Line.Carrier Seal No.** → **Item Ledger Entry.Carrier Seal No.**: copied in an event subscriber. OnAfterInitItemLedgEntry on Item Jnl.-Post Line, before the entry is inserted; the value is written as part of posting, never by modifying entries afterwards. [5] [2] [16]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Sales Whse. Post Shipment | `OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify` | Copy Carrier Seal No. from the warehouse shipment header to each sales source header just before the routine modifies it, so Sales-Post carries it to the posted shipment and item journal lines. | Set ModifyHeader to true only when the value changed; the routine calls Modify only when the flag is set. · Overwrite the sales header value on every run (do not keep a previous value), because values written to the source persist into the next partial shipment of the same order. · Do not exit on preview: the request requires the seal in posting preview, and this event runs before Sales-Post in preview. · Subscribe on Sales Whse. Post Shipment, not on Whse.-Post Shipment, which does not publish the sales-specific events. | [2] [3] |
| Item Journal Line | `OnAfterCopyItemJnlLineFromSalesHeader` | Copy Carrier Seal No. from the sales header to the item journal line Sales-Post builds for each shipped item line. | Assignment only; no Modify or Insert on any record. | [2] [5] |
| Item Jnl.-Post Line | `OnAfterInitItemLedgEntry` | Copy Carrier Seal No. from the item journal line to the new item ledger entry before it is inserted. | Assignment only; never find and modify item ledger entries after posting. · Other item postings reach this subscriber with an empty journal field, so the entry stays empty; no source-document filter needed. | [5] [16] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification explicitly on Carrier Seal No. in every tableextension (CustomerContent is the likely value for a shipment seal identifier; confirm it holds no personal data). [9]
- **upgrade**: No upgrade code: the field has no InitValue and blank is a valid state for existing documents and posted history, which keep blank. [13]
- **permissions**: No new tables are created, so no table permissions are needed; if the app has a permission set, include the subscriber codeunit per the app's convention. agent judgment

## 6. Tests

1. **whse-shipment-posts-seal-to-posted-shipment** [2] [6] [10]
    - Given A released sales order for an item at a location requiring shipment, a warehouse shipment created from it, and Carrier Seal No. entered on the warehouse shipment header (fixtures built with the test Library codeunits).
    - When The warehouse shipment is posted (ship).
    - Then The Sales Shipment Header created for the order carries the same Carrier Seal No.
2. **whse-shipment-posts-seal-to-item-ledger** [5] [12] [10]
    - Given Same setup as whse-shipment-posts-seal-to-posted-shipment.
    - When The warehouse shipment is posted.
    - Then Every Item Ledger Entry with Document No. equal to the posted shipment number (Sales Header Last Shipping No.) carries the Carrier Seal No.
3. **whse-shipment-preview-shows-seal** [3]
    - Given A warehouse shipment with Carrier Seal No. entered.
    - When Preview Posting is run on the warehouse shipment.
    - Then The previewed item ledger entries carry the Carrier Seal No., and nothing is committed (the sales header and warehouse shipment are unchanged afterwards).
4. **two-source-documents-get-seal** [3] [2]
    - Given One warehouse shipment holding lines from two sales orders, with Carrier Seal No. entered.
    - When The warehouse shipment is posted.
    - Then Both posted sales shipments and their item ledger entries carry the Carrier Seal No.
5. **partial-shipment-overwrites-seal** [3]
    - Given A sales order partly shipped through a warehouse shipment with seal A; a second warehouse shipment for the remaining quantity with seal B.
    - When The second warehouse shipment is posted.
    - Then The second posted sales shipment and its item ledger entries carry seal B; the first keeps seal A.
6. **failed-document-under-posting-policy** [3]
    - Given A warehouse shipment with two sales orders where one fails to post, run once under each Shipment Posting Policy.
    - When The warehouse shipment is posted.
    - Then Under 'Stop and show the first posting error' the run stops; under 'Posting errors are not processed' the posted order carries the seal and the failed order's sales header keeps the seal value already committed, with no posted shipment.
7. **ship-and-invoice-mirrors-seal** [6] [2]
    - Given A warehouse shipment with Carrier Seal No. entered.
    - When The warehouse shipment is posted with Ship and Invoice.
    - Then The Sales Invoice Header also carries the Carrier Seal No. (if invoice headers stay in scope after open question mirror-targets).
8. **direct-sales-posting-leaves-seal-blank** [5]
    - Given A sales order at a location without warehouse shipment, with no seal entered.
    - When The sales order is posted directly.
    - Then The posted shipment and item ledger entries have a blank Carrier Seal No. and posting succeeds.
9. **modify-header-flag-set-only-on-change** [2]
    - Given A sales header whose Carrier Seal No. already equals the warehouse shipment value.
    - When The header subscriber runs.
    - Then The value is unchanged and ModifyHeader is not forced to true; when the values differ, the sales header value is replaced and ModifyHeader is true.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Target BC version, countries and application area are unknown; the tooltip-inheritance rule applies from BC24 and the related-table guidance from BC23.
- Permission handling for the subscriber codeunit rests on judgment; no opened article covers permissions for an extension that adds only fields and subscribers.
- How the posting preview page displays custom Item Ledger Entry fields is not covered by BCQuality knowledge; the preview test rests on judgment beyond the fact that the warehouse routine runs Sales-Post in preview mode with the same events.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Process map: selected the warehouse shipment, sales posted documents and item ledger rows and the cross-cutting rows (mirroring, copy document, upgrade, privacy, tests).
    - Plan one row group per process the field touches and open every linked article for the chosen stages.
    - Whether the field reaches stages the request does not name is a question for the requester, one question per group.
    - Do not fill other records with subscribers that find and modify them after posting.
[2] `microsoft/knowledge/warehouse/carry-warehouse-shipment-and-receipt-values-to-the-source-document-before-posting.md`: Core route: warehouse shipment header -> sales header before Sales-Post, then TransferFields and item journal events; names the subscriber events.
    - Posted sales shipment and item ledger entries are built from the source document, not the warehouse document; a warehouse field reaches them only if first copied to the source document.
    - Copy warehouse shipment header to sales header in OnInitSourceDocumentHeaderOnBeforeSalesHeaderModify on Sales Whse. Post Shipment and set ModifyHeader when the value changed.
    - Sales-specific shipment events are published by Sales Whse. Post Shipment, not Whse.-Post Shipment.
    - Give posted header fields the same numbers as on the source header so TransferFields carries them.
    - Do not patch posted shipment lines or item ledger entries after posting.
    - Other source types (purchase return, transfer, service) need their own subscriber per source type in scope.
[3] `microsoft/knowledge/warehouse/warehouse-shipment-and-receipt-posting-commits-per-source-document.md`: Commit and preview behaviour of warehouse shipment posting; guards and tests for multiple source documents, partial shipments, preview and posting policies.
    - Put everything that must become part of posted documents on the source document before it is posted.
    - Do not use OnAfterPostWhseShipment to write values to the sales header, posted shipment or item ledger: it runs after commit and never in preview.
    - Preview runs Sales-Post with preview set; no commits occur in preview.
    - Values written to source lines persist into the next partial shipment unless overwritten.
    - Earlier source documents are already committed when a later one fails; failed documents keep values already written.
    - Test a shipment with two source documents, a preview, and a failing document under each posting policy.
[4] `microsoft/knowledge/warehouse/carry-warehouse-document-fields-to-posted-warehouse-documents.md`: Raises open question posted-whse-shipment: the posted warehouse shipment header is a separate stage filled field by field.
    - Posted Whse. Shipment Header is filled field by field, not by TransferFields; a same-numbered field stays blank without a subscriber to OnBeforePostedWhseShptHeaderInsert.
    - A reused posted header is not inserted again, so the header value is the value at the first posting.
[5] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md`: Item ledger stage: Item Journal Line and Item Ledger Entry fields and the OnAfterInitItemLedgEntry subscriber.
    - Add the field to Item Journal Line and Item Ledger Entry and copy it through the journal line into the entry during posting.
    - Store the field on the ledger only when users must see or filter it as a native list column or it is read on almost every access; otherwise prefer a related table keyed by entry number.
    - Do not find item ledger entries after posting and modify them.
    - Other item postings leave the journal field empty, so no source-document filter is needed.
[6] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring Sales Header to Sales Shipment Header and the other posted headers and archive.
    - Same field number, name, type and length on the source and every TransferFields target the plan needs; for a header field that is all four posted headers and the archive unless the plan states a document type never needs it.
    - No subscriber is needed for TransferFields stages.
    - Keep mirrored fields non-editable on posted tables.
[7] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Sales posting path: page extensions per stage, posting test that reads back every target, and the Copy Document flow-back question.
    - Name the page extensions that show the field and a test that posts and reads the value back from every target.
    - Copy Document copies posted and archived headers back into Sales Header with TransferFields; decide whether that is wanted, and if not clear it in OnAfterCopySalesHeaderDone on Copy Document Mgt.
    - Do not fill ledger entries after posting by finding and modifying them.
[8] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definition rule for every mirrored table.
    - Mirrored fields must have the exact same field number, data type and length on every table in the TransferFields cascade.
[9] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of the new field on every tableextension.
    - A tableextension field must set its own DataClassification; ToBeClassified is not a safe default.
    - Choose the classification that matches the data the field stores.
[10] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build customers, items, sales orders and warehouse setup with the test Library codeunits, parents before dependents, validating foreign keys.
[11] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Raises open question ile-storage (applies from BC23): stored field on Item Ledger Entry versus related table.
    - Put optional or sparse attributes on hot ledgers such as Item Ledger Entry in a related table keyed by Entry No.; use a stored tableextension field only when the value must appear as a native list column and is read on almost every access.
[12] `microsoft/knowledge/data-modeling/item-ledger-entry-document-no-follows-last-shipping-no.md`: Test read-back: item ledger entries of the shipment are found by the shipment number.
    - After Ship and Invoice posting, filter Item Ledger Entry by Sales Header Last Shipping No., not by the invoice number.
[13] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: Confirms no upgrade code is needed.
    - InitValue does not back-fill existing rows; optional fields where empty is valid need no upgrade code.
[14] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on the page extensions.
    - User-facing page fields need an explicit or inherited ToolTip; define shared text on the table field from runtime 13.0 and avoid duplicate page-level tooltips.
    - Tooltip text should say what the value is used for, not just repeat the caption.
[15] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Tooltip inheritance on bound page fields (applies from BC24, runtime 13.0).
    - From BC24 a bound page field inherits the table field's ToolTip; earlier runtimes need page-level tooltips.
[16] `microsoft/knowledge/scm/post-item-ledger-changes-through-item-journals.md`: Confirms the item ledger value is added through supported posting events inside the sales posting workflow.
    - Item ledger entries are created only by the owning posting workflow; enrich them through supported posting events, never by independent inserts or overwrites.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v4. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

