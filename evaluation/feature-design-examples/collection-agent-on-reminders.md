# Feature design

> Customers are assigned a Collection Agent. Reminders and finance charge memos must show the agent, the issued documents must keep it, and the customer ledger entries created when they are issued must carry it so we can track each agent's collections.

**Result:** Partial design: some parts could not be designed. **Business process:** Reminder and finance charge memo issuing (Reminder-Issue, FinChrgMemo-Issue) and the customer ledger posting it triggers. **Knowledge used:** 17 BCQuality articles.

**Why:** The copy of the agent from Customer to Reminder Header and Finance Charge Memo Header needs an event that no opened BCQuality article confirms and no repository was supplied to check symbols; the issued-document, journal-line and customer-ledger hops are fully designed.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Is the Collection Agent a new list of agents, or should the field reuse an existing table such as Salesperson/Purchaser? Reusing an existing table removes the new table, page and permissions and changes every field's type and length to match its key. _(affects: collection-agent-table, collection-agents-page, customer-ext, reminder-header-ext, fin-charge-memo-header-ext, issued-reminder-header-ext, issued-fin-charge-memo-header-ext, gen-journal-line-ext, cust-ledger-entry-ext, collection-agent-permissions)_
2. Are collection agents named persons (employees or external collectors)? If so, the agent name is personal data and needs EndUserIdentifiableInformation rather than CustomerContent. _(affects: collection-agent-table)_
3. May users change the agent on an open reminder or finance charge memo, or must it always equal the customer's agent? What happens to open documents when the customer's agent changes? _(affects: reminder-header-ext, fin-charge-memo-header-ext, reminder-page-ext, fin-charge-memo-page-ext)_
4. Does 'show the agent' include the printed or emailed reminder and finance charge memo reports, or only the pages? Printed output would need report extensions and layout selection, which are not designed. _(affects: reminder-page-ext, fin-charge-memo-page-ext, issued-reminder-page-ext, issued-fin-charge-memo-page-ext)_
5. Must users filter or see the agent as a column on Customer Ledger Entries? The design stores the field on Cust. Ledger Entry for that reason; if not, a related table keyed by Entry No. is preferred. _(affects: cust-ledger-entry-ext, customer-ledger-entries-page-ext)_
6. Should G/L entries created by issuing also carry the agent? Not designed; the journal-line field would allow it. _(affects: gen-journal-line-ext)_
7. Do 'each agent's collections' also include payments and sales invoices for the customer? Only entries created by issuing reminders and finance charge memos are designed; payments and sales postings would need their own hops. _(affects: cust-ledger-entry-ext, collection-agent-issuing-codeunit)_
8. Must existing customers, open reminders or already issued documents and entries receive an agent when the app is installed or upgraded? No install or upgrade step is designed. _(affects: customer-ext, issued-reminder-header-ext, cust-ledger-entry-ext)_
9. Is the agent needed only on headers, or also on reminder and finance charge memo lines? Only headers are designed. _(affects: reminder-header-ext, fin-charge-memo-header-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Collection Agent | Supplemental table listing the collection agents that can be assigned to customers. Primary key Code (Code[10]) and a Name field; plural list page set as LookupPageID. Table-level DataClassification covers its fields; the Name field overrides it if it identifies a person (see open question). | Code (Code[10]): Primary key, per the Supplemental table-type convention.; Name (Text[100]): Length is agent judgment; classification depends on whether agents are named persons. | [6] [7] [10] [9] [11] |
| 2 | create | page | Collection Agents | List page for the Collection Agent table, named after the table it shows and used as its LookupPageID. |  | [7] [15] [14] |
| 3 | extend | tableextension | Customer | Holds the customer's assigned collection agent. | Collection Agent Code (Code[10]): TableRelation = "Collection Agent".Code; exact type and length of the related key. Explicit DataClassification = CustomerContent, because a tableextension inherits no table-level value. | [8] [10] [9] |
| 4 | extend | pageextension | Customer Card | Lets users assign the collection agent on the customer. |  | [14] |
| 5 | extend | tableextension | Reminder Header | Carries the agent on the reminder so it can be shown and transferred to the issued reminder. | Collection Agent Code (Code[10]): Field 50100, Code[10], same number and type as on every other table in the cascade; explicit DataClassification = CustomerContent. TableRelation to Collection Agent. | [1] [3] [8] [10] |
| 6 | extend | tableextension | Issued Reminder Header | Keeps the agent on the issued reminder; filled by the standard TransferFields from Reminder Header, so no subscriber writes it. | Collection Agent Code (Code[10]): Field 50100, Code[10], same number and type as on every other table in the cascade; explicit DataClassification = CustomerContent. Editable = false. | [1] [3] [10] |
| 7 | extend | tableextension | Finance Charge Memo Header | Carries the agent on the finance charge memo so it can be shown and transferred to the issued memo. | Collection Agent Code (Code[10]): Field 50100, Code[10], same number and type as on every other table in the cascade; explicit DataClassification = CustomerContent. TableRelation to Collection Agent. | [1] [3] [8] [10] |
| 8 | extend | tableextension | Issued Fin. Charge Memo Header | Keeps the agent on the issued finance charge memo; filled by the standard TransferFields from Finance Charge Memo Header. | Collection Agent Code (Code[10]): Field 50100, Code[10], same number and type as on every other table in the cascade; explicit DataClassification = CustomerContent. Editable = false. | [1] [3] [10] |
| 9 | extend | tableextension | Gen. Journal Line | Carries the agent on the temporary journal lines that Reminder-Issue and FinChrgMemo-Issue build, so the customer ledger entry can receive it during posting. | Collection Agent Code (Code[10]): Explicit DataClassification = CustomerContent. | [1] [2] [10] |
| 10 | extend | tableextension | Cust. Ledger Entry | Stores the agent on customer ledger entries created by issuing. Chosen as a stored field rather than a related table because the request is to track each agent's collections, which implies filtering the entries list by agent; the hot-ledger article allows a stored field only when the value must appear as a native list column (confirm in open questions). | Collection Agent Code (Code[10]): Explicit DataClassification = CustomerContent; Editable = false. | [2] [4] [10] |
| 11 | extend | pageextension | Reminder | Shows the agent on the reminder. |  | [14] |
| 12 | extend | pageextension | Finance Charge Memo | Shows the agent on the finance charge memo. |  | [14] |
| 13 | extend | pageextension | Issued Reminder | Shows the kept agent on the issued reminder. |  | [14] |
| 14 | extend | pageextension | Issued Finance Charge Memo | Shows the kept agent on the issued finance charge memo. |  | [14] |
| 15 | extend | pageextension | Customer Ledger Entries | Shows the agent as a list column so entries can be filtered per agent. |  | [14] [4] |
| 16 | create | codeunit | Collection Agent Issuing | Event subscribers that copy the agent from the reminder or finance charge memo header to the issuing journal lines, and from the journal line to the customer ledger entry. |  | [1] [2] |
| 17 | create | permissionset | Collection Agent - Objects | Non-assignable building block granting the new table, page and codeunit explicitly, included through IncludedPermissionSets in an assignable role-shaped set; no wildcard grants. |  | [6] [12] [13] |
| 18 | create | codeunit | Collection Agent Tests | Test codeunit covering every data-flow hop by issuing documents and reading the agent back. |  | [16] [17] |

## 3. How the data flows

- **Collection Agent** → **Customer."Collection Agent Code"**: entered by the user. User assigns the agent on the Customer Card; the TableRelation validates it. [8]
- **Customer."Collection Agent Code"** → **Reminder Header."Collection Agent Code"**: other. UNRESOLVED: no opened article or repository symbol confirms an event raised when Reminder Header copies customer data (manual entry or Create Reminders). The copy point must be confirmed in BaseApp symbols before implementation. agent judgment
- **Customer."Collection Agent Code"** → **Finance Charge Memo Header."Collection Agent Code"**: other. UNRESOLVED: no opened article or repository symbol confirms an event raised when Finance Charge Memo Header copies customer data. The copy point must be confirmed in BaseApp symbols before implementation. agent judgment
- **Reminder Header** → **Issued Reminder Header**: standard TransferFields copy. Reminder-Issue (393) fills the issued header with TransferFields; same field number and type is enough, no subscriber and no Modify in OnAfterIssueReminder. [1] [3]
- **Finance Charge Memo Header** → **Issued Fin. Charge Memo Header**: standard TransferFields copy. FinChrgMemo-Issue (395) fills the issued header with TransferFields. [1] [3]
- **Reminder Header** → **Gen. Journal Line**: copied in an event subscriber. Reminder-Issue OnAfterInitGenJnlLine; the sales CopyFromSalesHeader event never fires for reminder entries. [1]
- **Finance Charge Memo Header** → **Gen. Journal Line**: copied in an event subscriber. FinChrgMemo-Issue OnAfterInitGenJnlLine. [1]
- **Gen. Journal Line** → **Cust. Ledger Entry**: copied in an event subscriber. OnAfterCopyCustLedgerEntryFromGenJnlLine, while the entry is initialized and before it is inserted; never by modifying posted entries afterwards. [2] [1] [5]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Reminder-Issue" (393) | `OnAfterInitGenJnlLine(var GenJournalLine; ReminderHeader; var SrcCode; AccNo)` | Copy the agent from the reminder header to each journal line built for interest, fees and the customer total. | Plain assignment only; declare only the parameters used. · Runs inside the issuing transaction: no external calls, no Modify of other records. | [1] |
| Codeunit "FinChrgMemo-Issue" (395) | `OnAfterInitGenJnlLine(var GenJnlLine; FinChargeMemoHeader; var SrcCode)` | Copy the agent from the finance charge memo header to each journal line it builds. | Parameter names differ from the Reminder-Issue event (GenJnlLine, FinChargeMemoHeader); do not copy the reminder subscriber signature. · Runs inside the issuing transaction: no external calls, no Modify of other records. | [1] |
| Table "Cust. Ledger Entry" | `OnAfterCopyCustLedgerEntryFromGenJnlLine(var CustLedgerEntry; GenJournalLine)` | Copy the agent from the journal line to the customer ledger entry before it is inserted. | Assign during initialization; never find and Modify posted customer entries after issuing. | [2] [5] |

## 5. Setup, permissions and lifecycle

- **permissions**: Ship a non-assignable building-block permission set listing tabledata Collection Agent (RIMD), table/page/codeunit execute entries for the new objects, and include it through IncludedPermissionSets in an assignable set; enumerate each object, no wildcards. [6] [12] [13]
- **privacy**: Classify the Collection Agent table at table level and override the Name field if it identifies a person; give every field added by a tableextension an explicit DataClassification (CustomerContent); leave no ToBeClassified. [9] [10] [11] [6]
- **other**: Tooltips: on runtime 13.0 (BC24) or later define the tooltip on the table fields and let bound page fields inherit it; on earlier targets add page-level tooltips on every page extension. Applies conditionally because the target bc-version is unknown. [14]

## 6. Tests

1. **customer-agent-defaults-to-reminder** [16] [17]
    - Given A customer with a Collection Agent, created with the test Library codeunits
    - When A reminder is created for the customer
    - Then Reminder Header shows the customer's Collection Agent Code (depends on the unresolved copy point)
2. **customer-agent-defaults-to-fin-charge-memo** [16] [17]
    - Given A customer with a Collection Agent
    - When A finance charge memo is created for the customer
    - Then Finance Charge Memo Header shows the customer's Collection Agent Code (depends on the unresolved copy point)
3. **issued-reminder-keeps-agent** [1] [3] [16] [17]
    - Given A reminder with a Collection Agent Code
    - When The reminder is issued
    - Then Issued Reminder Header has the same Collection Agent Code
4. **issued-fin-charge-memo-keeps-agent** [1] [3] [16] [17]
    - Given A finance charge memo with a Collection Agent Code
    - When The memo is issued
    - Then Issued Fin. Charge Memo Header has the same Collection Agent Code
5. **reminder-cust-ledger-entries-carry-agent** [1] [2] [16] [17]
    - Given A reminder with a Collection Agent Code and an additional fee or interest that posts entries
    - When The reminder is issued
    - Then Every Cust. Ledger Entry created for the issued reminder carries the Collection Agent Code
6. **fin-charge-memo-cust-ledger-entries-carry-agent** [1] [2] [16] [17]
    - Given A finance charge memo with a Collection Agent Code and amounts that post entries
    - When The memo is issued
    - Then Every Cust. Ledger Entry created for the issued memo carries the Collection Agent Code
7. **issuing-subscribers-do-not-modify-posted-entries** [1] [5] [17]
    - Given A reminder with a Collection Agent Code
    - When The reminder is issued
    - Then The agent is present on the customer ledger entry as inserted by posting, with no subscriber on OnAfterIssueReminder modifying the issued header or the entries

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Material gap: event for copying Customer."Collection Agent Code" to Reminder Header (manual entry and Create Reminders) is not confirmed by any opened article or repository symbols.
- Material gap: event for copying Customer."Collection Agent Code" to Finance Charge Memo Header is not confirmed by any opened article or repository symbols.
- Not covered by BCQuality knowledge: the Customer-to-reminder and Customer-to-finance-charge-memo hops rest on agent judgment only.
- Applicability dimensions unknown: bc-version, countries, application-area (no repository or app.json supplied); all cited articles declare [all] / w1, and the tooltip guidance applies conditionally on runtime 13.0 (BC24).

## Sources

[1] `microsoft/knowledge/finance-extensions/carry-reminder-and-finance-charge-fields-when-issuing.md`: Issued-document and ledger-entry hops for reminders and finance charge memos, and the issuing subscribers.
    - Issued headers are filled by TransferFields: give the field the same number and type on source and issued tables; no subscriber is needed.
    - Carry the value to customer and G/L entries by adding it to Gen. Journal Line and setting it in each issuing codeunit's own OnAfterInitGenJnlLine; the sales OnAfterCopyGenJnlLineFromSalesHeader never fires for reminder entries.
    - OnAfterIssueReminder and OnAfterIssueFinChargeMemo run inside the issuing transaction; an error there undoes the issued document, so keep external calls out.
    - Do not fill the issued header in OnAfterIssueReminder with Modify.
[2] `microsoft/knowledge/sales-purchase/carry-sales-fields-to-customer-ledger-through-the-journal-line.md`: Customer-entry hop from Gen. Journal Line to Cust. Ledger Entry.
    - Add the field to Gen. Journal Line and Cust. Ledger Entry and copy it in OnAfterCopyCustLedgerEntryFromGenJnlLine while the entry is initialized, before insert.
    - Store the field on the ledger entry only when users must see or filter it as a native list column, or it is read on almost every access.
    - Do not find and Modify the customer entry after posting.
[3] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Mirroring the agent field across the TransferFields cascade to the issued headers.
    - Define the mirrored field with the exact same field number, data type and length on every table in the cascade.
[4] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choosing a stored field on Cust. Ledger Entry instead of a related table.
    - Put optional, sparse or integration attributes in a related table keyed by Entry No.
    - Use a tableextension stored field on a hot ledger only when the value must appear as a native list column and is read on almost every access.
[5] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Guard that ledger entries receive the agent during posting, not by later row edits.
    - Do not change posted financial entries in place outside the supported posting and correction workflows.
[6] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Decisions for the new Collection Agent entity: table type, privacy, pages, permissions and tests.
    - Plan table type, numbering, setup, data rules, privacy, pages, permissions, install/upgrade and tests before building.
    - A decision the request does not settle is a question for the requester, not a default to assume.
[7] `microsoft/knowledge/data-modeling/table-design-must-match-bc-table-type-conventions.md`: Collection Agent as a Supplemental table.
    - Supplemental tables use a Code[10] primary key named Code and one plural List page set as LookupPageID.
[8] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing every Collection Agent Code field that relates to the Collection Agent table.
    - A field with an unconditional TableRelation must have the exact type and length of the related field.
[9] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classification of the agent fields and the agent name.
    - Set DataClassification to match the data actually stored; personal identifiers are EndUserIdentifiableInformation or EndUserPseudonymousIdentifiers; never SystemMetadata for customer or personal data.
[10] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Table-level classification on the new table and explicit field-level classification on every tableextension field.
    - A tableextension inherits no table-level DataClassification; every Normal field it adds must classify itself.
[11] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of the classification.
    - No field may ship with ToBeClassified.
[12] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure.
    - Use non-assignable building blocks composed into assignable role-shaped sets through IncludedPermissionSets.
[13] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Permission set entries.
    - Enumerate each tabledata and table entry explicitly; no wildcard grants; grant only the letters required.
[14] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on the new fields shown on pages; applies conditionally on target runtime (table-field tooltips from BC24/runtime 13.0).
    - On runtime 13.0 or later define the tooltip on the table field and let bound page fields inherit it; before that, add page-level tooltips.
    - Tooltip text must say what the value is used for, not repeat the caption.
[15] `microsoft/knowledge/style/page-name-must-match-source-table.md`: Naming the new list page.
    - A page name must describe the table it shows.
[16] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for customers, reminders and finance charge memos.
    - Build fixtures with the test Library codeunits, top-down, validating foreign-key fields; no hand-rolled Init/Insert.
[17] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Test structure.
    - Tag the test codeunit with [FEATURE] and each test with [SCENARIO], [GIVEN], [WHEN], [THEN].

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
