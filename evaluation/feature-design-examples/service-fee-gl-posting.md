# Feature design

> Our service contracts charge a monthly handling fee. When a user runs Post Fees, each fee must be posted to the general ledger, and the G/L entries must carry the contract number so finance can analyze fees per contract. Posted fees must be reversible.

**Result:** Complete design. **Business process:** General journal posting from feature code (Gen. Journal Line in a reserved batch, Gen. Jnl.-Post Batch creating G/L entries) and G/L transaction reversal. **Knowledge used:** 22 BCQuality articles.

**Why:** Design covers journal-line creation in a reserved batch, the Contract No. copy to G/L entries, and standard reversal; the fee source record and the Post Fees host page are open questions.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Are the service contracts the standard Service Management Service Contract Header, or a table in your own app? This fixes the Contract No. type and length and the table relation. _(affects: gen-journal-line-ext, gl-entry-ext)_
2. Where is the monthly handling fee stored (amount per contract, a fee line per month, or a fee table), and which records does Post Fees select (all unposted fees up to a date, one contract, a filter the user enters)? _(affects: service-fee-post, post-fee-carries-contract-no)_
3. Which page hosts the Post Fees action (contract card, contract list, a fee list or a report request page)? _(affects: service-fee-post)_
4. How is a fee marked as posted so a second Post Fees run does not post it again, and must that mark roll back with a failed posting (which decides SetSuppressCommit(true))? After reversal, may the fee be posted again? _(affects: service-fee-post, reverse-fee-keeps-contract-and-nets-zero)_
5. Which G/L account does the fee post to: one account per company in Service Fee Setup, or an account resolved from posting groups (for example by customer or contract group)? _(affects: service-fee-setup, service-fee-post)_
6. What is the other side of the fee posting: another G/L account (accrual or clearing), or the customer of the contract (a customer ledger entry, which needs unapplication before reversal if it was applied)? _(affects: service-fee-setup, service-fee-post, reverse-fee-keeps-contract-and-nets-zero)_
7. Does the handling fee carry VAT? If yes, is the fee amount VAT-inclusive or net, and which VAT posting groups apply? _(affects: service-fee-post, post-fee-carries-contract-no)_
8. Should the fee G/L entries carry the contract's dimensions (if the contract record has a dimension set) or none? _(affects: service-fee-post, dimensions-carried-to-gl)_
9. How will finance analyze fees per contract: filtering the General Ledger Entries list by a Contract No. column, a report, or a query/API? A list column needs the stored field; otherwise a related table keyed by G/L Entry No. is preferred. _(affects: gl-entry-ext, general-ledger-entries-ext)_
10. Does the app create the reserved journal template and batch, or does the customer create them and enter them in setup? Which number series should the batch use? _(affects: service-fee-setup)_
11. Which posting date and description should each fee use (run date, end of the fee month), and should several fees of one run share one document number or have one each? _(affects: service-fee-post, two-contracts-separate-documents)_
12. Should Service Fee - Post include standard general-journal posting rights, or are fee posters already assigned a finance role that grants them? _(affects: service-fee-post-permissions, post-fees-with-role-permissions)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | table | Service Fee Setup | Singleton setup that names the journal template and batch reserved for fee posting and the G/L accounts the fee posts to, so no account or batch is hard-coded. Which accounts live here depends on open question account-source. | Primary Key (Code[10]): Sole key; the single row keeps a blank value.; Journal Template Name (Code[10]): TableRelation to Gen. Journal Template. Checked with TestField before any journal line is created.; Journal Batch Name (Code[10]): TableRelation to Gen. Journal Batch of the template. A batch reserved for fees only. Checked with TestField.; Fee G/L Account No. (Code[20]): TableRelation to G/L Account. Only if the answer to account-source is one account per company; checked with TestField.; Balancing Account No. (Code[20]): Type and table relation depend on open question balancing-side (G/L account or another account type). Checked with TestField. | [1] [2] [3] [4] [15] [16] |
| 2 | create | page | Service Fee Setup | Card page over Service Fee Setup with InsertAllowed = false and DeleteAllowed = false; OnOpenPage inserts the blank row when it is missing. Reads and writes only its own setup record. |  | [2] [17] [18] |
| 3 | extend | tableextension | Gen. Journal Line | Hold the contract number on each fee journal line so the posting engine can pass it to the G/L entry through the copy event. | Contract No. (Code[20] (confirm it matches the contract number field of the contract table; see open question contract-source)): Explicit DataClassification on the field, because a tableextension inherits no table-level value; CustomerContent is the likely value, to be confirmed. Never ToBeClassified. | [7] [15] [16] |
| 4 | extend | tableextension | G/L Entry | Stored Contract No. on the G/L entry so finance can filter and analyze fee entries per contract. A stored field on a hot ledger is chosen because the request requires the G/L entries themselves to carry the value; the performance article allows this only when the value must appear as a native list column and is read on almost every access, otherwise a related table keyed by Entry No. is preferred (applies from BC23). Confirm with open question analysis-surface. | Contract No. (Same type and length as Gen. Journal Line "Contract No."): Explicit DataClassification (tableextension). A reference value: reversal copies it unchanged to the reversing entry, which is the intended behavior. Add no custom amount field without a reversal subscriber. | [7] [11] [15] [16] |
| 5 | extend | pageextension | General Ledger Entries | Show Contract No. as a list column so finance can filter and analyze fee entries per contract. Depends on open question analysis-surface. |  | [11] [18] |
| 6 | create | codeunit | Service Fee-Post | The Post Fees operation. Reads Service Fee Setup and TestFields every value it needs; errors when the reserved batch is not empty; creates one balanced journal document per fee with SetUpNewLine (document numbers from the batch series), validates account fields, amount and Dimension Set ID, sets Contract No., then posts through Gen. Jnl.-Post Batch. Owns the transaction boundary: calls SetSuppressCommit(true) when the posting must roll back together with the feature's own writes (see open question double-posting). The page action that starts Post Fees only calls this codeunit. |  | [1] [4] [5] [6] [3] [10] [12] [17] |
| 7 | create | codeunit | Service Fee G/L Subscribers | Event subscriber that copies Contract No. from Gen. Journal Line to G/L Entry when the posting engine creates the entry. |  | [7] |
| 8 | create | permissionset | Service Fee - Objects | Building block, Assignable = false: explicit entries for Service Fee Setup tabledata, the setup page, Service Fee-Post and the subscriber codeunit. No wildcard grants; only the letters each object needs. |  | [13] [14] |
| 9 | create | permissionset | Service Fee - Post | Role-shaped, Assignable = true set for users who run Post Fees, composed through IncludedPermissionSets from the building block. Whether it also includes the standard journal-posting rights or relies on a separately assigned finance role is open question permissions-scope. |  | [13] [14] |

## 3. How the data flows

- **User runs Post Fees (page action; host page to be confirmed)** → **Service Fee-Post codeunit**: entered by the user. The action only calls the codeunit; no posting logic in the page. [17]
- **Service fee source (contract and monthly fee amount; record to be confirmed)** → **Gen. Journal Line in the reserved fee batch**: field validation. Service Fee-Post validates Account Type/No., Bal. Account Type/No. and Amount so posting groups, VAT and default dimensions are filled; assigns Contract No.; one balanced document per fee by date and document number. [4] [6] [12]
- **Service fee source dimension set (if it has one)** → **Gen. Journal Line "Dimension Set ID"**: field validation. Validate("Dimension Set ID", source set ID) so the shortcut dimensions are synchronized; never copy only shortcut codes. Applies only if the fee source carries dimensions (open question dimensions). [10] [1]
- **Gen. Journal Line "Contract No."** → **G/L Entry "Contract No."**: copied in an event subscriber. Gen. Jnl.-Post Line initializes each G/L entry with CopyFromGenJnlLine, which raises OnAfterCopyGLEntryFromGenJnlLine. VAT and bank entries are not extended; the request asks only for G/L entries. [7] [5]
- **Original fee G/L Entry** → **Reversing G/L Entry**: other. Standard reversal (Reversal Entry.ReverseTransaction with the G/L entry's Transaction No.) builds the reversing entry by assigning the original record, so Contract No. is copied unchanged. As a reference value it must stay as copied; no reversal subscriber is needed. The reversal pair nets to zero per contract. [7] [8] [9]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "G/L Entry" | `OnAfterCopyGLEntryFromGenJnlLine` | Copy Contract No. from the journal line to the G/L entry being created. | Plain field assignment only; no database call and no Modify of the entry. | [7] |

## 5. Setup, permissions and lifecycle

- **setup**: An administrator opens Service Fee Setup (the page inserts the blank row on first open), names a journal template and a batch reserved for fees, and fills the accounts. Whether the app creates the template and batch or the customer does is open question batch-provisioning; account numbers are never hard-coded in an install codeunit. [2] [4] [1]
- **setup**: Service Fee-Post calls TestField on Journal Template Name, Journal Batch Name and every account it uses before creating any journal line, including any account returned by a posting setup getter. [3] [1]
- **permissions**: Ship Service Fee - Objects (Assignable = false) and Service Fee - Post (Assignable = true, IncludedPermissionSets), with explicit entries and no wildcards. [13] [14]
- **privacy**: Give Service Fee Setup a table-level DataClassification; give each Contract No. field on Gen. Journal Line and G/L Entry its own explicit DataClassification, because table extensions inherit nothing. No ToBeClassified ships. [15] [16]

## 6. Tests

1. **post-fee-carries-contract-no** [7] [19] [20]
    - Given Service Fee Setup with a reserved empty template and batch and fee/balancing accounts created with LibraryERM, and a fee for contract C with a random amount
    - When Post Fees runs
    - Then The G/L entries of the fee document carry Contract No. = C, the fee account entry has the fee amount, and the reserved batch is empty
2. **two-contracts-separate-documents** [6] [7] [19]
    - Given Fees for two different contracts C1 and C2
    - When Post Fees runs
    - Then Each contract's G/L entries form their own balanced document and carry their own contract number; filtering G/L entries by Contract No. returns only that contract's fee
3. **reverse-fee-keeps-contract-and-nets-zero** [8] [7] [9] [1]
    - Given A posted fee for contract C
    - When The fee is reversed through Reversal Entry.ReverseTransaction with the Transaction No. of one of its G/L entries
    - Then The reversing G/L entries carry Contract No. = C, the original entries are marked reversed, and the sum of G/L Amount for contract C on the fee account is zero
4. **blank-setup-field-blocks-posting** [3] [21] [1]
    - Given Service Fee Setup with one required field blanked (Journal Template Name, Journal Batch Name, fee account or balancing account; one test per field)
    - When Post Fees runs under asserterror
    - Then Assert.ExpectedTestFieldError names the blanked field, and no G/L entry was posted
5. **non-empty-batch-blocks-posting** [4] [21]
    - Given A line a user entered in the reserved fee batch
    - When Post Fees runs under asserterror
    - Then Assert.ExpectedError with the full batch-not-empty label text built with StrSubstNo, the user's line is still unposted, and no fee G/L entry exists
6. **dimensions-carried-to-gl** [10] [19]
    - Given A fee whose source carries a dimension set with a dimension outside the shortcut dimensions
    - When Post Fees runs
    - Then The fee G/L entries have the source's Dimension Set ID, including the non-shortcut dimension
7. **post-fees-with-role-permissions** [22] [13]
    - Given TestPermissions Restrictive and the test user lowered to Service Fee - Post plus the journal-posting rights decided in permissions-scope
    - When Post Fees runs
    - Then Posting succeeds; without Service Fee - Post the same run fails with the expected permission error

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined; no repository was supplied.
- prefer-related-table-over-extension-on-hot-ledgers applies from BC23; the stored-field choice on G/L Entry rests on the request and open question analysis-surface.
- The fee source record and the Post Fees host page are not designed because the request does not say where fees are stored; see fee-source and post-fees-entry-point.
- Preventing a fee from being posted twice is not covered by BCQuality knowledge; see double-posting.

## Sources

[1] `microsoft/knowledge/feature-design/plan-gl-account-determination-for-a-finance-feature.md`: The decision list for the finance feature: account source, missing-account check, how to post, balance, dimensions, VAT, custom values on entries, corrections and tests.
    - Do not hard-code account numbers in code or an install codeunit; read accounts from posting groups or a feature setup table.
    - Check every account the feature needs before creating journal lines, including a posting setup getter's value, which can be blank.
    - Create journal lines in a batch reserved for the feature and post through the posting engine.
    - Which account a fee belongs to is the requester's accounting decision; raise an open question rather than choosing.
    - Test with a blanked account to prove the check fires, and post then reverse to prove the entries net to zero.
[2] `microsoft/knowledge/data-modeling/setup-table-is-a-singleton.md`: Shape of Service Fee Setup and its card page.
    - Primary Key Code[10] is the sole key; one blank-keyed row per company.
    - Card page with InsertAllowed = false and DeleteAllowed = false and an open-time guard that inserts the missing row.
    - No Integer/AutoIncrement key and no List page over the setup table.
[3] `microsoft/knowledge/data-modeling/testfield-required-setup-field.md`: Guarding every setup value Post Fees depends on, and the test that blanks it.
    - Call TestField on a required setup field before use; never fall through to a default when it is blank.
    - Write a test that blanks the setup field and asserts the resulting error.
[4] `microsoft/knowledge/finance-extensions/post-finance-journal-lines-from-code-in-a-dedicated-batch.md`: How Service Fee-Post creates and posts journal lines.
    - Use the feature's own journal template and batch, named in setup, so batch posting only reaches the feature's lines.
    - Gen. Jnl.-Post Batch posts every line in the batch matching the record's filters, including lines users entered.
    - Create lines with SetUpNewLine so document numbers come from the batch series; hard-coded numbers fail unless the series allows manual numbers.
    - Validate account fields rather than assigning them.
    - Batch posting commits unless SetSuppressCommit(true) was called; decide the transaction boundary in the design.
[5] `microsoft/knowledge/finance/post-ledger-entries-through-posting-codeunits.md`: Posting fees only through the posting engine.
    - Never insert G/L Entry or register records directly; Insert(true) does not invoke the posting engine.
    - Use Gen. Jnl.-Post Batch for a persisted journal batch; normal batch posting owns numbering and commits by default.
[6] `microsoft/knowledge/finance/preserve-journal-batch-document-balance.md`: Keeping each fee document balanced in the reserved batch.
    - Post the batch through its batch workflow, not a loop over Gen. Jnl.-Post Line.RunWithCheck.
    - Keep balancing lines in the same document/date group when the template's Force Doc. Balance requires it.
[7] `microsoft/knowledge/finance-extensions/carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md`: Copying Contract No. to G/L entries and deciding reversal behavior.
    - Add the field to Gen. Journal Line and to each entry table that needs it, and subscribe to that table's copy event (OnAfterCopyGLEntryFromGenJnlLine on G/L Entry).
    - Do not add the field to VAT or bank entries only because it exists on the journal line.
    - Reversal copies custom fields unchanged; a reference may stay as copied, a custom amount or quantity must be negated in the reversal events such as OnReverseGLEntryOnBeforeInsertGLEntry.
    - Add a test that reverses a posted transaction and checks the custom values.
    - Do not patch entries after posting.
[8] `microsoft/knowledge/finance/reverse-transactions-by-transaction-number.md`: How a posted fee is reversed and how the reversal test starts it.
    - Pass the G/L entry's Transaction No. to Reversal Entry.ReverseTransaction, never its Entry No.; ReverseRegister takes a G/L register number.
    - Let the reversal workflow validate eligibility; do not bypass a rejection by changing origin, application or reversal fields. Reversal is not guaranteed for every posting.
[9] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Making reversal the only correction path for posted fees.
    - Correct posted fees through supported reversal or a correcting posting, never by changing amounts or deleting entries.
    - Do not set Reversed or negate a single row yourself.
[10] `microsoft/knowledge/finance/write-dimensions-as-dimension-set-entries.md`: Passing the fee source's dimensions to the journal line.
    - Copy the complete Dimension Set ID and synchronize projections with Validate("Dimension Set ID") on Gen. Journal Line.
    - Do not copy only global or shortcut dimension codes.
[11] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choosing between a stored Contract No. on G/L Entry and a related table. Applies from BC23; bc-version unknown.
    - Put optional, sparse or integration attributes in a related table keyed by the ledger Entry No., shown through a FactBox or FlowField.
    - Use a stored tableextension field only when the value must appear as a native list column and is read on almost every access.
[12] `microsoft/knowledge/finance/normal-vat-journal-amount-includes-vat.md`: The VAT decision for the fee journal line, conditional on open question vat.
    - With Automatic VAT Entry and Normal VAT, journal Amount includes VAT; posting extracts tax and does not add it.
    - Establish the account and posting-group combination before validating the final amount; account-derived VAT defaults depend on Copy VAT Setup to Jnl. Lines.
[13] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Structure of the feature's permission sets.
    - Building blocks marked Assignable = false; role-shaped Assignable = true sets reference them through IncludedPermissionSets.
[14] `microsoft/knowledge/security/permission-set-avoid-wildcard-grants.md`: Content of the permission sets.
    - Enumerate each tabledata and object explicitly; no * grants.
    - Grant only the letters required (R, RIM, RIMD as the role needs).
[15] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of the new table and the extension fields.
    - A table-level DataClassification is the default for the table's own Normal fields.
    - A tableextension inherits nothing; every Normal field it adds needs an explicit DataClassification.
[16] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release readiness of every new field.
    - No field ships with DataClassification = ToBeClassified.
[17] `microsoft/knowledge/style/pages-must-not-contain-business-logic.md`: Keeping Post Fees logic out of the page action.
    - The page owns presentation; the business operation lives in a codeunit the action calls.
    - A setup page reading and writing its own singleton record is conventional.
[18] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips on the setup page fields and the Contract No. column.
    - On runtime 13.0 or later define the tooltip on the table field and let bound page fields inherit it; before that, add page-level tooltips.
    - Tooltips say what the value is used for, not only its name.
[19] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for G/L accounts, journal template/batch and amounts in tests.
    - Create prerequisite records with Library codeunits (for example LibraryERM.CreateGLAccount, LibraryRandom) instead of Init/Insert with invented keys.
    - Create parents before dependent records and Validate foreign keys.
[20] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit.
    - [FEATURE] once per codeunit; [SCENARIO] first in each test body; [GIVEN]/[WHEN]/[THEN] marking setup, action and assertions.
[21] `microsoft/knowledge/testing/asserterror-needs-expectederror-and-code.md`: Negative tests for blank setup and a non-empty batch.
    - Follow every asserterror with a check of the specific error; use Assert.ExpectedTestFieldError for TestField failures.
    - For other errors, use Assert.ExpectedError with the full label text built with StrSubstNo; an error code alone is not enough.
[22] `microsoft/knowledge/testing/permission-tests-must-lower-the-execution-context.md`: The permission test for Post Fees.
    - Use TestPermissions Restrictive and lower the test user with Permissions Mock or Library - Lower Permissions before the protected operation.
    - A role that includes the permission set under test is an adequate context.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
