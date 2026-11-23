---
bc-version: [all]
domain: sales-purchase
keywords: [onafterpostsalesdoc, onafterpostpurchasedoc, onafterpostservicedoc, onafterfinalizepost, bank-acc-reconciliation-post, posting-preview, commit, previewmode, follow-up-processing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Choose the after-posting hook per posting routine

## Description

Every posting routine has its own "after posting" event, and each one sits at a different point of the transaction. They differ in three ways that decide how a subscriber must be written: whether the commit has already happened, whether the event is raised during posting preview, and how the subscriber can tell that preview is running.

| Routine | Event | Commit before the event | Raised in preview | Preview check |
| --- | --- | --- | --- | --- |
| `Sales-Post` | `OnAfterPostSalesDoc` | Yes, unless commit is suppressed, preview or inventory pick and put-away | Yes | `PreviewMode` parameter |
| `Purch.-Post` | `OnAfterPostPurchaseDoc` | Yes, unless commit is suppressed, preview or inventory pick and put-away | Yes | No parameter; `"Gen. Jnl.-Post Preview".IsActive()` |
| `Service-Post` | `OnAfterPostServiceDoc` | Yes, unless commit is suppressed | No | Not needed |
| `Bank Acc. Reconciliation Post` | `OnAfterFinalizePost` | No; the commit follows the event | No | Not needed |

Details and samples for each row:

- Sales: [OnAfterPostSalesDoc runs after the posting commit](onafterpostsalesdoc-runs-after-the-posting-commit.md).
- Purchases: [OnAfterPostPurchaseDoc has no PreviewMode parameter](onafterpostpurchasedoc-has-no-previewmode-parameter.md).
- Service: [mirror service fields and follow up after service posting](../service/mirror-service-fields-and-follow-up-after-service-posting.md).
- E-documents: E-Document Core creates the e-document in its own `OnAfterPostSalesDoc` subscriber, after the commit, and skips it when commit is suppressed or in preview. See [e-document creation runs after the posting commit](../e-documents/e-document-creation-runs-after-the-posting-commit.md).

Bank reconciliation is the opposite case. `Bank Acc. Reconciliation Post` raises `OnAfterFinalizePost` at the end of `FinalizePost` and calls `Commit()` only after it returns. The subscriber still runs inside the posting transaction, so an error there rolls back the whole posting. By then the reconciliation and its lines are already deleted, so the subscriber can use the record it receives but cannot read the lines from the database. In preview, `FinalizePost` exits before the event.

## Best Practice

Write one rule per routine, from that routine's own row. Before subscribing, open the publisher at the target version and check three things: where the commit is, whether preview reaches the event, and which parameters it passes.

- After a commit (sales, purchases, service), treat the event as follow-up work. Do not rely on rollback, do not call `Commit()` when commit is suppressed, and send external calls through an outbox.
- Inside the transaction (bank reconciliation), an error is a valid way to stop posting. Keep slow work and external calls out, because they hold the posting's locks.
- Guard preview only where the event is raised in preview, and use the check that routine offers.

When a feature hooks several routines, give each subscriber its own guard and its own test, including a preview test where the event runs in preview.

## Anti Pattern

Design the sales subscriber, then copy it to the other routines by analogy. The purchase copy declares a `PreviewMode` parameter that its publisher does not have. The service copy adds a preview guard that never fires. The bank reconciliation copy assumes the posting is committed, and its error then undoes the reconciliation the user just posted. Another mistake is to assume E-Document Core's e-document already exists inside your own sales after-posting subscriber.

## References

- [Sales-Post, commit before OnAfterPostSalesDoc](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
- [Purch.-Post, OnAfterPostPurchaseDoc](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchPost.Codeunit.al).
- [Service-Post, preview error, commit and OnAfterPostServiceDoc](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Posting/ServicePost.Codeunit.al).
- [Bank Acc. Reconciliation Post, FinalizePost, OnAfterFinalizePost and the final commit](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Bank/Reconciliation/BankAccReconciliationPost.Codeunit.al).
- [Gen. Jnl.-Post Preview, IsActive](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Preview/GenJnlPostPreview.Codeunit.al).
