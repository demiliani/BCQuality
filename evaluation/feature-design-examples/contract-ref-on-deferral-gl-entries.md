# Feature design

> We defer subscription revenue on sales invoices with deferral templates. Finance wants every G/L entry of the invoice, including each monthly deferral release, to carry the Contract No. from the sales header and a Recognition Month (YYYY-MM) showing the month the amount is recognised. Some contracts need their own number of months, so sales lines created by our contract import must get a schedule with the contract's period count.

**Result:** Complete design. **Business process:** Carry a sales header Contract No. and a per-period Recognition Month to every G/L entry of a sales invoice, including deferral releases posted by Gen. Jnl.-Post Line, and give contract-imported sales lines a deferral schedule with the contract's period count (sales posting, invoice posting buffer, deferrals). **Knowledge used:** 12 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Does the contract import app already define Contract No. on Sales Header (with which field number, type and length)? If so, the new tables must mirror that definition and the Sales Header extension is dropped. _(affects: sales-header-contract-no, posted-sales-headers-contract-no, invoice-posting-buffer-contract-no, gen-journal-line-contract-no, gl-entry-contract-fields)_
2. Should Contract No. also be mirrored on the posted shipment, credit memo, return receipt and archive tables (designed by default), or only on the posted invoice? _(affects: posted-sales-headers-contract-no)_
3. Should Contract No. also be stored on Cust. Ledger Entry (the journal line already carries it)? _(affects: gen-journal-line-contract-no)_
4. Must Contract No. and Recognition Month appear as native filterable columns on General Ledger Entries (stored fields, designed), or is a related table keyed by Entry No. acceptable to avoid the G/L Entry extension cost? _(affects: gl-entry-contract-fields, gl-entries-page-ext)_
5. Which Recognition Month should non-deferred entries carry (receivables, VAT, non-deferred revenue, and the initial transfer to the deferral account)? Designed: the month of the entry's posting date. _(affects: gl-entry-contract-fields, contract-gl-posting-codeunit)_
6. Do credit memos with deferrals and general journal deferrals also need Contract No. and Recognition Month? General journals use their own events (OnPostDeferralOnBeforeInsertGLEntryDeferralLineForGLAccount / ...ForDeferralAccount), not designed now. _(affects: contract-gl-posting-codeunit)_
7. Where does the import read the contract's period count, start date and calculation method (straight-line assumed), and which object performs the import? _(affects: contract-import-modify, contract-deferral-schedule-codeunit, sales-line-contract-periods)_
8. Must already-posted invoices get Contract No. and Recognition Month? Only through a supported mechanism; otherwise history stays blank. _(affects: gl-entry-contract-fields)_
9. Are invoices posted with a payment method that has a balancing account, creating an extra payment journal line whose G/L entries must also carry Contract No.? _(affects: contract-gl-posting-codeunit)_
10. Is this the base-application deferral feature only, or are some invoices created by the Subscription Billing app? _(affects: contract-gl-posting-codeunit)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Sales Header | Holds the Contract No. that every G/L entry of the invoice must carry. Needed only if the contract import app does not already define it (see open question). | Contract No. (Code[20]): Same field number, type and length on every table that carries it. | [4] [7] [8] [12] |
| 2 | extend | tableextension | Sales Invoice Header | Mirror of Contract No. so TransferFields carries it to the posted invoice. The same mirror is needed on Sales Cr.Memo Header, Sales Shipment Header, Return Receipt Header and Sales Header Archive (one tableextension each, same field number), non-editable on posted tables. | Contract No. (Code[20]): Same field number, type and length on every table that carries it. | [7] [8] |
| 3 | extend | tableextension | Sales Line | Stores the contract's period count set by the contract import, so the schedule can be checked before posting. | Contract No. of Periods (Integer): 0 = use the deferral template's period count. Local to Sales Line; not mirrored. | [2] [10] |
| 4 | extend | tableextension | Invoice Posting Buffer | Carries Contract No. from the sales line posting to the G/L journal line of each buffer group. Not added to Group ID because the value is the same for every line of one invoice. | Contract No. (Code[20]): Same field number, type and length on every table that carries it. | [3] [2] |
| 5 | extend | tableextension | Gen. Journal Line | Carries Contract No. to G/L entries, including the deferral entries Gen. Jnl.-Post Line builds from the same journal line. | Contract No. (Code[20]): Same field number, type and length on every table that carries it. | [3] [5] [2] |
| 6 | extend | tableextension | G/L Entry | Stores Contract No. and Recognition Month on every G/L entry, filled during posting. Stored fields are chosen because Finance needs them on every entry; the related-table alternative is an open question. | Contract No. (Code[20]): Editable = false.; Recognition Month (Code[7]): Format YYYY-MM. Editable = false. | [3] [2] [6] [12] |
| 7 | create | codeunit | Contract G/L Posting | Event subscribers that carry Contract No. through the invoice posting buffer and the customer journal line to the G/L entries, and set Recognition Month on each deferral entry. |  | [3] [5] [2] [9] |
| 8 | create | codeunit | Contract Deferral Schedule | SetContractSchedule(SalesLine, DeferralCode, StartDate, NoOfPeriods): validates Deferral Code, then calls Deferral Utilities.CreateDeferralSchedule with the line's GetDeferralAmount() and the contract's period count; plus the pre-posting check of the schedule. |  | [2] [10] |
| 9 | modify | codeunit | Contract Import | The caller's existing contract import calls SetContractSchedule for each sales line it creates, after the line's amounts are set, and fills Contract No. of Periods. Object name to be confirmed. |  | [2] |
| 10 | extend | pageextension | General Ledger Entries | Shows Contract No. and Recognition Month so Finance can see and filter them. |  | [4] |
| 11 | extend | pageextension | Sales Invoice | Shows Contract No. on the invoice, and Contract No. of Periods on the invoice subform lines (Sales Invoice Subform), if not already shown by the contract app. |  | [4] |
| 12 | create | permissionset | Contract Deferral | Execute permission on the two new codeunits for users who post sales invoices and run the contract import. |  | [4] |

## 3. How the data flows

- **Contract import** → **Sales Header.Contract No.**: other. Existing import sets the header value (to be confirmed). agent judgment
- **Contract import** → **Sales Line deferral schedule (Deferral Header / Deferral Line)**: field validation. Validate Deferral Code, then DeferralUtilities.CreateDeferralSchedule with the contract's No. of Periods; amounts changed later only through Validate so UpdateDeferralAmounts keeps the period count. [2]
- **Sales Header** → **Sales Invoice Header, Sales Cr.Memo Header, Sales Shipment Header, Return Receipt Header, Sales Header Archive**: standard TransferFields copy. Standard TransferFields by field number; no subscriber. [7] [8]
- **Sales Header (via Sales Line)** → **Invoice Posting Buffer**: copied in an event subscriber. OnPrepareLineOnAfterFillInvoicePostingBuffer on Sales Post Invoice Events; the confirmed parameters give the Sales Line, so the header's Contract No. is read from the line's document (judgment, see unresolved). [3]
- **Invoice Posting Buffer** → **Gen. Journal Line**: copied in an event subscriber. OnAfterCopyToGenJnlLine on Invoice Posting Buffer (revenue, deferral-source and other line-based G/L lines). [3]
- **Sales Header** → **Gen. Journal Line (customer/receivables line)**: copied in an event subscriber. OnAfterCopyGenJnlLineFromSalesHeader on Gen. Journal Line. [5]
- **Gen. Journal Line** → **G/L Entry (main and every deferral entry)**: copied in an event subscriber. OnAfterCopyGLEntryFromGenJnlLine copies Contract No. only; it also runs for every deferral entry built from the journal line. It does not read the entry's account, amount or posting date. [2] [3] [5]
- **Deferral posting (period posting date)** → **G/L Entry.Recognition Month**: copied in an event subscriber. Set from the period posting date in OnPostDeferralPostBufferOnBeforeInsertGLEntryForGLAccount and ...ForDeferralAccount, raised after the period posting date is set. [2]
- **Gen. Journal Line.Posting Date** → **G/L Entry.Recognition Month (non-deferred entries)**: copied in an event subscriber. Default for entries that are not deferral releases: month of the journal line posting date, set in OnAfterCopyGLEntryFromGenJnlLine; overwritten by the deferral events for deferral entries. Proposed value pending the open question. agent judgment

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Sales Post Invoice Events | `OnPrepareLineOnAfterFillInvoicePostingBuffer` | Copy the invoice's Contract No. into the Invoice Posting Buffer. | Subscribe on Sales Post Invoice Events, not Sales Post Invoice. · Contract No. not added to Group ID: constant per invoice. | [3] |
| Invoice Posting Buffer | `OnAfterCopyToGenJnlLine` | Copy Contract No. from the buffer to the Gen. Journal Line. |  | [3] |
| Gen. Journal Line | `OnAfterCopyGenJnlLineFromSalesHeader` | Copy Contract No. from the sales header to the customer journal line so the receivables G/L entry carries it. |  | [5] |
| G/L Entry | `OnAfterCopyGLEntryFromGenJnlLine` | Copy Contract No. to every G/L entry built from the journal line, deferral entries included; set the default Recognition Month for non-deferred entries from the journal line posting date. | Do not read GLEntry G/L Account No., Amount or Posting Date here: they are not final. · Fill during posting; never find and modify G/L entries after posting. | [2] [3] [9] |
| Gen. Jnl.-Post Line | `OnPostDeferralPostBufferOnBeforeInsertGLEntryForGLAccount` | Set Recognition Month (YYYY-MM) from the period posting date on the G/L account side of each sales deferral entry. |  | [2] |
| Gen. Jnl.-Post Line | `OnPostDeferralPostBufferOnBeforeInsertGLEntryForDeferralAccount` | Set Recognition Month on the deferral account side, so reports that read the deferral account see it too. |  | [2] |
| Sales-Post | `OnAfterCheckSalesDoc` | Stop posting (preview included) when a line with Contract No. of Periods > 0 has a deferral schedule whose No. of Periods differs, e.g. after a header Posting Date change re-validated Deferral Code with the template's period count. | Raise an actionable error naming the line and telling the user to re-apply the contract schedule. | [10] [2] |

## 5. Setup, permissions and lifecycle

- **privacy**: Classify Contract No. as CustomerContent on every table that holds it; Recognition Month as CustomerContent on G/L Entry; Contract No. of Periods as CustomerContent. [12]
- **permissions**: Ship permission set Contract Deferral with execute on Contract G/L Posting and Contract Deferral Schedule. [4]
- **upgrade**: No back-fill: G/L entries posted before installation keep blank Contract No. and Recognition Month unless the open question decides otherwise. Posted entries are never modified to fill them. [9]

## 6. Tests

1. **deferral-entries-carry-contract-and-month** [2] [3] [11]
    - Given Customer, G/L accounts and a 3-period straight-line deferral template created with Library codeunits; sales invoice with Contract No. and one line using the template.
    - When The invoice is posted.
    - Then Every G/L entry with the posted Document No. (revenue, receivables, VAT, deferral transfer and each release) has the Contract No.; each deferral release entry, on both the G/L account and deferral account side, has Recognition Month equal to the YYYY-MM of its own posting date, and the three months differ.
2. **receivables-entry-carries-contract-no** [5] [3] [11]
    - Given Sales invoice with Contract No. and no deferral.
    - When The invoice is posted.
    - Then The receivables G/L entry and the revenue G/L entry carry Contract No.; Recognition Month equals the posting month.
3. **multi-line-invoice-keeps-contract-no** [3] [11]
    - Given Sales invoice with Contract No. and two lines on different G/L accounts, one deferred and one not.
    - When The invoice is posted.
    - Then All G/L entries of both buffer groups carry the same Contract No.
4. **posted-header-mirror** [7] [11]
    - Given Sales invoice with Contract No.
    - When The invoice is posted, and separately the document is archived.
    - Then Sales Invoice Header and Sales Header Archive carry the Contract No.
5. **contract-schedule-period-count** [2] [11]
    - Given Deferral template with 12 periods; sales line created by the contract import procedure with a contract period count of 5.
    - When SetContractSchedule runs, then Quantity is validated to a new value.
    - Then Deferral Header No. of Periods is 5 after both steps, and the Deferral Line total equals the new Amount to Defer.
6. **contract-schedule-posts-five-releases** [2] [11]
    - Given Sales invoice line with a contract schedule of 5 periods.
    - When The invoice is posted.
    - Then Five deferral release pairs are posted, each with Contract No. and its own Recognition Month.
7. **posting-date-change-blocked** [10] [2] [11]
    - Given Sales line with Contract No. of Periods = 5 and a contract schedule; header Posting Date then changed so Deferral Code is re-validated with the template's 12 periods.
    - When Posting preview and posting are run.
    - Then Both stop with the schedule-mismatch error and no G/L entries exist; after re-running SetContractSchedule posting succeeds.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Reading the header's Contract No. inside OnPrepareLineOnAfterFillInvoicePostingBuffer: the opened article confirms only the Sales Line parameter, so obtaining the header value (Get of the Sales Header per line, or a field copied to the lines) rests on judgment.
- Default Recognition Month for non-deferred G/L entries (month of the journal line posting date) rests on judgment; no article states it.
- Contract import changes and the Sales Header Contract No. source rest on judgment: no repository was supplied.
- No opened article names an event to re-apply the contract schedule after a header Posting Date change; the design blocks posting instead (judgment).
- Not covered: balancing-account (payment method) journal lines; no opened article confirms their copy event.
- bc-version, countries and application-area are unknown (no repository).

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Process map: chose the Sales and Finance (deferrals) rows and the cross-cutting rows (mirroring, posted entries, upgrade, privacy, tests).
    - A field reaches only the stages the plan names; plan one row group per process.
    - Fill posted entries during posting, never by modifying them afterwards.
    - Whether a field reaches stages the request does not name is a question for the requester, one per group.
[2] `microsoft/knowledge/finance-extensions/carry-fields-to-deferral-gl-entries-and-maintain-deferral-schedules.md`: Deferral G/L entries, Recognition Month events, and the contract-specific deferral schedule.
    - Carry a document-level value to the Gen. Journal Line and copy it in OnAfterCopyGLEntryFromGenJnlLine; do not read the entry's account, amount or posting date there.
    - Set a period-dependent value in the deferral insert events, on both sides if reports read the deferral account.
    - Create a schedule from code by validating Deferral Code, then calling DeferralUtilities.CreateDeferralSchedule with GetDeferralAmount(); never insert or modify Deferral Line rows directly.
    - Change amounts only through Validate so UpdateDeferralAmounts keeps the method, period count and start date.
    - A header Posting Date change re-validates Deferral Code on every line with the template's period count; posting fails when the schedule total differs from Amount to Defer.
[3] `microsoft/knowledge/sales-purchase/carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.md`: Carrying Contract No. from sales line posting through the Invoice Posting Buffer to the G/L journal line and G/L Entry.
    - Add the field to Invoice Posting Buffer, Gen. Journal Line and G/L Entry.
    - Subscribe to OnPrepareLineOnAfterFillInvoicePostingBuffer on Sales Post Invoice Events, not Sales Post Invoice.
    - Add the field to Group ID only when lines with different values must post separately.
    - Copy with OnAfterCopyToGenJnlLine and OnAfterCopyGLEntryFromGenJnlLine.
[4] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stages of a custom sales header field, page extensions and permission entries in the plan.
    - Decide which stages the field must reach and plan one step per stage.
    - Name the page extensions that show the field, permission set entries for new objects, and a test that posts and reads the value back from every target.
    - Do not fill ledger entries after posting by finding and modifying them.
[5] `microsoft/knowledge/sales-purchase/carry-sales-fields-to-customer-ledger-through-the-journal-line.md`: Carrying Contract No. to the customer journal line so the receivables G/L entry carries it.
    - Copy from Sales Header to Gen. Journal Line in OnAfterCopyGenJnlLineFromSalesHeader.
    - The journal-line field reaches G/L entries through OnAfterCopyGLEntryFromGenJnlLine.
    - Do not modify posted entries in OnAfterPostSalesDoc.
[6] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choice between stored G/L Entry fields and a related table.
    - Use a stored tableextension field on G/L Entry only when the value must appear as a native list column and is read on almost every access.
    - Otherwise put the attribute in a related table keyed by Entry No.
[7] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring Contract No. on posted sales headers and the archive.
    - Same field number, name, type and length on Sales Header and on every posted header and archive table the plan needs.
    - No subscriber is needed for these stages; keep mirrored fields non-editable on posted tables.
[8] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definitions across the TransferFields cascade.
    - Define mirrored fields with the exact same number, data type and length on every table in the cascade.
[9] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Guard against filling G/L entries after posting.
    - Do not persist changes to posted financial entries outside supported posting or correction workflows.
[10] `microsoft/knowledge/sales-purchase/validate-sales-and-purchase-documents-before-posting-or-release.md`: Pre-posting check of the contract schedule.
    - A rule that must stop every posting, including preview, goes in OnAfterCheckSalesDoc.
    - Do not check in the page action or after posting.
[11] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build customers, items, G/L accounts and sales documents with Library codeunits and validate foreign keys; no hand-rolled Init/Insert.
[12] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of the new fields.
    - Set DataClassification matching the data stored on every new table field.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

