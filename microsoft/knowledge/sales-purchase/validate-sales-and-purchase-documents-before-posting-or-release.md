---
bc-version: [all]
domain: sales-purchase
keywords: [onafterchecksalesdoc, onaftercheckpurchdoc, onchecksalespostrestrictions, oncheckpurchasepostrestrictions, onchecksalesreleaserestrictions, oncheckpurchasereleaserestrictions, posting-preview, errormessagemgt, release-document]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Validate sales and purchase documents before posting or release

## Description

Sales and purchase posting offer three standard places for a custom "cannot post or release unless" rule. They differ in when they run:

| Hook | Raised by | Runs in posting preview |
| --- | --- | --- |
| `OnAfterCheckSalesDoc` / `OnAfterCheckPurchDoc` | `Sales-Post` / `Purch.-Post`, at the end of the document check | Yes; it receives `PreviewMode` and `ErrorMessageMgt` |
| `OnCheckSalesPostRestrictions` / `OnCheckPurchasePostRestrictions` | The header's `Check...PostRestrictions`, from the posting codeunit's post-restriction check | No: called only when not in preview |
| `OnCheckSalesReleaseRestrictions` / `OnCheckPurchaseReleaseRestrictions` | The header's `Check...ReleaseRestrictions`, from `Release Sales Document` / `Release Purchase Document` | No: skipped in preview and when release restrictions are skipped |

The restriction events are declared with `IncludeSender`, so the subscriber receives the header as `Sender`. The release restriction check also runs before the approval check, and posting releases an open document, so a release rule also stops posting an open document outside preview.

## Best Practice

Put a rule that must stop every posting, including its preview, in `OnAfterCheckSalesDoc` or `OnAfterCheckPurchDoc`. The check phase runs before any entry is written, and the event passes `ErrorMessageMgt`, which the standard checks use to collect errors such as `LogContextFieldError`. Put a rule about releasing the document, such as a required field before the order goes to the warehouse, in the release restriction event of that side. Use the post restriction events only for rules that must not block preview.

Raise errors that tell the user what to fix; see [prefer ErrorInfo for actionable errors](../error-handling/prefer-errorinfo-for-actionable-errors.md).

See sample: [`validate-sales-and-purchase-documents-before-posting-or-release.good.al`](validate-sales-and-purchase-documents-before-posting-or-release.good.al).

## Anti Pattern

Check the rule in the page action that starts posting, or after posting in `OnAfterPostSalesDoc`. A page check is skipped by batch posting, job queue posting, APIs and any code that posts. A check after posting runs after the commit, so the document is already posted when it fails; see [OnAfterPostSalesDoc runs after the posting commit](onafterpostsalesdoc-runs-after-the-posting-commit.md). Taking over a standard check with `IsHandled` instead of adding to it is covered by [do not bypass critical operations with IsHandled](../events/do-not-bypass-critical-operations-with-ishandled.md).

See sample: [`validate-sales-and-purchase-documents-before-posting-or-release.bad.al`](validate-sales-and-purchase-documents-before-posting-or-release.bad.al).

## References

- [Sales-Post, CheckSalesDocument and post restrictions](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
- [Purch.-Post, OnAfterCheckPurchDoc and post restrictions](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Posting/PurchPost.Codeunit.al).
- [Release Sales Document, release restrictions](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/ReleaseSalesDocument.Codeunit.al).
- [Release Purchase Document, release restrictions](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/ReleasePurchaseDocument.Codeunit.al).
