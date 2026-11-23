---
bc-version: [all]
domain: finance-extensions
keywords: [bank-acc-reconciliation, payment-reconciliation-journal, bank-acc-reconciliation-post, posted-payment-recon-line, bank-account-statement, onpostpaymentapplicationsonafterinitgenjnlline, onafterfinalizepost, match-bank-payments]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry bank reconciliation line fields to payment postings and posted statements

## Description

`"Bank Acc. Reconciliation Post"` (370) handles two different stages for a `Bank Acc. Reconciliation Line`:

- **Payment application.** For a payment reconciliation journal, each applied line becomes a `Gen. Journal Line` that the codeunit builds field by field, then posts with `"Gen. Jnl.-Post Line".RunWithCheck`. After the standard fields are set and before the amounts and applications, it raises `OnPostPaymentApplicationsOnAfterInitGenJnlLine(var GenJournalLine; BankAccReconciliationLine; var IsApplied; var AppliedAmount; var PaymentLineAmount; var IsHandled)`.
- **History.** The statement and its lines are copied with `TransferFields` into `Bank Account Statement` and `Bank Account Statement Line`, or into `Posted Payment Recon. Hdr` and `Posted Payment Recon. Line` for payment reconciliation journals.

The commit order differs from document posting. `OnAfterFinalizePost` runs at the end of `FinalizePost`, before the codeunit's `Commit()`, so an error there rolls back the whole reconciliation posting. `FinalizePost` exits at once in posting preview, so neither `OnBeforeFinalizePost` nor `OnAfterFinalizePost` runs during preview.

## Best Practice

To carry a custom line field to the customer, vendor or bank ledger entries created by payment application, add it to `Gen. Journal Line` and set it in `OnPostPaymentApplicationsOnAfterInitGenJnlLine`, leaving `IsHandled` false. From there the standard journal-line events take it to the entries; see [carry Gen. Journal Line fields to G/L, VAT and bank entries](carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md). To keep the value in the posted statement or posted payment reconciliation, mirror the field with the same number and type on those tables, as for any `TransferFields` target.

To change which open entries automatic matching considers, use the filter events of `"Match Bank Payments"` (1255), such as `OnInitCustomerLedgerEntriesMatchingBufferSetFilter` and `OnInitVendorLedgerEntriesMatchingBufferSetFilter`, rather than a copy of the matching codeunit. Applications themselves go through the standard application path; see [apply ledger entries through application codeunits](../finance/apply-ledger-entries-through-application-codeunits.md).

See sample: [`carry-bank-reconciliation-line-fields-to-payment-postings.good.al`](carry-bank-reconciliation-line-fields-to-payment-postings.good.al).

## Anti Pattern

Set `IsHandled` to true in `OnPostPaymentApplicationsOnAfterInitGenJnlLine` to add one field, which skips the standard application and posting of that line. Or modify the posted bank, customer or vendor ledger entries in `OnAfterFinalizePost`; the entries are outputs of posting, see [do not modify or delete posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md).

See sample: [`carry-bank-reconciliation-line-fields-to-payment-postings.bad.al`](carry-bank-reconciliation-line-fields-to-payment-postings.bad.al).

## References

- [Bank Acc. Reconciliation Post, payment application and finalize](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Bank/Reconciliation/BankAccReconciliationPost.Codeunit.al).
- [Match Bank Payments, matching buffer filters](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Bank/Reconciliation/MatchBankPayments.Codeunit.al).
