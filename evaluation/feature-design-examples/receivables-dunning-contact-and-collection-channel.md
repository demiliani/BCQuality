# Feature design

> Customers get a Dunning Contact Code that must default onto reminders and finance charge memos, both when a user creates them and when they are created by the Create Reminders and Create Finance Charge Memos batch jobs. Separately, cash receipt journal lines get a Collection Channel. It must appear on the customer ledger entry and on the detailed customer ledger entries, including application entries when a payment is applied later from Customer Ledger Entries.

**Result:** Complete design. **Business process:** Receivables: reminder and finance charge memo creation (manual, Create Reminders, Create Finance Charge Memos) and cash receipt journal posting with later application of customer ledger entries. **Knowledge used:** 15 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What does Dunning Contact Code refer to: a Contact No., a contact person of the customer, or a new code table? This sets its TableRelation, type and length, and whether a new table, page and permissions are needed. _(affects: customer-ext, reminder-header-ext, fin-charge-memo-header-ext, customer-card-ext, feature-permissionset)_
2. What are the allowed Collection Channel values: a new setup/code table, an enum, or free code? This sets type, length and TableRelation on all three tables and whether a new table and page are needed. _(affects: gen-journal-line-ext, cust-ledger-entry-ext, dtld-cust-ledg-entry-ext, feature-permissionset)_
3. Must the Dunning Contact Code also appear on issued reminders and issued finance charge memos (and their customer and G/L entries)? Only the field numbers are reserved now; issued-table extensions are not designed. _(affects: reminder-header-ext, fin-charge-memo-header-ext)_
4. Application rows on the invoice's customer entry take the invoice entry's own Collection Channel (usually blank), as the knowledge prescribes. Is that what users expect, or must they show the payment's channel? _(affects: collection-channel-posting, dtld-cust-ledg-entry-ext)_
5. Must users see and filter Collection Channel as a column on Customer Ledger Entries and Detailed Cust. Ledg. Entries? If not, a related table keyed by Entry No. is preferred over stored fields on these hot ledgers. _(affects: cust-ledger-entry-ext, dtld-cust-ledg-entry-ext, cust-ledger-entries-page-ext, dtld-cust-ledg-entries-page-ext)_
6. Should the Collection Channel also reach G/L entries of payment and application postings, and what is expected on reversing detailed rows when an application is unapplied? _(affects: collection-channel-posting, gen-journal-line-ext)_
7. Is Collection Channel mandatory on cash receipt lines, and does it apply only to lines with Account Type Customer? _(affects: gen-journal-line-ext, cash-receipt-journal-ext)_
8. May users change the defaulted Dunning Contact Code on a reminder or finance charge memo before issuing, or is it read-only? _(affects: reminder-page-ext, fin-charge-memo-page-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Customer | Holds the Dunning Contact Code that reminders and finance charge memos default from. | Dunning Contact Code (Code[20]): Type and length are provisional: they must equal the related field once the TableRelation target is settled (see open question dunning-contact-reference). DataClassification = CustomerContent. | [8] [9] |
| 2 | extend | pageextension | Customer Card | Lets users maintain the Dunning Contact Code on the customer. |  | agent judgment |
| 3 | extend | tableextension | Reminder Header | Receives the defaulted Dunning Contact Code. Use the same field number and type as the Customer field so that, if issued reminders are later brought into scope, Issued Reminder Header can mirror it through TransferFields without a subscriber. | Dunning Contact Code (Code[20]): Same type and length as Customer."Dunning Contact Code"; same field number reserved for Issued Reminder Header. DataClassification = CustomerContent. | [1] [3] [9] |
| 4 | extend | tableextension | Finance Charge Memo Header | Receives the defaulted Dunning Contact Code on finance charge memos, which are a separate document with their own event. Same field number and type as on Reminder Header and Customer. | Dunning Contact Code (Code[20]): Same type and length as Customer."Dunning Contact Code"; same field number reserved for Issued Fin. Charge Memo Header. DataClassification = CustomerContent. | [1] [3] [9] |
| 5 | extend | pageextension | Reminder | Shows the defaulted Dunning Contact Code on the reminder document page. |  | agent judgment |
| 6 | extend | pageextension | Finance Charge Memo | Shows the defaulted Dunning Contact Code on the finance charge memo document page. |  | agent judgment |
| 7 | create | codeunit | Dunning Contact Defaults | Two subscribers, one per header table, on OnValidateCustomerNoOnAfterAssignCustomerValues. One subscriber per header covers manual entry, Create Reminders (via Reminder-Make), reminder automation and Create Finance Charge Memos (via FinChrgMemo-Make). |  | [1] |
| 8 | extend | tableextension | Gen. Journal Line | Holds the Collection Channel entered on cash receipt journal lines, and receives the applying entry's value on the journal line that application from Customer Ledger Entries creates. | Collection Channel (Code[20]): Type and length provisional until the reference is settled (open question collection-channel-reference); must match Cust. Ledger Entry and Detailed Cust. Ledg. Entry. DataClassification = CustomerContent. | [2] [8] [9] |
| 9 | extend | pageextension | Cash Receipt Journal | Lets users enter the Collection Channel on cash receipt journal lines. |  | agent judgment |
| 10 | extend | tableextension | Cust. Ledger Entry | Stores the Collection Channel on the customer entry. Cust. Ledger Entry is a hot ledger, where a related table keyed by Entry No. is preferred; a stored field is chosen because the request requires the value to appear on the entry, which the knowledge allows when users must see it as a native list column and it is read on almost every access (confirm with open question cle-list-column). The field exists only on Cust. Ledger Entry, so the round trip through CV Ledger Entry Buffer during application leaves it untouched. | Collection Channel (Code[20]): Same type and length as Gen. Journal Line."Collection Channel". DataClassification = CustomerContent. | [2] [7] [9] |
| 11 | extend | tableextension | Detailed Cust. Ledg. Entry | Stores the Collection Channel on each detailed row, taken from the customer entry the row belongs to, because the request requires it on detailed entries including application rows. | Collection Channel (Code[20]): Same type and length as Cust. Ledger Entry."Collection Channel". DataClassification = CustomerContent. | [2] [7] [9] |
| 12 | extend | pageextension | Customer Ledger Entries | Shows the Collection Channel as a list column on customer ledger entries. |  | [7] |
| 13 | extend | pageextension | Detailed Cust. Ledg. Entries | Shows the Collection Channel on detailed customer ledger entries. |  | agent judgment |
| 14 | create | codeunit | Collection Channel Posting | Subscribers that carry the Collection Channel from the journal line to the customer entry, from each customer entry to its own detailed rows, and from the applying entry to the application journal line. |  | [2] [4] [10] |
| 15 | create | permissionset | Dunning Contact and Collection Channel | Grants execute on the two codeunits and covers the pages the feature extends, so non-SUPER users can use the feature. |  | [11] |

## 3. How the data flows

- **User on Customer Card** → **Customer."Dunning Contact Code"**: entered by the user. agent judgment
- **Customer."Dunning Contact Code"** → **Reminder Header."Dunning Contact Code" (manual creation on the Reminder page)**: copied in an event subscriber. Validate("Customer No.") raises OnValidateCustomerNoOnAfterAssignCustomerValues; the page saves the record. [1]
- **Customer."Dunning Contact Code"** → **Reminder Header."Dunning Contact Code" (Create Reminders report 188 and reminder automation, via Reminder-Make 392)**: copied in an event subscriber. Reminder-Make inserts an empty header, validates Customer No. (same event) and then calls Modify. [1]
- **Customer."Dunning Contact Code"** → **Finance Charge Memo Header."Dunning Contact Code" (manual creation on the Finance Charge Memo page)**: copied in an event subscriber. [1]
- **Customer."Dunning Contact Code"** → **Finance Charge Memo Header."Dunning Contact Code" (Create Finance Charge Memos report 191, via FinChrgMemo-Make 394)**: copied in an event subscriber. FinChrgMemo-Make also validates Customer No. in a checking mode on a header that is never inserted. [1]
- **User on Cash Receipt Journal** → **Gen. Journal Line."Collection Channel"**: entered by the user. agent judgment
- **Gen. Journal Line."Collection Channel"** → **Cust. Ledger Entry."Collection Channel" (payment entry)**: copied in an event subscriber. Set in OnAfterCopyCustLedgerEntryFromGenJnlLine while the entry is initialized, before insert; no extra write. [2] [4]
- **Cust. Ledger Entry** → **CV Ledger Entry Buffer and back to Cust. Ledger Entry (during application)**: standard TransferFields copy. The field exists only on Cust. Ledger Entry; TransferFields leaves it untouched. No field is added to CV Ledger Entry Buffer. [2]
- **Cust. Ledger Entry."Collection Channel" (the entry named by DtldCVLedgEntryBuffer."CV Ledger Entry No.")** → **Detailed Cust. Ledg. Entry."Collection Channel" (initial and application rows posted from the cash receipt journal, including Applies-to ID applications)**: copied in an event subscriber. Set in OnBeforeInsertDtldCustLedgEntry from the row's own customer entry, never from the posted GenJournalLine, so invoice application rows do not take the payment's value. [2]
- **Cust. Ledger Entry."Collection Channel" (applying entry, application from Customer Ledger Entries)** → **Gen. Journal Line."Collection Channel" (journal line created with Init by CustEntry-Apply Posted Entries)**: copied in an event subscriber. Set in OnAfterCopyGenJnlLineFromCustLedgEntry, so the application posting carries the applying entry's value. [2]
- **Cust. Ledger Entry."Collection Channel" (each entry involved in a later application)** → **Detailed Cust. Ledg. Entry."Collection Channel" (application rows posted from Apply Customer Entries)**: copied in an event subscriber. Same OnBeforeInsertDtldCustLedgEntry subscriber; the payment's application row gets the payment entry's value even though the application journal line was created with Init. [2]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Reminder Header" | `OnValidateCustomerNoOnAfterAssignCustomerValues(var ReminderHeader; Customer)` | Assign ReminderHeader."Dunning Contact Code" := Customer."Dunning Contact Code". Covers manual creation, Create Reminders and reminder automation. | Assign the value from the Customer parameter and do nothing else. · Do not call Modify; the page or Reminder-Make saves the record afterwards. | [1] |
| Table "Finance Charge Memo Header" | `OnValidateCustomerNoOnAfterAssignCustomerValues(var FinanceChargeMemoHeader; Customer)` | Assign FinanceChargeMemoHeader."Dunning Contact Code" := Customer."Dunning Contact Code". Covers manual creation and Create Finance Charge Memos. | Assign the value from the Customer parameter and do nothing else. · Do not call Modify: in FinChrgMemo-Make's checking mode the header is never inserted, so Modify fails; in the normal flow the make codeunit modifies the record right after. | [1] |
| Table "Cust. Ledger Entry" | `OnAfterCopyCustLedgerEntryFromGenJnlLine(var CustLedgerEntry; GenJournalLine)` | Copy GenJournalLine."Collection Channel" to the customer entry before it is inserted. | Assign only; do not find and Modify the posted entry afterwards. | [2] [4] [6] |
| Codeunit "Gen. Jnl.-Post Line" | `OnBeforeInsertDtldCustLedgEntry(var DtldCustLedgEntry; GenJournalLine; DtldCVLedgEntryBuffer; GLRegister)` | Set DtldCustLedgEntry."Collection Channel" from the Cust. Ledger Entry named by DtldCVLedgEntryBuffer."CV Ledger Entry No." (already inserted when the event runs). | Read the value from the row's own customer entry, never from GenJournalLine: otherwise invoice application rows get the payment's value and rows from Apply Customer Entries get blank. · Load only the Collection Channel field (SetLoadFields) before the Get, and use if Get(...) so a missing entry does not raise an error. · Do not write the field on closed invoice entries with Modify after posting. | [2] [10] [6] |
| Table "Gen. Journal Line" | `OnAfterCopyGenJnlLineFromCustLedgEntry(CustLedgerEntry; var GenJournalLine)` | Give the application journal line created by CustEntry-Apply Posted Entries the applying entry's Collection Channel. | Assign only; application itself stays in the standard application codeunits. | [2] [5] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification = CustomerContent on every new field in every tableextension (a tableextension has no table-level value to inherit); leave none as ToBeClassified or SystemMetadata. [9]
- **permissions**: Ship a permission set granting execute on Dunning Contact Defaults and Collection Channel Posting and covering the extended pages; verify manual reminder creation, both batch jobs, cash receipt posting and application as a user without SUPER. Grant the minimum, no wildcards. [11]
- **upgrade**: No upgrade code: all fields are new schema with no released baseline. Existing reminders, finance charge memos and ledger entries keep a blank value; a back-fill is not part of this design. [12]

## 6. Tests

1. **reminder-manual-defaults-dunning-contact** [1] [13]
    - Given A customer created with library codeunits, with a reminder terms code and a Dunning Contact Code.
    - When A user creates a reminder on the Reminder page and enters the customer number.
    - Then The Reminder Header's Dunning Contact Code equals the customer's.
2. **create-reminders-defaults-dunning-contact** [1] [15] [14]
    - Given A customer with a Dunning Contact Code, reminder terms and levels, and an overdue posted sales invoice (full posting-group chain set up).
    - When Create Reminders runs for that customer.
    - Then The created Reminder Header has the customer's Dunning Contact Code.
3. **fin-charge-memo-manual-defaults-dunning-contact** [1]
    - Given A customer with finance charge terms and a Dunning Contact Code.
    - When A user creates a finance charge memo on the Finance Charge Memo page and enters the customer number.
    - Then The Finance Charge Memo Header's Dunning Contact Code equals the customer's.
4. **create-fin-charge-memos-defaults-dunning-contact** [1] [15]
    - Given A customer with finance charge terms, a Dunning Contact Code and an overdue posted sales invoice (full posting-group chain set up).
    - When Create Finance Charge Memos runs for that customer.
    - Then The created Finance Charge Memo Header has the customer's Dunning Contact Code, and the run raises no error from the checking mode.
5. **cash-receipt-channel-reaches-customer-entry** [2] [13]
    - Given A cash receipt journal line for a customer with a Collection Channel and no application.
    - When The journal line is posted.
    - Then The payment's Cust. Ledger Entry and its initial Detailed Cust. Ledg. Entry carry the Collection Channel.
6. **applies-to-id-application-rows-use-own-entry** [2]
    - Given A posted sales invoice with a blank Collection Channel and a cash receipt line with a Collection Channel that applies to it through Applies-to ID.
    - When The cash receipt line is posted.
    - Then Application rows of the payment entry carry the payment's Collection Channel, and application rows of the invoice entry carry the invoice entry's own (blank) value, not the payment's.
7. **later-application-carries-channel** [2] [5]
    - Given A posted unapplied payment with a Collection Channel and an open posted invoice for the same customer.
    - When The payment is applied to the invoice from Customer Ledger Entries through the standard application codeunit (CustEntry-Apply Posted Entries).
    - Then The payment entry's application Detailed Cust. Ledg. Entry carries the Collection Channel (not blank), the invoice entry's application row carries the invoice entry's own value, and the payment Cust. Ledger Entry keeps its Collection Channel after the application.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown (no repository or app.json); all selected articles declare [all]/w1/all, so applicability is not affected.
- Page extensions customer-card-ext, reminder-page-ext, fin-charge-memo-page-ext, cash-receipt-journal-ext and dtld-cust-ledg-entries-page-ext and the user-entry hops rest on agent judgment; no BCQuality article covers them. Target page names (Customer Card, Reminder, Finance Charge Memo, Cash Receipt Journal, Detailed Cust. Ledg. Entries) are not confirmed by an opened article or repository symbols.
- Object and field IDs are not assigned; the app's ID range is unknown without app.json.

## Sources

[1] `microsoft/knowledge/finance-extensions/default-customer-fields-on-reminder-and-finance-charge-headers.md`: Defaulting Dunning Contact Code onto reminder and finance charge memo headers for manual and batch creation.
    - Subscribe to OnValidateCustomerNoOnAfterAssignCustomerValues on each header table in scope; one subscriber covers manual entry, Create Reminders, reminder automation and Create Finance Charge Memos.
    - Assign the value from the Customer parameter and do nothing else; do not call Modify in the event (fails in FinChrgMemo-Make checking mode).
    - Do not rely only on OnBeforeReminderHeaderInsert on Reminder-Make; manually created reminders would not get the value.
    - A design that defaults on reminders must add the finance charge memo subscriber too when both are in scope.
    - Sales header events such as OnAfterCopySellToCustomerAddressFieldsFromCustomer do not run for these documents.
[2] `microsoft/knowledge/finance-extensions/carry-cash-receipt-fields-to-customer-and-detailed-ledger-entries.md`: Carrying Collection Channel from cash receipt journal lines to customer and detailed customer ledger entries, including later applications.
    - Store the field on Cust. Ledger Entry and set it in OnAfterCopyCustLedgerEntryFromGenJnlLine.
    - For detailed entries, set it in OnBeforeInsertDtldCustLedgEntry from the customer entry named by DtldCVLedgEntryBuffer."CV Ledger Entry No.", not from GenJournalLine.
    - For application postings, set it on the new journal line in OnAfterCopyGenJnlLineFromCustLedgEntry.
    - Do not write the field on closed invoice entries with Modify after posting.
    - Change application only through the application codeunits.
[3] `microsoft/knowledge/finance-extensions/carry-reminder-and-finance-charge-fields-when-issuing.md`: Choosing field numbers on the reminder and finance charge memo headers so issued documents can mirror the value later.
    - To show a custom field on issued documents, give it the same field number and type on the source and issued tables; no subscriber is needed.
    - Do not fill the issued header in OnAfterIssueReminder with Modify.
[4] `microsoft/knowledge/sales-purchase/carry-sales-fields-to-customer-ledger-through-the-journal-line.md`: The journal-line to customer-entry hop and the choice between a stored field and a related table.
    - Copy the value in OnAfterCopyCustLedgerEntryFromGenJnlLine while the entry is initialized, before insert, with no extra write.
    - Store the field on the ledger entry only when users must see or filter it as a native list column, or it is read on almost every access.
    - Do not find the customer entry after posting and Modify it.
[5] `microsoft/knowledge/finance/apply-ledger-entries-through-application-codeunits.md`: Keeping application in the standard workflow and exercising it in tests.
    - Use CustEntry-Apply Posted Entries and the supported application workflow; do not persist Open, Closed by Entry No. or detailed application amounts directly.
[6] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Guard against writing the Collection Channel onto posted entries after posting.
    - Do not persist changes to posted customer or detailed ledger entries outside a supported workflow; a subscriber is not exempt merely because it runs inside a supported workflow.
[7] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Deciding between a stored field and a related table on Cust. Ledger Entry and Detailed Cust. Ledg. Entry.
    - Put optional, sparse or integration attributes in a related table keyed by the ledger entry number.
    - Use a tableextension stored field only when the value must appear as a native list column and is read on almost every access.
[8] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing Dunning Contact Code and Collection Channel once their TableRelation targets are known.
    - Read the type and length of the related field before adding a TableRelation.
    - For an unconditional relation, use the same type and exact length as the related field.
[9] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classifying every new field in the table extensions.
    - Every Normal field a tableextension adds must set its own DataClassification.
    - Do not leave fields ToBeClassified or classify customer data as SystemMetadata.
[10] `microsoft/knowledge/performance/guard-event-subscribers-before-db-call.md`: The database read in the OnBeforeInsertDtldCustLedgEntry subscriber.
    - Keep subscriber code lightweight; apply cheap in-memory guards before any database call.
    - Issue the database call with SetLoadFields for only the columns the body reads.
[11] `microsoft/knowledge/appsource/permission-sets-cover-setup-and-usage-without-super.md`: The permission set step.
    - Provide permission sets that let users complete normal usage without SUPER, covering every page and codeunit the feature uses.
    - Grant the minimum required operations; do not use wildcards.
[12] `microsoft/knowledge/upgrade/unreleased-schema-change-needs-no-upgrade-path.md`: Deciding that no upgrade code is needed for the new fields.
    - Schema that has no released baseline needs no upgrade or migration path.
[13] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Building customer, invoice, journal and reminder fixtures.
    - Use library codeunits (LibrarySales, LibraryERM, LibraryRandom) instead of hand-rolled Init/Insert; create parents before dependents and Validate foreign keys.
[14] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Test data rules for all scenarios.
    - Create the records the test owns instead of assuming existing ones; fill every mandatory field.
    - Keep scenario-defining values such as amounts and dates explicit.
[15] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Batch job and posting test setup.
    - For posting and batch tests, set up the full posting-group chain and the setup records the path reads, with explicit dates when the path is date-sensitive.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
