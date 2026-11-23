---
bc-version: [all]
domain: finance-extensions
keywords: [cash-receipt-journal, cust-ledger-entry, detailed-cust-ledg-entry, cv-ledger-entry-buffer, onbeforeinsertdtldcustledgentry, onaftercopygenjnllinefromcustledgentry, custentry-apply-posted-entries, applies-to-id, application]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry cash receipt fields to customer and detailed ledger entries

## Description

A cash receipt journal line is a `Gen. Journal Line`. `Gen. Jnl.-Post Line` builds the `Cust. Ledger Entry` with `CopyFromGenJnlLine`, so `OnAfterCopyCustLedgerEntryFromGenJnlLine` carries a custom field to the payment entry. Application then passes the entry through `CV Ledger Entry Buffer` and back with `TransferFields`. A field that exists only on `Cust. Ledger Entry` keeps its value, because `TransferFields` leaves fields that the source does not have untouched.

`Detailed Cust. Ledg. Entry` is not built from the journal line. `InsertDtldCustLedgEntry` fills it with `TransferFields` from `Detailed CV Ledg. Entry Buffer`, then raises `OnBeforeInsertDtldCustLedgEntry(var DtldCustLedgEntry; GenJournalLine; DtldCVLedgEntryBuffer; GLRegister)`. That `GenJournalLine` is the line being posted. When a payment with `Applies-to ID` closes invoices, the application rows of the invoice entries get the payment's journal line too.

Applying posted entries later works differently. `"CustEntry-Apply Posted Entries"` creates a new journal line with `Init` and fills it from the applying entry with `CopyCustLedgEntry`, which raises `OnAfterCopyGenJnlLineFromCustLedgEntry`. Unapply uses `CopyCustLedgEntry` too, but `InsertDtldCustLedgEntryUnapply` copies the reversing detailed entry from the original one with a record assignment.

## Best Practice

Store the field on `Cust. Ledger Entry` and set it in `OnAfterCopyCustLedgerEntryFromGenJnlLine`; see [carry sales fields to the customer ledger](../sales-purchase/carry-sales-fields-to-customer-ledger-through-the-journal-line.md). Detailed entries point to their entry through `Cust. Ledger Entry No.`, so reports can read the value there.

If the field must be on the detailed entry, set it in `OnBeforeInsertDtldCustLedgEntry` from the customer entry the row belongs to. `DtldCVLedgEntryBuffer."CV Ledger Entry No."` names that entry, and it is already inserted when the event runs. To give application postings a value, set it on the new journal line in `OnAfterCopyGenJnlLineFromCustLedgEntry`. The G/L entries of that posting then get it through the usual journal-line events.

Change application only through the application codeunits; see [apply and unapply entries through the application workflow](../finance/apply-ledger-entries-through-application-codeunits.md).

See sample: [`carry-cash-receipt-fields-to-customer-and-detailed-ledger-entries.good.al`](carry-cash-receipt-fields-to-customer-and-detailed-ledger-entries.good.al).

## Anti Pattern

Copy `GenJournalLine."<field>"` to every detailed entry in `OnBeforeInsertDtldCustLedgEntry`. Application rows on invoice entries then show the payment's value. Rows posted from the Apply Customer Entries page get a blank value, because that journal line was created with `Init`. Writing the field on closed invoice entries with `Modify` after posting is also wrong; see [do not modify or delete posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md).

See sample: [`carry-cash-receipt-fields-to-customer-and-detailed-ledger-entries.bad.al`](carry-cash-receipt-fields-to-customer-and-detailed-ledger-entries.bad.al).

## References

- [Gen. Jnl.-Post Line, PostCust and InsertDtldCustLedgEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al).
- [Cust. Ledger Entry, CopyFromGenJnlLine and CopyFromCVLedgEntryBuffer](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Receivables/CustLedgerEntry.Table.al).
- [CustEntry-Apply Posted Entries](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Receivables/CustEntryApplyPostedEntries.Codeunit.al).
- [Gen. Journal Line, CopyCustLedgEntry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Journal/GenJournalLine.Table.al).
