# Feature design

> Let technicians type a Site Visit Code on project journal lines and on purchase lines charged to a project, and carry it during posting onto every project ledger entry those lines create so project managers can analyze project costs per site visit.

**Result:** Complete design. **Business process:** Project (job) usage posting: project journal posting and purchase document posting with a project, both creating project ledger entries through Job Journal Line, Job Transfer Line and Job Jnl.-Post Line. **Knowledge used:** 10 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is the Site Visit Code's length, and must it be validated against a list of site visits (a new Site Visit master table with a TableRelation) or is it free-form? A master table would add a table, pages, permission set and setup that this design does not cover. _(affects: job-journal-line-ext, purchase-line-ext, job-ledger-entry-ext, posted-purchase-line-exts)_
2. The mirroring guidance puts the field on every posted purchase line table and Purchase Line Archive unless a document type never needs it. Should receipts, invoices, credit memos, return shipments and archives all keep the Site Visit Code, or should any be excluded? _(affects: posted-purchase-line-exts, credit-memo-return-and-archive, purchase-order-receive-and-invoice)_
3. Project usage can also be posted from project planning lines, from planning lines invoiced through sales, and from general journal lines with a project. Must those sources carry a Site Visit Code too (each needs its own field and Job Transfer Line subscriber), or are project journals and purchase lines the only sources? _(affects: site-visit-job-posting, job-journal-line-ext)_
4. Which purchase documents do technicians use for project costs (orders, invoices, credit memos, return orders)? This decides which subform pages get the field. _(affects: purchase-subform-page-exts)_
5. When a user copies a posted or archived purchase document, the mirrored Site Visit Code will flow back to the new purchase lines. Is that wanted? _(affects: purchase-line-ext, posted-purchase-line-exts)_
6. Is the Site Visit Code mandatory on project journal lines and project purchase lines, or optional? _(affects: job-journal-page-ext, purchase-subform-page-exts, job-journal-line-ext, purchase-line-ext)_
7. How will project managers analyze costs per site visit: filtering the Project Ledger Entries list, a report, a query or an analysis view? This confirms the stored-field choice and whether a key or further objects are needed. _(affects: job-ledger-entry-ext, job-ledger-entries-page-ext)_
8. Should existing project ledger entries posted before the feature be back-filled, or stay blank? _(affects: job-ledger-entry-ext)_
9. Does a Site Visit Code ever identify a person (for example a technician)? If not, CustomerContent is the likely classification. _(affects: job-journal-line-ext, purchase-line-ext, job-ledger-entry-ext, posted-purchase-line-exts)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Job Journal Line | Hold the Site Visit Code typed by technicians in the project journal, and receive it from purchase lines when Job Transfer Line builds the project journal line for purchase usage. It is the single source the ledger copy reads from. | Site Visit Code (Code[N] (length to be confirmed; see open question field-length-and-relation)): Same type and length as on Purchase Line and Job Ledger Entry so the event copies never truncate. Set DataClassification on the field itself (a tableextension has no table-level value to inherit). Define the ToolTip on the table field when the target runtime is 13.0 or later. | [1] [2] [7] [8] |
| 2 | extend | tableextension | Purchase Line | Hold the Site Visit Code typed on purchase lines charged to a project; source for the project journal line built at posting and for the posted purchase line tables filled by TransferFields. | Site Visit Code (Code[N] (length to be confirmed; see open question field-length-and-relation)): Field number, name, type and length identical on every TransferFields target (posted purchase lines and Purchase Line Archive). Explicit DataClassification. ToolTip on the table field when the target runtime is 13.0 or later. | [2] [3] [5] [7] [8] |
| 3 | extend | tableextension | Job Ledger Entry | Store the Site Visit Code on each project ledger entry so project managers can filter and analyze costs per site visit. A stored tableextension field is chosen over a related table keyed by Entry No.: the hot-ledger article keeps stored fields for values that must appear as a native list column and are read on almost every access, which matches per-site-visit cost analysis; Job Ledger Entry is not among the hot ledgers the article names. If analysis only needs occasional lookups, revisit (see open question analysis-surface). | Site Visit Code (Code[N] (same type and length as Job Journal Line)): Editable = false. Explicit DataClassification. Filled while the entry is built, never by modifying the inserted entry. | [1] [6] [7] |
| 4 | extend | tableextension | Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line, Return Shipment Line, Purchase Line Archive (one tableextension each) | Mirror the purchase line field on every TransferFields target so posted and archived purchase lines keep the Site Visit Code. Chosen by the mirroring article, not by the request; the requester can exclude document types (see open question posted-purchase-lines). | Site Visit Code (Code[N] (identical field number, type and length to Purchase Line)): Editable = false on the posted tables. Explicit DataClassification. No subscriber: the standard TransferFields call in InitFromPurchLine and archiving does the copy. | [3] [5] [7] |
| 5 | create | codeunit | Site Visit Job Posting (new event subscriber codeunit) | Hold the two Job Transfer Line subscribers: purchase line to project journal line, and project journal line to project ledger entry. |  | [1] [2] |
| 6 | extend | pageextension | Job Journal | Let technicians type the Site Visit Code on project journal lines. |  | [8] [9] |
| 7 | extend | pageextension | Purchase line subform pages the technicians use (for example Purchase Order Subform, Purch. Invoice Subform, Purch. Cr. Memo Subform) | Let users type the Site Visit Code on purchase lines charged to a project. Which subforms are needed is an open question (purchase-documents-in-scope). |  | [8] [9] |
| 8 | extend | pageextension | Job Ledger Entries | Show the Site Visit Code as a list column so project managers can filter and analyze costs per site visit. |  | [8] [9] |

## 3. How the data flows

- **Technician** → **Job Journal Line.Site Visit Code**: entered by the user. Typed on the Job Journal page. [1]
- **Technician** → **Purchase Line.Site Visit Code**: entered by the user. Typed on purchase lines that carry a project. [2]
- **Purchase Line.Site Visit Code** → **Job Journal Line.Site Visit Code**: copied in an event subscriber. Job Post-Line.PostJobOnPurchaseLine builds a project journal line through Job Transfer Line.FromPurchaseLineToJnlLine; copy in OnAfterFromPurchaseLineToJnlLine. [2]
- **Job Journal Line.Site Visit Code** → **Job Ledger Entry.Site Visit Code**: copied in an event subscriber. Job Jnl.-Post Line.CreateJobLedgEntry calls Job Transfer Line.FromJnlLineToLedgEntry; copy in OnAfterFromJnlLineToLedgEntry. One subscriber covers project journal and purchase sources because both post through CreateJobLedgEntry. [1]
- **Purchase Line.Site Visit Code** → **Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line, Return Shipment Line, Purchase Line Archive**: standard TransferFields copy. InitFromPurchLine and archiving call TransferFields; requires the same field number, type and length on each target. [3] [5]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Job Transfer Line" | `OnAfterFromPurchaseLineToJnlLine` | Copy Purchase Line.Site Visit Code to the project journal line built for purchase usage on a project. |  | [2] |
| Codeunit "Job Transfer Line" | `OnAfterFromJnlLineToLedgEntry` | Copy Job Journal Line.Site Visit Code to the Job Ledger Entry while it is being built, before insert. | Assign only; do not call Modify. Do not use OnAfterJobLedgEntryInsert with Modify, and do not rely on matching field numbers. | [1] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification explicitly on every Site Visit Code field in every tableextension; choose the value that matches what the code stores (CustomerContent is the likely value; confirm it holds no personal identifier) and never leave ToBeClassified or use SystemMetadata to silence the compiler. [7]
- **other**: Write the tooltip once on the table field when the target runtime is 13.0 (BC24) or later and let bound page fields inherit it; on earlier runtimes put the tooltip on each page field. Describe what the code is used for (analysis of project costs per site visit), not just its name. [8] [9]

## 6. Tests

1. **job-journal-to-job-ledger** [1] [10]
    - Given A project with a task and a resource or item, created with the test library codeunits, and a project journal line with a Site Visit Code
    - When The project journal line is posted
    - Then Every Job Ledger Entry created for that line carries the same Site Visit Code
2. **purchase-invoice-to-job-ledger** [2] [1] [10]
    - Given A purchase invoice built with LibraryPurchase whose line has a project, project task and a Site Visit Code
    - When The purchase invoice is posted
    - Then The project usage Job Ledger Entry for that line carries the Site Visit Code (proves the purchase line to project journal line hop and the ledger hop)
3. **purchase-order-receive-and-invoice** [3] [2] [10]
    - Given A purchase order line charged to a project with a Site Visit Code
    - When The order is received and invoiced
    - Then Purch. Rcpt. Line, Purch. Inv. Line and the resulting Job Ledger Entry all carry the Site Visit Code
4. **credit-memo-return-and-archive** [3] [10]
    - Given A purchase credit memo or return order line charged to a project with a Site Visit Code, and a purchase document that is archived
    - When The credit memo or return order is posted and the document is archived
    - Then Purch. Cr. Memo Line, Return Shipment Line and Purchase Line Archive carry the Site Visit Code
5. **max-length-value-survives-posting** [5]
    - Given A purchase line with a Site Visit Code that uses the full declared field length
    - When The document is posted
    - Then Posting succeeds and every target (posted lines, project ledger entry) holds the full value, proving identical type and length on all mirrored fields
6. **ledger-entry-not-modified-after-insert** [1]
    - Given A project journal line with a Site Visit Code
    - When The line is posted
    - Then The Job Ledger Entry holds the value at insert; the implementation contains no OnAfterJobLedgEntryInsert subscriber that modifies the entry (code review check backing the guard)

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined (no repository or app.json); tooltip placement depends on whether the target runtime is 13.0 (BC24) or later.
- The choice of purchase subform pages and the Job Journal and Job Ledger Entries page extensions rests on the agent's judgment of where users type and read the value; the cited articles govern tooltips, not page selection.
- Purchase-side Copy Document handling has no confirmed purchase event in the opened knowledge; if flow-back must be prevented, the event must be confirmed in symbols before design.

## Sources

[1] `microsoft/knowledge/projects/carry-job-journal-fields-to-job-ledger-through-job-transfer-line.md`: Journal-to-ledger hop: fields on Job Journal Line and Job Ledger Entry plus the OnAfterFromJnlLineToLedgEntry subscriber.
    - Every Job Ledger Entry is created in Job Jnl.-Post Line.CreateJobLedgEntry, which copies fields one by one through Job Transfer Line.FromJnlLineToLedgEntry; matching field numbers do nothing.
    - Add the field to Job Journal Line and Job Ledger Entry and copy it in OnAfterFromJnlLineToLedgEntry; one subscriber covers every source.
    - OnBeforeJobLedgEntryInsert is acceptable only when the value is computed rather than copied.
    - Do not subscribe to OnAfterJobLedgEntryInsert and call Modify on the inserted entry.
[2] `microsoft/knowledge/projects/carry-document-fields-to-job-journal-line-on-every-source-path.md`: Purchase-line-to-project-journal-line hop and the decision which project journal sources must carry the value.
    - Project journal lines are built by Job Transfer Line from purchase lines, planning lines, planning lines invoiced through sales, and general journal lines; a field only on the project journal is empty for those.
    - Decide in the design which sources must carry the value and subscribe to the matching event; for purchase lines that is OnAfterFromPurchaseLineToJnlLine.
    - Do not design the field only on the project journal and project ledger assuming all usage is entered in project journals.
[3] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Posted and archived purchase line tables that receive the Purchase Line field by TransferFields.
    - Posted lines are created by InitFromPurchLine with TransferFields into Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line and Return Shipment Line; archiving copies into Purchase Line Archive.
    - Use the same field number, name, type and length on every target the plan needs; unless the plan states a document type never needs the field, that means all four posted tables and the archive.
    - No subscriber is needed for these stages; keep the mirrored fields non-editable on the posted tables.
    - Do not use a different field number and patch posted records with Modify in a subscriber.
[4] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Planning method applied to the purchase side: decide every stage the field must reach, and plan page extensions and a post-and-read-back test per stage; also raises the Copy Document flow-back question.
    - Before writing code, decide which stages the field must reach and plan one step per stage; do not plan only the tables the requester named.
    - For each stage name the page extensions that show the field and a test that posts a document and reads the value back from every target.
    - Copy Document copies posted and archived documents back with TransferFields, so a mirrored field flows back; decide in the plan whether that is wanted. Do not copy a sales subscriber to purchases without checking the purchase event.
    - Do not fill ledger entries after posting by finding and modifying them.
[5] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definition consistency across the purchase TransferFields cascade.
    - Define a mirrored field with the exact same field number, data type and length on every table in the cascade at creation time.
    - A shorter length on one side compiles and fails at runtime only when a longer value is copied.
[6] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choice between a stored field on Job Ledger Entry and a related table. Applies from BC23.
    - Put optional, sparse or integration attributes on hot ledgers in a related table keyed by the ledger Entry No.
    - Use a tableextension stored field only when the value must appear as a native list column and is read on almost every access.
[7] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: DataClassification on every new tableextension field.
    - A tableextension has no table-level value to inherit, so every Normal field it adds must set its own DataClassification.
    - Choose the value that matches the data stored, at field definition time; ToBeClassified is not a safe default and SystemMetadata must not be used for customer data.
[8] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the Site Visit Code on journal, purchase and ledger pages.
    - On runtime 13.0 or later define the tooltip on the table field and omit duplicate page-level tooltips; before runtime 13.0 user-facing page fields need page-level tooltips.
    - Tooltip text should say what the value is used for, without inventing behavior.
[9] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Tooltip inheritance for the bound page fields. Applies from BC24.
    - A bound page field inherits a non-empty source field ToolTip on runtime 13.0 or later; do not add a duplicate page-level property unless the page needs different help.
[10] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for the posting tests.
    - Build prerequisite records with the test Library codeunits (for example LibraryPurchase, LibraryRandom), not hand-rolled Init/Insert.
    - Create parents first and Validate foreign-key fields so table relations and validation run as in production.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
