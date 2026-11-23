# Feature design

> Our holding company posts monthly management-fee settlements to each subsidiary in the same database. Build a function that posts the settlement from the holding company with a Settlement Ref. code, so the subsidiary gets a matching journal line with the same Settlement Ref. to post on its side.

**Result:** Complete design. **Business process:** From the holding company, post a management-fee settlement through an Intercompany general journal batch carrying a Settlement Ref., so the standard IC outbox, same-database IC inbox and inbox acceptance (ICInboxOutboxMgt) create the subsidiary's general journal line with the same Settlement Ref. for the subsidiary to post; this changes intercompany general journal posting. **Knowledge used:** 17 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Which G/L account does the management fee post to in the holding company, which IC G/L account is sent to subsidiaries, and is it one per company or does it differ per subsidiary? Which side is debit and which credit (sign of Amount)? _(affects: ic-settlement-setup, ic-settlement-post)_
2. Does the management fee carry VAT in the holding or subsidiary companies? With automatic Normal VAT the journal Amount must be the VAT-inclusive total. _(affects: ic-settlement-post, ic-settlement-setup)_
3. Where does the Settlement Ref. come from (entered by the user, built from period and partner, or a number series), and must it be unique per subsidiary and month? _(affects: ic-settlement-post, gen-journal-line-ext)_
4. Is the function called once per subsidiary with an amount, or should one run post all subsidiaries' monthly fees, and where do the amounts come from? Which posting date (e.g. month end) is used? _(affects: ic-settlement-post)_
5. Should Settlement Ref. also reach stages the request does not name: G/L entries in the holding and subsidiary companies, and the handled IC history tables (Handled IC Inbox Jnl. Line is designed because the article requires it; Handled IC Outbox Jnl. Line is not)? Exclude any you do not need. _(affects: handled-ic-inbox-jnl-line-ext, gen-journal-line-ext)_
6. Will the holding company use Auto. Send Transactions and the subsidiaries auto-accept, or are settlements sent and accepted by hand? Both are covered by the same events; the answer decides which test paths matter. _(affects: auto-send-and-auto-accept-carry-ref, send-to-partner-copies-ref-to-inbox)_
7. Should Settlement Ref. be shown on the general journal and IC inbox/outbox journal pages in the subsidiary and holding company? _(affects: gen-journal-line-ext, ic-inbox-jnl-line-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Gen. Journal Line | Holds Settlement Ref. on the holding company's IC journal line and on the subsidiary's journal line created when the inbox transaction is accepted. Field number, type and length must be identical on all four IC journal tables. | Settlement Ref. (Code[20]): Same field number, type and length as on IC Outbox Jnl. Line, IC Inbox Jnl. Line and Handled IC Inbox Jnl. Line; set DataClassification on the field. | [1] [10] [11] [3] |
| 2 | extend | tableextension | IC Outbox Jnl. Line | Carries Settlement Ref. on the outbox transaction created by Gen. Jnl.-Post Batch in the holding company. | Settlement Ref. (Code[20]): Same field number, type and length as on Gen. Journal Line. | [1] [10] [11] |
| 3 | extend | tableextension | IC Inbox Jnl. Line | Carries Settlement Ref. on the subsidiary's inbox line. The row is built field by field and then copied into the partner company by IC Data Exchange Database with TransferFields, so the same field number is required. | Settlement Ref. (Code[20]): Same field number, type and length as on IC Outbox Jnl. Line and Handled IC Inbox Jnl. Line. | [1] [2] [10] [11] |
| 4 | extend | tableextension | Handled IC Inbox Jnl. Line | Keeps Settlement Ref. on the handled inbox history; CreateJournalLines fills this table with TransferFields from IC Inbox Jnl. Line. Designed because the article requires it; see the open question on history and ledger stages. | Settlement Ref. (Code[20]): Same field number, type and length as on IC Inbox Jnl. Line. | [1] [2] [10] [11] |
| 5 | create | table | IC Settlement Setup | Singleton setup (Primary Key Code[10], blank) naming the feature's own Intercompany journal template and batch and the accounts the settlement posts to, so batch posting reaches only the feature's lines and no account is hard-coded. | Primary Key (Code[10]): Sole key, left blank.; Journal Template Name (Code[10]): Must be a Gen. Journal Template of Type Intercompany; only that type creates the IC outbox transaction.; Journal Batch Name (Code[10]): Batch reserved for settlements; its No. Series supplies document numbers.; Mgmt. Fee G/L Account No. (Code[20]): Holding company account the fee posts to; which account is an open question.; IC G/L Account No. (Code[20]): IC Account No. sent to the partner and translated to the subsidiary's own account on acceptance; open question whether it is one per company or per partner. | [9] [4] [5] [1] |
| 6 | create | page | IC Settlement Setup | Card page over the setup with InsertAllowed = false, DeleteAllowed = false and an OnOpenPage guard that inserts the blank row if missing. |  | [9] |
| 7 | create | codeunit | IC Settlement Post | PostSettlement(IC Partner Code, Amount, Settlement Ref., Posting Date): Get setup and TestField template, batch and both accounts; TestField the template Type = Intercompany; error if the reserved batch is not empty; create the line with SetUpNewLine so the document number comes from the batch series; Validate Account Type/Account No. (fee account), Bal. Account Type IC Partner/Bal. Account No., IC Account Type/IC Account No. and Amount so the single line is self-balancing; set Settlement Ref.; Insert(true); post with Gen. Jnl.-Post Batch. Never writes the subsidiary's journal with ChangeCompany: the subsidiary's line is created by CreateJournalLines running in the subsidiary company. Transaction boundary: the feature has no own writes that must roll back with posting, so the batch's standard Commit is kept. |  | [1] [5] [4] [8] [6] [7] |
| 8 | create | codeunit | IC Settlement Subscribers | Static subscribers to the three ICInboxOutboxMgt journal events that copy Settlement Ref. hop by hop (journal to outbox, outbox to inbox, inbox to subsidiary journal line). |  | [1] |
| 9 | create | permissionset | IC Settlement Objects | Building block, Assignable = false: explicit entries for table IC Settlement Setup, tabledata IC Settlement Setup = RIMD, page IC Settlement Setup, and execute on both codeunits; no wildcards. |  | [12] [13] |
| 10 | create | permissionset | IC Settlement | Assignable role set that includes IC Settlement Objects through IncludedPermissionSets, for users who post settlements and maintain the setup. |  | [12] [13] |

## 3. How the data flows

- **PostSettlement parameters (Settlement Ref.)** → **Gen. Journal Line (holding company, Intercompany batch)**: other. Assigned by IC Settlement Post before Insert; account fields are validated, not assigned. [1] [5]
- **Gen. Journal Line (holding company)** → **IC Outbox Jnl. Line**: copied in an event subscriber. Gen. Jnl.-Post Batch ProcessICLines/PostGenJournalLine create the outbox line; copied in OnInsertOutboxJnlLineOnBeforeICOutboxJnlLineInsert. Only happens for a template of Type Intercompany. [1]
- **IC Outbox Jnl. Line** → **IC Inbox Jnl. Line**: copied in an event subscriber. Built field by field by Move IC Trans. to Partner Comp (manual Send to IC Partner or Auto. Send Transactions); copied in OnOutboxJnlLineToInboxOnBeforeICInboxJnlLineInsert, which may run in the holding company. [1] [2]
- **IC Inbox Jnl. Line (built in holding company)** → **IC Inbox Jnl. Line (subsidiary company)**: standard TransferFields copy. IC Data Exchange Database writes the same-database partner's inbox with ChangeCompany, TransferFields and Insert without triggers; requires the same field number and type/length. [1] [2] [10]
- **IC Inbox Jnl. Line (subsidiary)** → **Gen. Journal Line (subsidiary company)**: copied in an event subscriber. Complete IC Inbox Action with Line Action Accept (manual or auto-accept job queue in the subsidiary) runs CreateJournalLines in the subsidiary company; copied in OnCreateJournalLinesOnBeforeModify. The subsidiary then posts the line on its side. [1]
- **IC Inbox Jnl. Line (subsidiary)** → **Handled IC Inbox Jnl. Line**: standard TransferFields copy. CreateJournalLines fills the handled table with TransferFields. [1] [10]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| ICInboxOutboxMgt | `OnInsertOutboxJnlLineOnBeforeICOutboxJnlLineInsert` | Copy Settlement Ref. from the posted holding-company journal line to the IC Outbox Jnl. Line. | Copy only; no lookups. | [1] |
| ICInboxOutboxMgt | `OnOutboxJnlLineToInboxOnBeforeICInboxJnlLineInsert` | Copy Settlement Ref. from IC Outbox Jnl. Line to IC Inbox Jnl. Line. | May run in the sending (holding) company: copy only, never read the subsidiary's setup or any company data. | [1] [2] |
| ICInboxOutboxMgt | `OnCreateJournalLinesOnBeforeModify` | Copy Settlement Ref. from IC Inbox Jnl. Line to the subsidiary's Gen. Journal Line created on acceptance. | Runs in the partner (subsidiary) company: this is the only subscriber where the subsidiary's setup may be read. | [1] |

## 5. Setup, permissions and lifecycle

- **setup**: In the holding company create a Gen. Journal Template of Type Intercompany and a batch reserved for settlements (with a No. Series), and fill IC Settlement Setup with them and the fee and IC accounts; PostSettlement TestFields every value and the template type before creating lines. [1] [5] [8] [4] [9]
- **setup**: Each subsidiary is an IC Partner of the holding company with a same-database inbox (and the holding company an IC Partner of each subsidiary), with IC G/L account mapping so CreateJournalLines translates the IC account to the subsidiary's own account. [1]
- **permissions**: Ship IC Settlement Objects (non-assignable building block) and the assignable IC Settlement set including it, with explicit object entries and no wildcards. [12] [13]
- **privacy**: Set DataClassification explicitly on Settlement Ref. in all four table extensions (a tableextension has no table-level value) and on every field of IC Settlement Setup; never leave ToBeClassified. [11]
- **other**: Partners with a file (or API) inbox type are out of scope: the IC Outbox Imp/Exp xmlport has a fixed field list, so Settlement Ref. cannot travel in the file. The request names subsidiaries in the same database. [2]

## 6. Tests

1. **post-settlement-creates-outbox-line-with-ref** [1] [14] [15]
    - Given IC Settlement Setup with an Intercompany template and empty reserved batch, an IC partner and accounts created with library codeunits, random amount and unique Settlement Ref.
    - When PostSettlement is called
    - Then An IC Outbox Jnl. Line for the partner exists with the same Settlement Ref. and amount, and the reserved batch is empty.
2. **send-to-partner-copies-ref-to-inbox** [1] [2]
    - Given A posted settlement outbox transaction for a same-database partner
    - When The transaction is sent with Send to IC Partner / Move IC Trans. to Partner Comp
    - Then The partner's IC Inbox Jnl. Line carries the same Settlement Ref.
3. **accept-inbox-creates-journal-line-with-ref** [1]
    - Given An IC inbox transaction carrying a Settlement Ref. in the subsidiary
    - When Complete IC Inbox Action runs with Line Action Accept
    - Then The created Gen. Journal Line and the Handled IC Inbox Jnl. Line carry the same Settlement Ref., and the line posts in the subsidiary.
4. **auto-send-and-auto-accept-carry-ref** [1]
    - Given IC Setup with Auto. Send Transactions and a partner with auto-accept
    - When PostSettlement is called and the auto-accept job queue entry runs
    - Then The subsidiary's Gen. Journal Line carries the same Settlement Ref.
5. **non-intercompany-template-is-rejected** [1] [8]
    - Given IC Settlement Setup pointing to a General-type template
    - When PostSettlement is called
    - Then The TestField on template Type errors and no IC outbox transaction is created.
6. **blank-setup-field-errors** [8] [4]
    - Given IC Settlement Setup with the fee G/L account (and, separately, template, batch, IC account) blanked
    - When PostSettlement is called
    - Then A TestField error names the missing setup field and nothing is posted.
7. **non-empty-batch-is-rejected** [5]
    - Given A manually entered line already in the reserved settlement batch
    - When PostSettlement is called
    - Then An error states the batch must be empty and the manual line is not posted.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Applicability dimensions bc-version, countries and application-area are unknown; all cited articles are [all]/[w1] and apply unconditionally.
- Running sender and partner companies in one automated test (two companies in the same database) is not covered by BCQuality knowledge; the test setup for the send and accept tests rests on judgment.
- IC partner and IC G/L account mapping setup in each company is a prerequisite described from the IC article's mechanism; its configuration steps rest on judgment.
- The IC Settlement Subscribers codeunit split from IC Settlement Post is a structural choice resting on judgment.

## Sources

[1] `microsoft/knowledge/finance-extensions/send-intercompany-journals-through-the-ic-outbox-not-changecompany.md`: Core mechanism: post through an Intercompany template batch, the three journal events, which company each step runs in, and the four tables that need the field.
    - Only Gen. Jnl.-Post Batch on a template of type Intercompany creates the IC outbox transaction; Gen. Jnl.-Post Line or another template type does not.
    - Validate IC Partner Code, IC Account Type and IC Account No.; let the partner accept the inbox transaction by hand, through Complete IC Inbox Action, or by auto-accept.
    - Add the field to Gen. Journal Line, IC Outbox Jnl. Line, IC Inbox Jnl. Line and Handled IC Inbox Jnl. Line with the same field number.
    - Subscribe to OnInsertOutboxJnlLineOnBeforeICOutboxJnlLineInsert, OnOutboxJnlLineToInboxOnBeforeICInboxJnlLineInsert and OnCreateJournalLinesOnBeforeModify.
    - The inbox event may run in the sending company and must only copy; read the partner's setup only in OnCreateJournalLinesOnBeforeModify.
    - Never create the partner's Gen. Journal Line with ChangeCompany.
[2] `microsoft/knowledge/finance-extensions/carry-intercompany-document-fields-to-the-partner-document.md`: Same-database transport of the inbox hop (TransferFields into the partner company), handled IC tables, and the file-partner limit.
    - For a same-database partner, inbox rows are built in the sending company and copied to the partner with TransferFields.
    - A file partner's xmlport IC Outbox Imp/Exp has a fixed field list; a custom field cannot travel in the file.
    - Code in the inbox insert event must work in either company and must not read the partner's setup.
    - Handled IC tables are filled with TransferFields; add the field there if users need the history.
[3] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Field-path map for the Intercompany and Finance rows; one open question per group of stages the request does not name (ledger entries, history tables).
    - A field reaches only the stages the plan names.
    - Whether a field should reach a stage the request does not name is a question for the requester; raise one question per group of stages.
[4] `microsoft/knowledge/feature-design/plan-gl-account-determination-for-a-finance-feature.md`: Account source (feature setup table), checking accounts before posting, and raising the account choice and VAT as open questions.
    - Use a feature setup table for accounts that are one per company or per feature type; never hard-code account numbers.
    - Check every account the feature needs before creating journal lines.
    - Which account a fee belongs to is an accounting decision for the requester; raise an open question rather than choosing.
    - Test with a blanked account to prove the check fires.
[5] `microsoft/knowledge/finance-extensions/post-finance-journal-lines-from-code-in-a-dedicated-batch.md`: Reserved batch named in setup, SetUpNewLine numbering, validated accounts and the transaction boundary decision.
    - Give the feature its own journal template and batch named in its setup table; batch posting posts every line in the batch.
    - Create lines with SetUpNewLine so document numbers come from the batch series; never hard-code document numbers.
    - Validate account fields rather than assigning them.
    - Gen. Jnl.-Post Batch commits unless SetSuppressCommit(true) is called; decide the transaction boundary in the design.
[6] `microsoft/knowledge/finance/preserve-journal-batch-document-balance.md`: Keep each settlement document balanced in the batch; the single line balances against the IC partner.
    - Post persisted journal batches through Gen. Jnl.-Post Batch, not a per-line loop.
    - When the template has Force Doc. Balance, balancing lines must be in the same document/date group.
[7] `microsoft/knowledge/events/changecompany-runs-triggers-in-the-calling-company.md`: Rejects writing the subsidiary's journal line from the holding company; the subsidiary's line is created by code running in the subsidiary.
    - After ChangeCompany, triggers and trigger-event subscribers run in the calling company.
    - Use ChangeCompany to read; run code in the target company or write a hand-off row the target processes itself.
[8] `microsoft/knowledge/data-modeling/testfield-required-setup-field.md`: TestField on every required setup value and the template type before posting, with tests that blank them.
    - Call TestField on a required setup field before use; do not fall through to a default.
    - Write a test that blanks the setup field and asserts the error.
[9] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Shape of IC Settlement Setup and its card page.
    - Primary Key Code[10] as sole key, blank value.
    - Card page with InsertAllowed = false, DeleteAllowed = false and an open-time guard inserting the row.
[10] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Identical definition of Settlement Ref. on every IC journal table linked by TransferFields.
    - Define a mirrored field with the same field number, data type and length on every table in the TransferFields cascade.
[11] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classification of every added field.
    - A tableextension has no table-level classification to inherit; every Normal field it adds must set DataClassification.
    - Do not leave ToBeClassified or use SystemMetadata for data that is customer content.
[12] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Permission set structure.
    - Building blocks are Assignable = false; role-shaped sets include them through IncludedPermissionSets.
[13] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Permission set contents.
    - Enumerate each table and tabledata entry explicitly; no wildcard grants.
    - Grant only the permission letters required.
[14] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Create G/L accounts, partners and other prerequisites with the test Library codeunits and random values, parents before dependents.
[15] `microsoft/knowledge/testing/transactionmodel-attribute-governs-test-transactions.md`: Transaction model for tests that run Gen. Jnl.-Post Batch, which commits.
    - Do not declare AutoRollback on tests whose code under test commits; use AutoCommit with a TestIsolation-enabled runner.
[16] `microsoft/knowledge/finance/normal-vat-journal-amount-includes-vat.md`: Open question on whether the management fee carries VAT.
    - With Automatic VAT Entry and Normal VAT, journal Amount includes VAT; supply the VAT-inclusive total.
    - Establish the account and posting-group combination before validating the amount.
[17] `microsoft/knowledge/finance-extensions/carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md`: Open question on whether Settlement Ref. must reach G/L entries in either company.
    - A custom Gen. Journal Line field reaches no G/L, VAT or bank entry unless copied in that table's copy event.
    - Decide per entry; do not store a field on a ledger entry only because it exists on the journal line.
    - A code copied to an entry stays unchanged on reversal.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

