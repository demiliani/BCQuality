---
bc-version: [all]
domain: sales-purchase
keywords: [onafterpostsalesdoc, sales-post, commit, previewmode, commitissuppressed, posting-preview, job-queue, follow-up-processing, side-effects]
technologies: [al]
countries: [w1]
application-area: [all]
---

# OnAfterPostSalesDoc runs after the posting commit

## Description

In normal sales posting, `Sales-Post` calls `Commit()` after finalizing the posted documents and entries, and only then raises `OnAfterPostSalesDoc`. An error raised by a subscriber at that point does not undo the posting. The posted invoice and its entries stay, and the subscriber's own work is left half done.

The commit is skipped when `PreviewMode`, `CommitIsSuppressed` or inventory pick and put-away posting is in effect. In those cases the subscriber runs inside the caller's transaction. During posting preview, that transaction is rolled back afterwards, but anything the subscriber did outside the database, such as an HTTP call or an email, has already happened.

## Best Practice

Treat `OnAfterPostSalesDoc` as follow-up processing, not as part of posting:

- Put rules that must stop posting before posting writes anything, for example in a check that runs before the posting routine starts.
- Exit on `PreviewMode` before any external side effect.
- Do not call `Commit()` in the subscriber. When `CommitIsSuppressed` is true, the caller owns the transaction.
- Move calls to external services out of the subscriber. Insert an outbox row and let a recurring job queue entry send it, as [HttpClient inside a write transaction holds locks](../performance/httpclient-inside-write-transaction-holds-locks.md) describes. When `CommitIsSuppressed` is true, the row then commits or rolls back with the caller's transaction. Make the call idempotent, as [job queue external effects must be idempotent](../performance/job-queue-external-effects-must-be-idempotent.md) requires.

Use the posted document numbers passed by the event, such as `SalesInvHdrNo`, to identify what was posted.

See sample: [`onafterpostsalesdoc-runs-after-the-posting-commit.good.al`](onafterpostsalesdoc-runs-after-the-posting-commit.good.al).

## Anti Pattern

Call an external service directly from the subscriber, ignore `PreviewMode`, and raise an error when the call fails, expecting the posting to roll back. Users who only preview the posting trigger the external call. When the call fails after a real posting, the invoice is already posted and the error only confuses the user.

See sample: [`onafterpostsalesdoc-runs-after-the-posting-commit.bad.al`](onafterpostsalesdoc-runs-after-the-posting-commit.bad.al).

## References

- [Sales-Post, Commit before OnAfterPostSalesDoc](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
- [Preview posting results](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-how-preview-post-results).
- [Job queue](https://learn.microsoft.com/en-us/dynamics365/business-central/admin-job-queues-schedule-tasks).
