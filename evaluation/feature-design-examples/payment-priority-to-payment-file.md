# Feature design

> Vendor ledger entries carry a Payment Priority Code. When we run Suggest Vendor Payments, each payment journal line must get that code, and our bank's payment file needs it in an extra column. When payments are matched in the payment reconciliation journal, the bank batch reference from the statement line must reach the resulting bank and vendor ledger entries.

**Result:** Complete design. **Business process:** Vendor payments: Suggest Vendor Payments into the payment journal, payment file export through the data exchange framework, and payment reconciliation journal posting to bank and vendor ledger entries. **Knowledge used:** 14 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Does Payment Priority Code already exist on Vendor Ledger Entry in one of your apps, and how is it filled (for example from the purchase invoice or the vendor card)? The request does not say, so this design does not fill it. _(affects: vendor-ledger-entry-ext)_
2. What are the type, length and allowed values of Payment Priority Code: free code, option/enum, or a relation to a priority table (which would need its own table, page and permissions)? _(affects: vendor-ledger-entry-ext, vendor-payment-buffer-ext, gen-journal-line-ext, payment-export-data-ext)_
3. When Summarize per Vendor is on and the invoices have different priority codes, what should the summarized payment line carry: nothing, the code only when it is the same for all entries, or a code that is constant per vendor? _(affects: payment-priority-suggest-cu, suggest-payments-summarized-priority-code)_
4. Which payment export format does the bank account use, and what are the column position, name and format of the extra column? If it is a fixed XMLport format such as SEPA credit transfer, the data exchange mapping cannot carry the value. _(affects: payment-export-data-ext, payment-priority-export-cu, payment-export-carries-priority-code)_
5. How does the bank batch reference get onto the payment reconciliation journal line: from the imported bank statement file (which column in the statement import definition), or typed by the user? What is its maximum length? _(affects: bank-acc-recon-line-ext)_
6. Must the posted payment reconciliation (Posted Payment Recon. Line) also keep the bank batch reference? If yes, mirror the field with the same number and type there. _(affects: bank-acc-recon-line-ext)_
7. Must users see or filter Bank Batch Ref. (and Payment Priority Code) as columns on the Vendor Ledger Entries and Bank Account Ledger Entries pages? If not, a related table keyed by Entry No. is preferred over stored fields on the ledgers. _(affects: vendor-ledger-entry-ext, bank-account-ledger-entry-ext)_
8. Should the Payment Priority Code also be copied from the payment journal line to the vendor payment ledger entry when the payment journal is posted, or is it needed only on the journal line and in the file? _(affects: bank-batch-ref-posting-cu, gen-journal-line-ext)_
9. Should Payment Priority Code be visible or editable on the Payment Journal page, and Bank Batch Ref. on the Payment Reconciliation Journal page? _(affects: gen-journal-line-ext, bank-acc-recon-line-ext)_
10. Do open vendor ledger entries posted before this feature need a Payment Priority Code (a backfill through upgrade code), or does the feature apply only to new entries? _(affects: vendor-ledger-entry-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Vendor Ledger Entry | Holds the Payment Priority Code that Suggest Vendor Payments reads, and receives the Bank Batch Ref. on payment entries posted from the payment reconciliation journal. Stored fields because the request requires the values on the entries; whether users need them as native list columns (otherwise a related table keyed by Entry No.) is open. Add Payment Priority Code only if no existing app already defines it. Fields are Editable = false; values arrive only through posting. | Payment Priority Code (Code[10]): Length and any TableRelation are open; with a relation, match the related field's type and exact length. Skip this field if it already exists on Vendor Ledger Entry.; Bank Batch Ref. (Code[35]): Length is open; use the same field number, type and length as on Gen. Journal Line and Bank Acc. Reconciliation Line. | [5] [6] [10] [9] |
| 2 | extend | tableextension | Vendor Payment Buffer | Carries Payment Priority Code from the vendor ledger entry to the payment journal line inside Suggest Vendor Payments. Cannot join the buffer's primary key, so a summarized line keeps the first entry's value. | Payment Priority Code (Code[10]): Same type and length as on Vendor Ledger Entry. | [1] [9] |
| 3 | extend | tableextension | Gen. Journal Line | Payment Priority Code on suggested payment lines (source for the payment file), and Bank Batch Ref. on the journal line that payment application builds and posts. | Payment Priority Code (Code[10]): Same type and length as on Vendor Payment Buffer and Payment Export Data.; Bank Batch Ref. (Code[35]): Same type and length as on Bank Acc. Reconciliation Line. | [1] [3] [4] [9] |
| 4 | extend | tableextension | Payment Export Data | Gives the data exchange definition a Payment Priority Code field to map to the extra file column; the export does not read Gen. Journal Line while writing the file. | Payment Priority Code (Code[10]) | [2] [9] |
| 5 | extend | tableextension | Bank Acc. Reconciliation Line | Holds the bank batch reference on the payment reconciliation journal (statement) line. How it is filled during statement import is an open question. | Bank Batch Ref. (Code[35]): Length is open. If the posted payment reconciliation must keep it, mirror it with the same number and type on Posted Payment Recon. Line. | [3] [9] |
| 6 | extend | tableextension | Bank Account Ledger Entry | Receives Bank Batch Ref. from the journal line when payment application posts. Editable = false; reversal copies the reference unchanged, which is correct for a code. | Bank Batch Ref. (Code[35]) | [4] [6] [9] |
| 7 | create | codeunit | Payment Priority Suggest | Subscribers that copy Payment Priority Code from Vendor Ledger Entry to Vendor Payment Buffer and from the buffer to Gen. Journal Line during Suggest Vendor Payments. Never fill lines afterwards by looking up a source entry. |  | [1] |
| 8 | create | codeunit | Payment Priority Export | Subscriber that sets Payment Export Data.Payment Priority Code from the journal line before each export row is inserted. Does not copy or replace the pre-mapping codeunit or rewrite the file afterwards. |  | [2] |
| 9 | create | codeunit | Bank Batch Ref. Posting | Subscribers that copy Bank Batch Ref. from the reconciliation line to the payment-application journal line, and from the journal line to the bank account ledger entry and vendor ledger entry while posting initializes them. Never modifies posted entries afterwards (for example in OnAfterFinalizePost). |  | [3] [4] [5] [7] [8] |

## 3. How the data flows

- **Vendor Ledger Entry.Payment Priority Code** → **Vendor Payment Buffer.Payment Priority Code**: copied in an event subscriber. Vendor Payment Buffer.OnAfterCopyFieldsFromVendorLedgerEntry, raised for each entry Suggest Vendor Payments processes. With Summarize per Vendor, the first entry's value is kept. [1]
- **Vendor Payment Buffer.Payment Priority Code** → **Gen. Journal Line.Payment Priority Code (payment journal)**: copied in an event subscriber. Vendor Payment Buffer.OnAfterCopyFieldsToGenJournalLine, once per created payment line. [1]
- **Gen. Journal Line.Payment Priority Code** → **Payment Export Data.Payment Priority Code**: copied in an event subscriber. Exp. Pre-Mapping Gen. Jnl. OnBeforeInsertPaymentExoprtData (exact misspelled name), before each row is inserted. [2]
- **Payment Export Data.Payment Priority Code** → **Bank payment file extra column**: other. Field mapping in the bank's payment export Data Exchange Definition, like any standard column. Not available for fixed formats with their own XMLport, such as SEPA credit transfer. [2]
- **Bank Acc. Reconciliation Line.Bank Batch Ref.** → **Gen. Journal Line.Bank Batch Ref. (payment application)**: copied in an event subscriber. Bank Acc. Reconciliation Post OnPostPaymentApplicationsOnAfterInitGenJnlLine, with IsHandled left false. [3]
- **Gen. Journal Line.Bank Batch Ref.** → **Bank Account Ledger Entry.Bank Batch Ref.**: copied in an event subscriber. Bank Account Ledger Entry OnAfterCopyFromGenJnlLine, raised by CopyFromGenJnlLine in Gen. Jnl.-Post Line. [4]
- **Gen. Journal Line.Bank Batch Ref.** → **Vendor Ledger Entry.Bank Batch Ref.**: copied in an event subscriber. Vendor Ledger Entry OnAfterCopyVendLedgerEntryFromGenJnlLine, as the vendor payment entry is initialized. [5] [3]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Vendor Payment Buffer" | `OnAfterCopyFieldsFromVendorLedgerEntry` | Copy Payment Priority Code from the vendor ledger entry into the buffer. | Behavior for summarized lines (Summarize per Vendor) follows the answer to the open question: carry only when summarizing is off, or rely on a value that is constant per vendor. | [1] |
| Table "Vendor Payment Buffer" | `OnAfterCopyFieldsToGenJournalLine` | Copy Payment Priority Code from the buffer to the new payment journal line. |  | [1] |
| Codeunit "Exp. Pre-Mapping Gen. Jnl." | `OnBeforeInsertPaymentExoprtData` | Set Payment Export Data.Payment Priority Code from the Gen. Journal Line. | Copy the publisher's misspelled event name exactly; a corrected spelling does not compile. · Do not subscribe to Pmt Export Mgt Gen. Jnl Line OnBeforeInsertPmtExportDataJnlFromGenJnlLine unless the app is on-premises and must support the older path; it is Scope OnPrem. | [2] |
| Codeunit "Bank Acc. Reconciliation Post" | `OnPostPaymentApplicationsOnAfterInitGenJnlLine` | Copy Bank Batch Ref. from the reconciliation line to the journal line that payment application posts. | Leave IsHandled false so the standard application and posting of the line still run. · Do not post or apply the line in the subscriber. | [3] [8] |
| Table "Bank Account Ledger Entry" | `OnAfterCopyFromGenJnlLine` | Copy Bank Batch Ref. to the bank account ledger entry while it is initialized. |  | [4] |
| Table "Vendor Ledger Entry" | `OnAfterCopyVendLedgerEntryFromGenJnlLine` | Copy Bank Batch Ref. to the vendor ledger entry while it is initialized. The same subscriber point would also copy Payment Priority Code to payment entries if the requester wants that (open question). |  | [5] |

## 5. Setup, permissions and lifecycle

- **setup**: Before relying on the mapping, check which export the bank account's payment export setup uses. In that bank's payment export Data Exchange Definition, add a column definition for the extra column and a field mapping to Payment Export Data.Payment Priority Code. Fixed XMLport formats such as SEPA credit transfer cannot carry it this way. [2]
- **privacy**: Give every new field a real DataClassification (CustomerContent for these business references) and leave no ToBeClassified before release. [9]

## 6. Tests

1. **suggest-payments-copies-priority-code** [1] [11] [13] [12] [14]
    - Given A vendor with an open posted invoice whose vendor ledger entry has a random Payment Priority Code, created with library codeunits including the full posting-group chain, and a payment journal batch; Summarize per Vendor is off.
    - When Suggest Vendor Payments runs for that vendor.
    - Then The created payment journal line has the vendor ledger entry's Payment Priority Code.
2. **suggest-payments-summarized-priority-code** [1] [11] [12] [14]
    - Given A vendor with two open invoices whose entries have different Payment Priority Codes; Summarize per Vendor is on.
    - When Suggest Vendor Payments runs for that vendor.
    - Then The single summarized payment line carries the value the requester chose for summarized lines (for example blank or the vendor-constant code), not an arbitrary entry's code.
3. **payment-export-carries-priority-code** [2] [11] [13] [12] [14]
    - Given A bank account using a data exchange payment export definition with the Payment Priority Code column mapped, and a payment journal line with a Payment Priority Code.
    - When The payment journal line is exported to a payment file.
    - Then The Payment Export Data row (and the file's extra column) contains the journal line's Payment Priority Code.
4. **recon-posting-carries-batch-ref-to-bank-ledger** [3] [4] [11] [13] [12] [14]
    - Given An open vendor invoice entry and a payment reconciliation journal line with a random Bank Batch Ref. matched to it, with full bank and vendor posting setup.
    - When The payment reconciliation journal is posted.
    - Then The resulting bank account ledger entry has the line's Bank Batch Ref.
5. **recon-posting-carries-batch-ref-to-vendor-ledger-and-applies** [3] [5] [8] [11] [13] [12] [14]
    - Given An open vendor invoice entry and a payment reconciliation journal line with a random Bank Batch Ref. applied to it in full.
    - When The payment reconciliation journal is posted.
    - Then The vendor payment ledger entry has the Bank Batch Ref., and the invoice entry is closed by the application, proving IsHandled stayed false.
6. **reversal-keeps-batch-ref** [4] [11] [12] [14]
    - Given A posted payment carrying a Bank Batch Ref. on its bank account and vendor ledger entries, unapplied so it can be reversed.
    - When The transaction is reversed.
    - Then The reversing bank account and vendor ledger entries carry the same Bank Batch Ref. as the originals.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined (no repository, not stated in the request); prefer-related-table-over-extension-on-hot-ledgers applies from BC23.
- Filling Bank Batch Ref. on the reconciliation line during bank statement import is not designed and is not covered by BCQuality knowledge; see open question batch-ref-on-statement-line.
- The parameter list of Bank Account Ledger Entry OnAfterCopyFromGenJnlLine is not shown in the opened article or samples; confirm it against the target version's symbols when implementing.

## Sources

[1] `microsoft/knowledge/finance-extensions/carry-vendor-ledger-fields-to-suggested-payment-lines.md`: Path from Vendor Ledger Entry through Vendor Payment Buffer to the payment journal line during Suggest Vendor Payments.
    - Add the field to Vendor Payment Buffer and Gen. Journal Line and subscribe to OnAfterCopyFieldsFromVendorLedgerEntry and OnAfterCopyFieldsToGenJournalLine.
    - With Summarize per Vendor, a custom field keeps the first entry's value and cannot be added to the buffer's primary key; decide what the value means on a summarized line (carry only when summarizing is off, or use a value constant per vendor).
    - Do not fill the field after the report runs by looking up a source vendor ledger entry for each journal line.
[2] `microsoft/knowledge/finance-extensions/add-custom-data-to-payment-export-files.md`: Getting Payment Priority Code into the bank's payment file through Payment Export Data and the data exchange field mapping.
    - Add the field to Payment Export Data, set it in a subscriber to OnBeforeInsertPaymentExoprtData, and map it in the data exchange definition's field mapping.
    - Copy the misspelled event name exactly; a corrected spelling names an event that does not exist.
    - OnBeforeInsertPmtExportDataJnlFromGenJnlLine is Scope OnPrem; subscribe to it only in an on-premises app that must support the older path.
    - Fixed formats with their own XMLport, such as SEPA credit transfer, do not use this mapping; check the bank account's export setup.
    - Do not rewrite the exported file afterwards or replace the pre-mapping codeunit with a copy.
[3] `microsoft/knowledge/finance-extensions/carry-bank-reconciliation-line-fields-to-payment-postings.md`: Carrying Bank Batch Ref. from the payment reconciliation line into the journal line that payment application posts.
    - Add the field to Gen. Journal Line and set it in OnPostPaymentApplicationsOnAfterInitGenJnlLine, leaving IsHandled false; standard journal-line events take it to the entries.
    - To keep the value in the posted payment reconciliation, mirror the field with the same number and type on Posted Payment Recon. Line.
    - Do not set IsHandled to true to add a field, and do not modify posted bank or vendor ledger entries in OnAfterFinalizePost.
    - OnAfterFinalizePost runs before the codeunit's Commit and does not run in posting preview.
[4] `microsoft/knowledge/finance-extensions/carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md`: Copying Bank Batch Ref. from Gen. Journal Line to Bank Account Ledger Entry, and its behavior on reversal.
    - A custom Gen. Journal Line field reaches Bank Account Ledger Entry only through a subscriber to its OnAfterCopyFromGenJnlLine event.
    - Do not store the field on a ledger entry only because it exists on the journal line.
    - Reversal copies custom fields unchanged; a reference or code can stay as copied, a custom amount must be negated. Add a test that reverses a posted transaction and checks the custom values.
[5] `microsoft/knowledge/sales-purchase/carry-purchase-fields-to-vendor-ledger-through-the-journal-line.md`: Copying Bank Batch Ref. from Gen. Journal Line to Vendor Ledger Entry during posting.
    - Add the field to Gen. Journal Line and Vendor Ledger Entry and subscribe to OnAfterCopyVendLedgerEntryFromGenJnlLine so the value is part of the posting itself.
    - Store the field on the ledger entry only when users must see or filter it as a native list column or it is read on almost every access; otherwise prefer a related table keyed by the entry number.
    - Do not find and modify the vendor entry after posting.
[6] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choice between stored fields on Vendor and Bank Account Ledger Entry and a related table (applies from BC23).
    - Put optional, sparse or integration attributes in a related table keyed by the ledger entry number, shown through a FactBox or FlowField.
    - Use a stored tableextension field only when the value must appear as a native list column and is read on almost every access.
[7] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Rules out filling bank and vendor ledger entries after posting.
    - Do not persist changes to posted financial content or repair it outside the supported posting and correction workflows; a subscriber inside a supported workflow is judged by the fields it changes.
[8] `microsoft/knowledge/events/do-not-bypass-critical-operations-with-ishandled.md`: Guard on the payment-application subscriber.
    - Do not use IsHandled to skip posting or ledger-entry creation; adjust values while the critical work runs unconditionally.
[9] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Data classification of every new field.
    - Resolve every ToBeClassified to a real classification before release, decided from the data's content.
[10] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing Payment Priority Code if it gets a TableRelation.
    - With an unconditional relation, the field must have the related field's type and exact length; a shorter field fails at runtime once a longer value is used.
[11] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for vendors, invoices, bank accounts and journals.
    - Build fixtures with the test Library codeunits and random values, creating parents before dependents and validating foreign keys, instead of hand-rolled Init/Insert.
[12] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit.
    - Tag the codeunit with [FEATURE] and each test with [SCENARIO], [GIVEN], [WHEN] and [THEN] comments.
[13] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Preconditions of the posting and export tests.
    - For a posting test, set up the full posting-group chain and the setup records the posting path reads.
[14] `microsoft/knowledge/testing/test-one-when-per-test.md`: Test granularity.
    - Give each test one [WHEN] and one focused claim; preconditions such as posting the invoice belong in [GIVEN].

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
