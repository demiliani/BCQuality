# Feature design

> Buyers set a Cost Reason on purchase invoice lines that are charged to a project. Project managers need to see the Cost Reason on project ledger entries for those purchases, including subcontractor hours we buy from vendors.

**Result:** Complete design. **Business process:** Carry a custom Cost Reason from project-linked purchase lines through purchase posting and project usage posting (Purch.-Post, Job Post-Line, Job Transfer Line, Job Jnl.-Post Line) to the project ledger entries. **Knowledge used:** 13 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is a Cost Reason: a free code, a relation to the standard Reason Code table, or a new Cost Reason table maintained by users? This sets the field's type, length and TableRelation on every table, and a new table would need its own page, permissions and setup. _(affects: purchase-line-ext, purch-inv-line-ext, purch-rcpt-line-ext, purch-cr-memo-line-ext, return-shipment-line-ext, purchase-line-archive-ext, job-journal-line-ext, job-ledger-entry-ext)_
2. How are subcontractor hours bought today? Purchase lines of type Resource with a project post only a resource ledger entry and no project usage, so they never reach the project ledger. Should buyers buy subcontractor hours as G/L Account (or Item) lines charged to the project, or post them through a project journal resource line, where the Cost Reason would be entered on the project journal? Should Cost Reason also reach Resource Ledger Entries? _(affects: cost-reason-posting-subscribers, subcontractor-hours-cost-reason-reaches-job-ledger, job-journal-line-ext)_
3. The design mirrors Cost Reason on posted receipt, invoice, credit memo and return shipment lines and on the purchase line archive. Should any of these document types be excluded? _(affects: purch-rcpt-line-ext, purch-cr-memo-line-ext, return-shipment-line-ext, purchase-line-archive-ext, receipt-line-mirrors-cost-reason, credit-memo-line-mirrors-cost-reason, return-shipment-line-mirrors-cost-reason, archive-line-mirrors-cost-reason)_
4. Should Cost Reason also be carried on project ledger entries that do not come from purchases: manual project journal lines, project planning lines, planning lines invoiced through sales, and general journal lines with a project? _(affects: job-journal-line-ext, cost-reason-posting-subscribers)_
5. Should buyers also enter Cost Reason on purchase order and purchase credit memo lines, and should it be shown on posted purchase document line pages? _(affects: purchase-invoice-subform-ext)_
6. Is Cost Reason mandatory on project-linked purchase lines before posting? If so, the check belongs in OnAfterCheckPurchDoc so it also stops the posting preview. _(affects: purchase-line-ext)_
7. Must Cost Reason survive Copy Document (including the recalculate-lines path, which drops custom line fields) and corrective credit memos? _(affects: purchase-line-ext)_
8. Do existing project ledger entries and posted purchase lines need a Cost Reason back-filled, and from what source? _(affects: job-ledger-entry-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Purchase Line | Source of the value: the buyer enters Cost Reason on purchase lines charged to a project. Field number, name, type and length are reused unchanged on every mirror target and carrier table. | Cost Reason (Code[20]): Type and any TableRelation depend on q-cost-reason-source; if a TableRelation is added, the length must equal the related key field and every mirror below must change with it. DataClassification = CustomerContent; ToolTip on the table field. | [2] [7] [8] |
| 2 | extend | tableextension | Purch. Inv. Line | Mirror of the purchase line field so the posted invoice line keeps the Cost Reason; filled by the standard TransferFields in InitFromPurchLine. | Cost Reason (Code[20]): Same field number, name, type and length as Purchase Line; Editable = false. | [5] [6] |
| 3 | extend | tableextension | Purch. Rcpt. Line | Mirror on the posted receipt line, required by the mirroring article unless the requester excludes it (q-mirror-targets). | Cost Reason (Code[20]): Same field number, name, type and length as Purchase Line; Editable = false. | [5] [6] |
| 4 | extend | tableextension | Purch. Cr. Memo Line | Mirror on the posted credit memo line, required by the mirroring article unless the requester excludes it (q-mirror-targets). | Cost Reason (Code[20]): Same field number, name, type and length as Purchase Line; Editable = false. | [5] [6] |
| 5 | extend | tableextension | Return Shipment Line | Mirror on the posted return shipment line, required by the mirroring article unless the requester excludes it (q-mirror-targets). | Cost Reason (Code[20]): Same field number, name, type and length as Purchase Line; Editable = false. | [5] [6] |
| 6 | extend | tableextension | Purchase Line Archive | Mirror on the archived purchase line, required by the mirroring article unless the requester excludes it (q-mirror-targets). | Cost Reason (Code[20]): Same field number, name, type and length as Purchase Line; Editable = false. | [5] [6] |
| 7 | extend | tableextension | Job Journal Line | Carrier for the value between the purchase line and the project ledger. Job Post-Line builds a separate project journal line for each project-linked item or G/L account purchase line; G/L account lines are posted later from a temporary copy of this line, so the value must be on it. | Cost Reason (Code[20]): Same type and length as Purchase Line; copied by event, not by field number. | [2] [3] |
| 8 | extend | tableextension | Job Ledger Entry | Target the project managers read. Filled while the entry is built in Job Transfer Line.FromJnlLineToLedgEntry; matching field numbers alone do nothing because the copy is field by field. | Cost Reason (Code[20]): Same type and length as Job Journal Line; Editable = false. | [4] [2] |
| 9 | create | codeunit | Purchase Cost Reason Posting | Single-purpose subscriber codeunit holding the two Job Transfer Line subscribers: purchase line to project journal line, and project journal line to project ledger entry. One pair covers item and G/L account lines, including subcontractor hours bought as G/L account or item lines. |  | [1] [2] [3] [4] |
| 10 | extend | pageextension | Purch. Invoice Subform | Lets buyers enter Cost Reason on purchase invoice lines. Other purchase line pages (order, credit memo) are q-entry-pages. The page field is bound to the table field and inherits its ToolTip from BC24 (runtime 13.0); on earlier runtimes declare the ToolTip on the page control. |  | [9] |
| 11 | extend | pageextension | Job Ledger Entries | Shows Cost Reason to project managers on the project ledger entries list (non-editable). Bound field inherits the table field ToolTip from BC24 (runtime 13.0). |  | [9] |

## 3. How the data flows

- **Buyer** → **Purchase Line.Cost Reason**: entered by the user. Entered on project-linked purchase invoice lines through the Purch. Invoice Subform page extension. agent judgment
- **Purchase Line** → **Purch. Inv. Line**: standard TransferFields copy. Standard InitFromPurchLine TransferFields; no subscriber needed. [5]
- **Purchase Line** → **Purch. Rcpt. Line**: standard TransferFields copy. Standard InitFromPurchLine TransferFields; stage chosen by the mirroring article, see q-mirror-targets. [5]
- **Purchase Line** → **Purch. Cr. Memo Line**: standard TransferFields copy. Standard InitFromPurchLine TransferFields; stage chosen by the mirroring article, see q-mirror-targets. [5]
- **Purchase Line** → **Return Shipment Line**: standard TransferFields copy. Standard InitFromPurchLine TransferFields; stage chosen by the mirroring article, see q-mirror-targets. [5]
- **Purchase Line** → **Purchase Line Archive**: standard TransferFields copy. ArchiveManagement copies lines with TransferFields; stage chosen by the mirroring article, see q-mirror-targets. [5]
- **Purchase Line** → **Job Journal Line**: copied in an event subscriber. Job Post-Line.PostJobOnPurchaseLine calls Job Transfer Line.FromPurchaseLineToJnlLine for Item and G/L Account lines only; copy in OnAfterFromPurchaseLineToJnlLine. Item lines post at once (Job Posting Only); G/L account lines are held in a temporary table and posted by PostJobPurchaseLines after the G/L entries exist, carrying the value with them. [2] [3]
- **Job Journal Line** → **Job Ledger Entry**: copied in an event subscriber. Job Jnl.-Post Line.CreateJobLedgEntry calls Job Transfer Line.FromJnlLineToLedgEntry for every source; copy in OnAfterFromJnlLineToLedgEntry while the entry is built, never Modify after insert. [4]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Job Transfer Line | `OnAfterFromPurchaseLineToJnlLine` | Copy PurchLine."Cost Reason" to JobJnlLine."Cost Reason" for project-linked Item and G/L Account purchase lines, so the value is set before the deferred G/L account project lines are posted. | Assign the field only; the journal line is still being built, so do not call Modify. | [2] [3] |
| Job Transfer Line | `OnAfterFromJnlLineToLedgEntry` | Copy JobJournalLine."Cost Reason" to JobLedgerEntry."Cost Reason" while the entry is built in CreateJobLedgEntry; one subscriber covers every source of project journal lines. | Assign before insert; never subscribe to OnAfterJobLedgEntryInsert and Modify the inserted entry. | [4] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification = CustomerContent explicitly on Cost Reason in every table extension (a tableextension has no table-level classification to inherit); never leave it ToBeClassified or SystemMetadata. [8]
- **upgrade**: No upgrade code: the field is new, has no InitValue, and blank is a valid state. Project ledger entries and posted lines created before installation stay blank unless back-fill is requested (q-history-backfill). [10] [11]
- **permissions**: No permission set: the feature adds only table extensions, a subscriber codeunit and page extensions, and no new table. agent judgment

## 6. Tests

1. **item-line-cost-reason-reaches-job-ledger** [2] [4] [5] [12] [13]
    - Given A vendor, an item, a project with a project task (created with the test Library codeunits), and a purchase invoice with an Item line charged to the project task with a Cost Reason.
    - When The purchase invoice is posted.
    - Then The Purch. Inv. Line and the project usage Job Ledger Entry for that document carry the same Cost Reason.
2. **gl-account-line-cost-reason-reaches-job-ledger** [2] [3] [12]
    - Given A purchase invoice with a G/L Account line charged to a project task, with a Cost Reason (fixtures from library codeunits).
    - When The purchase invoice is posted.
    - Then The Job Ledger Entry posted after the G/L entries (deferred PostJobPurchaseLines path) carries the Cost Reason.
3. **subcontractor-hours-cost-reason-reaches-job-ledger** [2] [12]
    - Given Subcontractor hours bought from a vendor as a purchase invoice line of the agreed supported type (G/L Account or Item, per q-subcontractor-hours) charged to a project task, with a Cost Reason and a quantity of hours.
    - When The purchase invoice is posted.
    - Then A Job Ledger Entry exists for the hours with the Cost Reason.
4. **receipt-line-mirrors-cost-reason** [5] [12]
    - Given A purchase order with a project-linked Item line with a Cost Reason.
    - When The order is posted as receive only.
    - Then The Purch. Rcpt. Line carries the Cost Reason.
5. **credit-memo-line-mirrors-cost-reason** [5] [4] [12]
    - Given A purchase credit memo with a project-linked Item line with a Cost Reason.
    - When The credit memo is posted.
    - Then The Purch. Cr. Memo Line and the resulting Job Ledger Entry carry the Cost Reason.
6. **return-shipment-line-mirrors-cost-reason** [5] [12]
    - Given A purchase return order with an Item line with a Cost Reason.
    - When The return order is posted as ship only.
    - Then The Return Shipment Line carries the Cost Reason.
7. **archive-line-mirrors-cost-reason** [5] [12]
    - Given A purchase order with a line with a Cost Reason.
    - When The document is archived through ArchiveManagement.
    - Then The Purchase Line Archive row carries the Cost Reason.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown; the ToolTip inheritance rule applies only from BC24 (runtime 13.0).
- Page extensions Purch. Invoice Subform and Job Ledger Entries, beyond ToolTip placement, rest on the agent's judgment: no BCQuality article covers which pages show the field.
- The buyer's user-entry hop on Purchase Line is not covered by BCQuality knowledge; it rests on the agent's judgment.
- No permission set is designed because no table is added; this rests on the agent's judgment and changes if q-cost-reason-source introduces a new table.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Map that selected the Purchase and Projects row groups and the cross-cutting rows (mirrored definitions, copy document, checks before posting, upgrade back-fill, privacy, tests).
    - Plan one row group per process the request touches and open every linked article for the stages chosen.
    - Whether a field should reach a stage the request does not name is a question for the requester; raise one question per group of stages.
    - Do not fill other records with subscribers that find and modify them after posting.
[2] `microsoft/knowledge/projects/project-purchases-post-usage-only-for-item-and-gl-account-lines.md`: Core path Purchase Line -> Job Journal Line -> Job Ledger Entry, and the design of subcontractor hours as supported line types.
    - Add the field to Job Journal Line and Job Ledger Entry; copy it in OnAfterFromPurchaseLineToJnlLine, then in OnAfterFromJnlLineToLedgEntry.
    - Only Item and G/L Account purchase lines with a project post project usage; Resource purchase lines post only a resource ledger entry and no project usage.
    - When project cost comes from a purchase, design it as an item or G/L account line with the project; post resource time through a project journal resource line.
    - Matching field numbers between Purchase Line and Job Ledger Entry do not copy the value.
[3] `microsoft/knowledge/projects/carry-document-fields-to-job-journal-line-on-every-source-path.md`: Purchase line to project journal line hop, and the list of other Job Transfer Line sources raised as an open question.
    - Decide which sources must carry the value and subscribe to the matching Job Transfer Line events.
    - A field that exists only on the project journal is empty for usage posted from a purchase invoice and every other generated line.
[4] `microsoft/knowledge/projects/carry-job-journal-fields-to-job-ledger-through-job-transfer-line.md`: Project journal line to project ledger entry hop.
    - Subscribe to OnAfterFromJnlLineToLedgEntry on Job Transfer Line to copy the value while the entry is built; one subscriber covers every source.
    - Do not rely on matching field numbers, and do not Modify the entry in OnAfterJobLedgEntryInsert.
[5] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Mirroring the line field on posted purchase lines and the line archive.
    - Give the field the same number, name, type and length on Purchase Line and every target: Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line, Return Shipment Line and Purchase Line Archive, unless the plan states a document type never needs it.
    - No subscriber is needed for these stages; keep the mirrored fields non-editable on posted tables.
    - Do not patch posted records with Modify in a subscriber.
[6] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definitions of the mirrored Cost Reason fields.
    - Define the mirrored field with exactly the same field number, data type and length on every table in the TransferFields cascade.
[7] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing Cost Reason if it gets a TableRelation (q-cost-reason-source).
    - For an unconditional relation, give the field the same type and exact length as the related field; read the related field's declared length rather than assuming Code[10] or Code[20].
[8] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of every Cost Reason field.
    - Every Normal field added by a tableextension must set its own DataClassification matching the data it stores; never leave ToBeClassified or use SystemMetadata for customer data.
[9] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: ToolTip placement for the page extension fields; applies from BC24 (runtime 13.0).
    - On runtime 13.0 or later a bound page field inherits the table field's ToolTip; do not add a duplicate page-level ToolTip.
    - On earlier runtimes, or with no inheritable ToolTip, the page control must declare one.
[10] `microsoft/knowledge/upgrade/unreleased-schema-change-needs-no-upgrade-path.md`: No upgrade code for the new field.
    - A schema element that is new in an unreleased version needs no upgrade or migration path.
[11] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: Confirms existing rows stay blank; no InitValue is used, so no back-fill is required by the field definition.
    - InitValue does not back-fill existing rows; if existing rows must carry a value, ship upgrade code guarded by an upgrade tag.
[12] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for every posting test.
    - Build vendors, items, G/L accounts and documents with the test Library codeunits, parents first, validating foreign-key fields.
[13] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Test values.
    - Generate incidental fixture values with library codeunits; keep scenario-defining values such as quantities and the Cost Reason explicit; do not rely on pre-existing records.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

