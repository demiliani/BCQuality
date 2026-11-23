---
kind: action-skill
id: al-finance-extensions-review
version: 1
title: AL finance extensions review
description: Reviews AL extensions of finance, payment, reminder and fixed asset processes against BCQuality guidance.
inputs: [pr-diff, file-path, folder-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
---

# AL finance extensions review

Reviews AL source changes against the `finance-extensions` knowledge domain in BCQuality. This is a leaf action skill composed by `al-code-review`.

## Source

Use READ's **Bounded retrieval for review skills** workflow with `-Domain finance-extensions`. Consume every catalog page across enabled layers before applying this leaf's Relevance and Worklist; preserve each exact catalog path and open complete bodies only for exact paths selected by the Worklist. If the helper or prepared index is unavailable or invalid, use READ's explicit path-discovery and bounded native-read fallback.

## Relevance

Apply READ's frontmatter matching rules against the task context. Use the target version from `app.json` when available and `[al]` for technologies. Retain conditionally applicable files only when configured; cap resulting confidence at `medium` and name every unknown dimension in the finding message.

Return `not-applicable` when the input contains none of the following: code that inserts `Gen. Journal Line` rows and runs `"Gen. Jnl.-Post Batch"`, table extensions of `G/L Entry`, `VAT Entry`, `Bank Account Ledger Entry`, `Vendor Payment Buffer`, `Payment Export Data`, bank reconciliation, reminder, finance charge memo or fixed asset tables, a new table with global dimension fields, or event subscribers to `Gen. Jnl.-Post Reverse`, `Default Dimension`, `Suggest Vendor Payments`, `Exp. Pre-Mapping Gen. Jnl.`, `Bank Acc. Reconciliation Post`, `Match Bank Payments`, `Reminder-Issue`, `FinChrgMemo-Issue`, `Make FA Ledger Entry`, `Make Maintenance Ledger Entry` or the `Calculate Depreciation` report; code or subscribers touching `Reminder Header`, `Finance Charge Memo Header`, `Reminder-Make`, `FinChrgMemo-Make`, `Detailed Cust. Ledg. Entry`, `CustEntry-Apply Posted Entries`, allocation accounts or `Gen. Jnl. Allocation`, or intercompany outbox and inbox tables and `ICInboxOutboxMgt`. Also review inputs that extend `Deferral Header`, `Deferral Line` or `Deferral Posting Buffer`, subscribe to `Deferral Utilities` or the deferral insert events of `Gen. Jnl.-Post Line`, extend intercompany outbox or inbox tables, subscribe to `ICInboxOutboxMgt`, or call `ChangeCompany`.

## Worklist

Match relevant entries against the changed objects and subscribers named in Relevance. The following targeted checks cover the reviewable `finance-extensions` articles:

- A subscriber to `OnAfterCopyGLEntryFromGenJnlLine`, or to `OnAfterCopyFromGenJnlLine` on `VAT Entry` or `Bank Account Ledger Entry`, copies a custom Decimal amount and the app has no matching reversal subscriber on `Gen. Jnl.-Post Reverse` that negates it — `carry-gen-journal-line-fields-to-gl-vat-and-bank-entries`.
- Code inserts `Gen. Journal Line` rows and runs `"Gen. Jnl.-Post Batch"` with hard-coded template or batch names, a hard-coded `"Document No."` instead of `SetUpNewLine`, or a caller that expects rollback without `SetSuppressCommit(true)` — `post-finance-journal-lines-from-code-in-a-dedicated-batch`.
- A new table with Global Dimension 1 and 2 Code fields does not call `DeleteDefaultDim` in `OnDelete` or `RenameDefaultDim` in `OnRename`, or has no subscriber to `OnAfterUpdateGlobalDimCode` on `Default Dimension` — `give-a-new-master-table-default-dimensions`.
- A subscriber modifies payment journal lines after Suggest Vendor Payments to fill a value from vendor ledger entries, or a per-invoice value is expected on lines created with Summarize per Vendor — `carry-vendor-ledger-fields-to-suggested-payment-lines`.
- A subscriber targets `OnBeforeInsertPaymentExportData` (a spelling that does not exist; the publisher is `OnBeforeInsertPaymentExoprtData`), an online app subscribes to the OnPrem-scoped `OnBeforeInsertPmtExportDataJnlFromGenJnlLine`, or the app ships a copy of `"Exp. Pre-Mapping Gen. Jnl."` to add a value — `add-custom-data-to-payment-export-files`.
- A subscriber to `OnPostPaymentApplicationsOnAfterInitGenJnlLine` sets `IsHandled` to add a field, or a subscriber to `OnAfterFinalizePost` modifies bank, customer or vendor ledger entries — `carry-bank-reconciliation-line-fields-to-payment-postings`.
- A field on `Reminder Header` or `Finance Charge Memo Header` is expected on customer or G/L entries with no subscriber to the issuing codeunit's `OnAfterInitGenJnlLine`, or a subscriber to `OnAfterIssueReminder` or `OnAfterIssueFinChargeMemo` modifies issued documents or performs external calls — `carry-reminder-and-finance-charge-fields-when-issuing`.
- A subscriber carries a custom field to `FA Ledger Entry` or `Maintenance Ledger Entry` from only one of `OnAfterCopyFromFAJnlLine` and `OnAfterCopyFromGenJnlLine` on `Make FA Ledger Entry` or `Make Maintenance Ledger Entry` when the input states both sources matter, or code modifies FA or maintenance ledger entries after posting — `carry-fields-to-fa-ledger-entries-from-fa-and-gen-journal-lines`.
- A purchase line field is expected on `FA Ledger Entry` through matching field numbers only, or `Calculate Depreciation` is extended through only one of `OnBeforeFAJnlLineInsert` and `OnBeforeGenJnlLineInsert` — `carry-purchase-and-depreciation-fields-to-fixed-asset-entries`.
- A customer default on `Reminder Header` is set only in `OnBeforeReminderHeaderInsert`, or an `OnValidateCustomerNoOnAfterAssignCustomerValues` subscriber on `Reminder Header` or `Finance Charge Memo Header` calls `Modify` — `default-customer-fields-on-reminder-and-finance-charge-headers`.
- An `OnBeforeInsertDtldCustLedgEntry` subscriber assigns a custom field from the journal line to every detailed entry, or code modifies a custom field on closed invoice `Cust. Ledger Entry` rows after a payment posts or applies — `carry-cash-receipt-fields-to-customer-and-detailed-ledger-entries`.
- A custom `Sales Line` or `Purchase Line` field on allocation-account lines has no `OnBeforeCreateSalesLine` or `OnBeforeCreatePurchaseLine` subscriber, or allocated lines are repaired after posting — `carry-fields-through-allocation-account-lines`.
- An `OnAfterCopyGenJnlLineFromGenJnlAllocation` subscriber assigns only when the source is not blank, or a recurring-line field expected on allocation postings has no `OnPostAllocationsOnBeforeCopyFromGenJnlAlloc` subscriber — `carry-fields-through-recurring-journal-allocations`.
- A custom field on IC outbox or inbox tables has no `OnBeforeICInboxPurchHeaderInsert` or `OnBeforeICInboxPurchLineInsert` subscriber, a purchase line field is set in `OnCreatePurchLinesOnAfterTransferFields`, or `OnBeforeICInboxPurchHeaderInsert` reads company setup — `carry-intercompany-document-fields-to-the-partner-document`.
- An `OnAfterCopyGLEntryFromGenJnlLine` subscriber reads the G/L entry's posting date, account or amount to derive a value, a per-period value is written only on one of the `...ForGLAccount` / `...ForDeferralAccount` deferral insert events, `Deferral Header` or `Deferral Line` rows are inserted or modified directly instead of validating `Deferral Code` and calling `CreateDeferralSchedule`, or amount fields on a line with a `Deferral Code` are assigned without `Validate` — `carry-fields-to-deferral-gl-entries-and-maintain-deferral-schedules`.
- A record after `ChangeCompany` is used with `Validate`, `Insert(true)`, `Modify(true)` or a posting codeunit on journal or document tables, a journal line with an IC partner is posted through `Gen. Jnl.-Post Line` or from a non-Intercompany template, or a custom IC journal field is copied in fewer than the three outbox, inbox and journal-creation hops — `send-intercompany-journals-through-the-ic-outbox-not-changecompany`.

Resolve layer conflicts per READ. When no finance-extensions knowledge exists, emit `no-knowledge`; when knowledge exists but no article matches the changed code, emit `completed` with no findings.

## Action

Evaluate every worklist article against the changed objects and the subscribers that touch the process.

- Emit `major` for a subscriber that modifies posted ledger entries, that performs external side effects during posting preview, that declares a parameter the publisher does not have, or that subscribes to an event that does not exist or is not available to the app's target.
- Emit `minor` for a missing copy path, a mismatched field number or a copy-and-modify subscriber on posted document tables.
- Do not emit applicability-only information.

Set confidence to `high` when the table extensions and subscribers involved are all visible, and `medium` when the source table extension or the target table is outside the input. Domain-scoped agent findings follow DO's precision bar and remain capped at `minor`/`medium`.

Provide `suggested-code` only for a complete, local replacement. Otherwise set `suggested-code-omission-reason`.

Outcome selection follows DO: `completed`, `no-knowledge`, `not-applicable`, `partial`, or `failed`.

## Output

Output conforms to the DO findings-report contract. Every finding this skill emits MUST set `findings[].domain` to `"Finance extensions"`.
