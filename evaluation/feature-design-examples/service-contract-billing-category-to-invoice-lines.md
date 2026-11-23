# Feature design

> Each service contract line gets a Billing Category. Contract invoices created by the Create Contract Invoices batch must show the category on every invoice line and on the posted service invoice lines, and finance wants to filter service ledger entries by it. Also, every service order line should show the Asset Class of the service item it belongs to, and we need the Asset Class on item ledger entries for parts consumed on service orders.

**Result:** Complete design. **Business process:** Adds a contract-line Billing Category carried by Create Contract Invoices (ServContractManagement) to contract service ledger entries, invoice service lines and posted service invoice lines, and an Asset Class carried from service items through service order lines and service posting to item ledger entries, in Service Management. **Knowledge used:** 15 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is a Billing Category: a code from a new master table (with its own page and permissions), an enum, or free text? This sets the field type, length and TableRelation on every table that holds it. _(affects: service-contract-line-ext, service-ledger-entry-ext, service-line-ext, service-invoice-line-ext, lifecycle)_
2. Is the Asset Class an existing field (for example from another app or a fixed-asset class) or a new field on Service Item maintained by users? This sets its type, length and whether the Service Item Card extension is needed. _(affects: service-item-ext, service-item-card-ext, service-line-ext, item-ledger-entry-ext)_
3. Must contract credit memos (built by CreateCreditLine) and posted Service Cr.Memo Lines also carry the Billing Category? That needs a subscriber to OnBeforeServLineInsert and a mirrored field on Service Cr.Memo Line. _(affects: contract-billing-category-subscribers, service-line-ext)_
4. Contract invoices also contain text lines (heading, detailed and last lines) that are not built from a service ledger entry. Should they stay blank, or does 'every invoice line' include them? No BCQuality article names an event for those lines. _(affects: service-line-ext, contract-billing-category-subscribers)_
5. Only contract service ledger entries will carry the Billing Category. Should service ledger entries from service orders, invoices and credit memos posted against a contract (usage, sale, credit memo paths in ServLedgEntries-Post) carry one too, and from which source? _(affects: service-ledger-entry-ext, contract-billing-category-subscribers)_
6. Are both prepaid and non-prepaid contracts in scope? The design covers all three entry insert points; any that never applies can be dropped. _(affects: contract-billing-category-subscribers)_
7. Should service invoices and credit memos entered directly (no service item line) also show the Asset Class? That needs a copy from Service Item when Service Line.Service Item No. is validated. _(affects: service-asset-class-subscribers, service-line-ext)_
8. Should the Asset Class also reach posted service shipment, invoice and credit memo lines? Each needs a mirrored field with the same number, type and length. _(affects: service-line-ext)_
9. Service posting writes item ledger entries both when parts are shipped and when they are consumed. Should the Asset Class be on both, or only on consumption entries? _(affects: service-asset-class-subscribers, item-ledger-entry-ext)_
10. Will users see or filter the Asset Class as a column on Item Ledger Entries? If not, a related table keyed by Entry No. is preferred over a stored field on this hot ledger. _(affects: item-ledger-entry-ext, item-ledger-entries-page-ext)_
11. Should existing contract lines, open contract service ledger entries, service items or open service orders be back-filled on upgrade, or is blank acceptable for history? _(affects: lifecycle)_
12. Should the Billing Category carry from service contract quotes to the signed contract, and to filed (archived) contracts? No BCQuality article covers those copies. _(affects: service-contract-line-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Service Contract Line | Holds the Billing Category the user enters per contract line; the source of every contract invoice value. | Billing Category (Code[20]): Type, length and any TableRelation pending question billing-category-definition. DataClassification CustomerContent; ToolTip on the table field. | [2] [10] [15] |
| 2 | extend | tableextension | Service Ledger Entry | Carries the Billing Category on the contract service ledger entries created by Create Contract Invoices, so finance can filter Service Ledger Entries by it. Stored field rather than a related table: the value must be filtered as a native list column, which is the condition the hot-ledger article states for a stored field. | Billing Category (Code[20]): Non-editable. Filled when the contract entries are created, never modified afterwards; posting closes the same rows and keeps the value. | [2] [6] [10] [15] |
| 3 | extend | tableextension | Service Line | Shows the Billing Category on contract invoice lines and the Asset Class of the serviced item on service order lines; both are the TransferFields source for posted service lines and the source of the item journal line copy. | Billing Category (Code[20]): Same field number, type and length as on Service Invoice Line.; Asset Class (Code[20]): Same type and length as Service Item Line and Service Item. Mirrored to posted service lines only if question asset-class-posted-documents says so. | [2] [4] [5] [9] [10] [15] |
| 4 | extend | tableextension | Service Invoice Line | Receives the Billing Category from the service line by the standard TransferFields in Serv-Documents Mgt. when the contract invoice is posted. | Billing Category (Code[20]): Same field number, name, type and length as on Service Line; non-editable on the posted table. | [5] [8] [9] [10] |
| 5 | extend | tableextension | Service Item | Holds the Asset Class of a service item, the source of the service order line value. Designed as a new field pending question asset-class-source. | Asset Class (Code[20]): Entered by the user unless the Asset Class already exists elsewhere (question asset-class-source). | [4] [10] [15] |
| 6 | extend | tableextension | Service Item Line | Intermediate hop: the service item line copies the Asset Class from the service item so service lines can take it from the item line they belong to. | Asset Class (Code[20]): Filled in OnAfterSetServItemInfo. | [4] [10] |
| 7 | extend | tableextension | Item Journal Line | Carries the Asset Class from the service line to the item ledger entry during service posting. | Asset Class (Code[20]): Empty for item journals posted directly and for other documents. | [4] [7] [10] |
| 8 | extend | tableextension | Item Ledger Entry | Stores the Asset Class on item ledger entries posted from service lines. Stored field because the request asks for it on the entry; the item ledger is a hot ledger, so the related-table alternative applies if users will not see or filter it as a list column (question asset-class-item-ledger-storage). | Asset Class (Code[20]): Non-editable; filled in OnAfterInitItemLedgEntry, never by modifying entries after posting. | [4] [7] [6] [10] |
| 9 | create | codeunit | Contract Billing Category | Event subscribers that copy the Billing Category from the contract line to each contract service ledger entry on all three insert points, then from the converted entry to the invoice service line. |  | [2] |
| 10 | create | codeunit | Service Item Asset Class | Event subscribers that copy the Asset Class service item -> service item line -> service line -> item journal line -> item ledger entry. |  | [4] [7] |
| 11 | extend | pageextension | Service Contract Subform | Lets the user enter the Billing Category on contract lines. Page name rests on judgment. |  | [15] |
| 12 | extend | pageextension | Service Invoice Subform | Shows the Billing Category on contract invoice lines. Page name rests on judgment. |  | [15] |
| 13 | extend | pageextension | Posted Serv. Invoice Subform | Shows the Billing Category on posted service invoice lines. Page name rests on judgment. |  | [15] |
| 14 | extend | pageextension | Service Ledger Entries | Shows the Billing Category as a list column finance can filter on. |  | [6] [15] |
| 15 | extend | pageextension | Service Item Card | Lets the user maintain the Asset Class on the service item (if question asset-class-source confirms it is a new field). |  | [15] |
| 16 | extend | pageextension | Service Lines | Shows the Asset Class on service order lines (and on Service Order Subform for service item lines). Page names rest on judgment. |  | [15] |
| 17 | extend | pageextension | Item Ledger Entries | Shows the Asset Class on item ledger entries. |  | [15] |

## 3. How the data flows

- **User** → **Service Contract Line.Billing Category**: entered by the user. Entered on the contract lines page. [2]
- **Service Contract Line.Billing Category** → **Service Ledger Entry.Billing Category**: copied in an event subscriber. At invoice creation by Create Contract Invoices (CreateAllServLines -> CreateServiceLedgEntry), on all three insert points: not prepaid, prepaid per month, prepaid partial period. Read the contract line parameter, not the header. [2]
- **Service Ledger Entry.Billing Category** → **Service Line.Billing Category**: copied in an event subscriber. In ServLedgEntryToServiceLine, copy from ServiceLedgerEntryParm (the entry being converted), never from the global ServiceLedgerEntry parameter. Lines, not the header, carry the value, so Combine Invoices keeps each contract's category. [2]
- **Service Line.Billing Category** → **Service Invoice Line.Billing Category**: standard TransferFields copy. Serv-Documents Mgt. at posting; same field number, type and length on both tables. No subscriber. Posting closes the existing contract service ledger entries with ModifyAll, so their Billing Category stays. [5] [8] [9] [2]
- **User** → **Service Item.Asset Class**: entered by the user. Pending question asset-class-source. [4]
- **Service Item.Asset Class** → **Service Item Line.Asset Class**: copied in an event subscriber. SetServItemInfo, called when Service Item No. is validated. [4]
- **Service Item Line.Asset Class** → **Service Line.Asset Class**: copied in an event subscriber. Validation of Service Item Line No. on the service line; validating Service Item No. on an order line goes through the same validation. [4]
- **Service Line.Asset Class** → **Item Journal Line.Asset Class**: copied in an event subscriber. Serv-Posting Journals Mgt. builds the item journal line with Service Line.CopyToItemJnlLine for shipped and consumed items. [4] [7]
- **Item Journal Line.Asset Class** → **Item Ledger Entry.Asset Class**: copied in an event subscriber. Item Jnl.-Post Line initializes the entry before insert; journal lines from other sources leave it empty. [7] [4]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| ServContractManagement | `OnCreateServiceLedgerEntryOnBeforeServLedgEntryInsert` | Copy Billing Category from the contract line to the contract service ledger entry for contracts that are not prepaid. | Copy from the ServiceContractLine parameter. | [2] |
| ServContractManagement | `OnInsertMultipleServLedgEntriesOnBeforeServLedgEntryInsert` | Copy Billing Category to each monthly entry of a prepaid contract. | Read the contract line, not ServiceContractHeader, which is only filled for a partial month. | [2] |
| ServContractManagement | `OnPostPartialServLedgEntryOnBeforeServLedgEntryInsert` | Copy Billing Category to the prepaid partial-period entry. | Copy from the ServContractLine parameter. | [2] |
| ServContractManagement | `OnServLedgEntryToServiceLineOnBeforeServLineInsert` | Copy Billing Category from the converted contract service ledger entry to the contract invoice service line. | Read ServiceLedgerEntryParm, not the parameter named ServiceLedgerEntry (the codeunit's global, last-created entry). | [2] |
| Service Item Line | `OnAfterSetServItemInfo` | Copy Asset Class from the service item to the service item line. |  | [4] |
| Service Line | `OnValidateServiceItemLineNoOnBeforeValidateContractNo` | Copy Asset Class from the service item line the service line belongs to. | Take the value from the ServItemLine parameter; never guess the service item from the order, which can service several items. | [4] |
| Service Line | `OnAfterCopyToItemJnlLine` | Copy Asset Class from the service line to the item journal line built at service posting. |  | [4] [7] |
| Item Jnl.-Post Line | `OnAfterInitItemLedgEntry` | Copy Asset Class from the item journal line to the new item ledger entry before insert. | Copy from the item journal line only; do not re-read the service item or service order here. | [7] [4] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification on every field the table extensions add (CustomerContent for the Billing Category and Asset Class codes); a tableextension has no table-level value to inherit. [10]
- **upgrade**: No InitValue is used, so no upgrade code is needed for new rows; existing contract lines, service items, open service lines and posted history stay blank. Back-fill only if question backfill-existing-data asks for it. [11]
- **upgrade**: If back-fill is chosen, run it once per company behind its own upgrade tag (HasUpgradeTag / SetUpgradeTag), not a version check. [12]
- **other**: Put the ToolTip on the table fields so bound page fields inherit it (applies from BC24 / runtime 13.0; on earlier runtimes add page-level ToolTips). [15]
- **permissions**: No new table is created, so no permission set change is needed for table extensions and subscriber codeunits; if Billing Category or Asset Class becomes a new master table (questions billing-category-definition, asset-class-source), add it with its pages to the app's permission sets. agent judgment

## 6. Tests

1. **contract-invoice-not-prepaid** [2] [13] [14]
    - Given A signed, not prepaid service contract (created with the Library codeunits) with two lines carrying different Billing Categories
    - When Create Contract Invoices runs for the contract (request page handled by a handler)
    - Then Each contract service ledger entry and each invoice service line built from it carries its own contract line's Billing Category
2. **contract-invoice-prepaid-monthly** [2] [13] [14]
    - Given A prepaid contract invoiced over several months with a Billing Category on its line
    - When Create Contract Invoices runs
    - Then Every monthly contract service ledger entry and every resulting service line carries the Billing Category
3. **contract-invoice-prepaid-partial** [2] [13] [14]
    - Given A prepaid contract whose invoice period produces a partial-period entry
    - When Create Contract Invoices runs
    - Then The partial-period service ledger entry and its service line carry the Billing Category
4. **service-line-takes-converted-entry** [2] [13] [14]
    - Given One contract with several lines and different Billing Categories, so several entries are converted into lines in one run
    - When Create Contract Invoices runs
    - Then No line carries the value of the last-created entry; each line matches the entry in its Appl.-to Service Entry
5. **combine-invoices-keeps-line-values** [2] [13] [14]
    - Given Two contracts for the same bill-to customer with different Billing Categories
    - When Create Contract Invoices runs with Combine Invoices
    - Then The single invoice's lines carry each contract's own Billing Category
6. **post-contract-invoice** [5] [2] [13]
    - Given A contract invoice created by Create Contract Invoices with Billing Category on its lines
    - When The service invoice is posted
    - Then Each Service Invoice Line carries the Billing Category, and filtering Service Ledger Entry by Billing Category returns the closed contract entries of that invoice
7. **service-order-line-asset-class** [4] [13]
    - Given A service item with an Asset Class and a service order with a service item line for it
    - When A service line is added under that service item line
    - Then The service item line and the service line show the service item's Asset Class
8. **two-service-items-one-order** [4] [13]
    - Given A service order servicing two service items with different Asset Classes
    - When Service lines are added under each service item line
    - Then Each service line carries the Asset Class of its own service item line
9. **consume-parts-to-item-ledger** [4] [7] [13]
    - Given A service order line of type Item under a service item with an Asset Class
    - When The order is posted with Ship and Consume
    - Then The item ledger entry for the consumed part carries the Asset Class
10. **direct-item-journal-leaves-empty** [7] [13]
    - Given An item journal line not created from a service line
    - When It is posted
    - Then The item ledger entry's Asset Class is empty

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Page names for the page extensions (Service Contract Subform, Service Invoice Subform, Posted Serv. Invoice Subform, Service Lines, Service Order Subform, Service Item Card, Service Ledger Entries, Item Ledger Entries) rest on the agent's judgment; confirm them in the Base Application symbols.
- Permission set handling rests on the agent's judgment; no BCQuality article was selected for it because no new table is designed yet.
- Billing Category carry-over from service contract quotes and to filed contracts is not covered by BCQuality knowledge.
- No event for contract invoice text lines is covered by BCQuality knowledge.
- Field numbers and the app ID range are unknown: no repository was supplied.
- bc-version, countries and application-area could not be resolved from the request; the hot-ledger guidance applies from BC23 and table-field ToolTips from BC24.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Map of field paths: chose the service row (service item lines, posted documents, ledger entries, contracts) and the cross-cutting rows (mirrored definitions, posted entries, upgrade back-fill, privacy, tests).
    - Plan one row group per process the request touches and open every linked article for the stages chosen.
    - Whether a field should reach a stage the request does not name is a question for the requester; raise one question per group of stages.
    - Do not fill other records with subscribers that find and modify them after posting.
[2] `microsoft/knowledge/service/service-contract-invoices-are-built-from-contract-service-ledger-entries.md`: Billing Category path from contract line through contract service ledger entries to invoice service lines and posted invoice lines.
    - Put contract-line values on the contract service ledger entries when they are created, subscribing to the insert events the contracts in scope use (not prepaid, prepaid per month, prepaid partial period).
    - Copy to the service line in OnServLedgEntryToServiceLineOnBeforeServLineInsert from ServiceLedgerEntryParm, not from the parameter named ServiceLedgerEntry.
    - OnBeforeServLedgerEntrySaleInsert never runs for contract invoice lines; do not rely on it.
    - Do not look up the contract line from the finished service line; neither table stores the contract line number.
    - Keep values that differ per contract on the lines, because a combined invoice has one header.
    - Contract credit memos are a separate path through CreateCreditLine and OnBeforeServLineInsert.
    - OnBeforeCreateInvoice and OnAfterCreateInvoice do not run from the Create Contract Invoices report.
[3] `microsoft/knowledge/service/carry-service-fields-to-service-and-warranty-ledger-entries.md`: Other Service Ledger Entry insert paths, used to scope open question non-contract-service-ledger-entries.
    - A field that must appear on all service ledger entries needs subscribers on all four ServLedgEntries-Post insert events; the parameter order differs between them.
    - Do not find service ledger entries after posting and Modify them.
[4] `microsoft/knowledge/service/carry-service-item-fields-through-service-item-lines-and-posting.md`: Asset Class path service item -> service item line -> service line -> item journal line -> item ledger entry.
    - Extend each hop on the path: OnAfterSetServItemInfo for the service item line, OnValidateServiceItemLineNoOnBeforeValidateContractNo for the service line.
    - Invoices and credit memos have no service item line step; copy from Service Item when Service Line.Service Item No. is validated if they need the value.
    - Copy to Item Journal Line in OnAfterCopyToItemJnlLine on Service Line, then to the entry in OnAfterInitItemLedgEntry.
    - Matching field numbers on Service Item and Item Ledger Entry do not fill the entry; no step copies the service item to journal lines.
    - Do not re-read the service item in OnAfterInitItemLedgEntry; one service order can service several items.
[5] `microsoft/knowledge/service/mirror-service-fields-and-follow-up-after-service-posting.md`: Service Line to Service Invoice Line by TransferFields in Serv-Documents Mgt.
    - Give the field the same number, name, type and length on Service Line and on each posted table the plan needs; no subscriber is needed for that hop.
    - Posted service documents exist only in temporary tables until Finalize; do not Get them from subscribers that run during line posting.
    - OnAfterPostServiceDoc has no PreviewMode parameter and is not raised in preview.
[6] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Stored field vs related table on Service Ledger Entry and Item Ledger Entry.
    - Use a tableextension stored field on a ledger only when the value must appear as a native list column and is read on almost every access.
    - Put optional, sparse or integration attributes in a related table keyed by the entry number. Applies from BC23.
[7] `microsoft/knowledge/sales-purchase/carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md`: Item Journal Line to Item Ledger Entry hop and its storage condition.
    - Add the field to Item Journal Line and Item Ledger Entry and copy in OnAfterInitItemLedgEntry so the value is written as part of posting.
    - Store it on the ledger entry only when users must see or filter it as a list column or it is read on almost every access; otherwise prefer a related table.
    - Journal lines from other sources leave the field empty; no source filter is needed unless the plan says otherwise.
    - Do not find item ledger entries after posting and Modify them.
[8] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring rule for posted line tables, applied to Service Invoice Line.
    - Same field number, name, type and length on the source and every target table the plan needs.
    - Keep the mirrored field non-editable on posted tables.
    - Do not copy with an OnAfter...Insert subscriber and Modify.
[9] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Exact type and length agreement between Service Line and Service Invoice Line.
    - Define the mirrored field with the exact same number, data type and length on every table in the cascade, at creation time.
[10] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: DataClassification on every added field.
    - Every Normal field a tableextension adds must set its own DataClassification matching the data it stores; never leave ToBeClassified or under-classify as SystemMetadata.
[11] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: Decides that no upgrade code is required unless back-fill is requested.
    - InitValue does not back-fill existing rows; optional fields where empty is a valid state need no upgrade code.
    - If existing rows must carry a value, ship an upgrade procedure guarded by an upgrade tag.
[12] `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`: Guarding an optional back-fill.
    - Every upgrade procedure starts with HasUpgradeTag and ends with SetUpgradeTag; do not branch on version checks.
    - Give the feature its own tag.
[13] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for contracts, service items, service orders and item journals.
    - Create fixtures with the test Library codeunits, parents first, validating foreign keys; no hand-rolled Init/Insert.
[14] `microsoft/knowledge/testing/ui-handlers-in-tests.md`: Running Create Contract Invoices from a test.
    - Every UI call on the executed path (request page, confirms, messages) needs a listed handler, and every nonoptional listed handler must run.
    - Assert the semantic outcome, not only that the handler ran.
[15] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Where to put tooltips for the new fields.
    - From BC24 (runtime 13.0) a bound page field inherits the table field's ToolTip; do not duplicate it on the page. Earlier runtimes need page-level ToolTips.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

