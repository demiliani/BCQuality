---
bc-version: [all]
domain: sales-purchase
keywords: [onafterpostpurchasedoc, purch-post, previewmode, posting-preview, gen-jnl-post-preview, isactive, commitissupressed, follow-up-processing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# OnAfterPostPurchaseDoc has no PreviewMode parameter

## Description

`Purch.-Post` raises `OnAfterPostPurchaseDoc` after its commit step, like `Sales-Post` raises `OnAfterPostSalesDoc`. In normal posting the commit has already happened, so an error in a subscriber does not undo the posting. During posting preview, or when commit is suppressed, there is no commit and the subscriber runs inside the transaction that preview later rolls back.

Unlike the sales event, `OnAfterPostPurchaseDoc` does not pass a `PreviewMode` parameter. Its last parameter is `CommitIsSupressed`, spelled with one "s". A subscriber copied from a sales design cannot test `PreviewMode`, and `CommitIsSupressed` is not a substitute: it is also true when another process posts with commit suppressed, outside preview.

## Best Practice

Detect preview with `"Gen. Jnl.-Post Preview".IsActive()`, which reports whether a posting preview is running for any document type. Exit before any external side effect when it returns true. The other rules for after-posting subscribers apply unchanged; see [OnAfterPostSalesDoc runs after the posting commit](onafterpostsalesdoc-runs-after-the-posting-commit.md). In short: do not call `Commit()`, do not rely on rollback, and hand external calls to an outbox processed by a recurring job queue entry.

When a design subscribes to after-posting events for both sales and purchases, plan the preview guard separately for each. Confirm each event's parameters in the target version's symbols instead of copying one subscriber's signature to the other.

See sample: [`onafterpostpurchasedoc-has-no-previewmode-parameter.good.al`](onafterpostpurchasedoc-has-no-previewmode-parameter.good.al).

## Anti Pattern

Declare a `PreviewMode` parameter on an `OnAfterPostPurchaseDoc` subscriber, which does not match the publisher. Or skip the guard because the purchase event offers none, so a posting preview triggers the external call.

See sample: [`onafterpostpurchasedoc-has-no-previewmode-parameter.bad.al`](onafterpostpurchasedoc-has-no-previewmode-parameter.bad.al).

## References

- [Purch.-Post, OnAfterPostPurchaseDoc after the commit step](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchPost.Codeunit.al).
- [Gen. Jnl.-Post Preview, IsActive](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Finance/GeneralLedger/Preview/GenJnlPostPreview.Codeunit.al).
