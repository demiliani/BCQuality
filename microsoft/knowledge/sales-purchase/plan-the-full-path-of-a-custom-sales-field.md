---
bc-version: [all]
domain: sales-purchase
keywords: [sales-header, sales-line, sales-post, posted-document, cust-ledger-entry, item-ledger-entry, gen-journal-line, item-journal-line, tableextension, feature-design]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan the full path of a custom sales field before building it

## Description

A field added to `Sales Header` or `Sales Line` does not travel through posting on its own. Sales posting moves data along several distinct mechanisms, and each one needs a different extension step. Some stages copy by field number, some copy field by field and expose an event, and the last stage commits before follow-up subscribers run.

A plan that only says "add the field and show it on the posted invoice" misses most of that path. The defects show up later as blank values on shipments, credit memos, archives or ledger entries, or as subscribers that patch posted entries.

## Best Practice

Before writing code, decide which stages the field must reach and plan one step per stage. Use this map for sales documents:

| Stage the field must reach | Mechanism in standard posting | Extension step |
| --- | --- | --- |
| Posted shipment, invoice, credit memo and return receipt headers; `Sales Header Archive` | `TransferFields` from `Sales Header` | Same field number and type on every target table. See [mirror sales fields on every TransferFields target](mirror-sales-fields-on-every-transferfields-target.md) |
| Posted lines and `Sales Line Archive` | `InitFromSalesLine` and archiving call `TransferFields` from `Sales Line` | Same rule, on the line tables |
| `Cust. Ledger Entry`, optionally `G/L Entry` | Field-by-field copy into `Gen. Journal Line`, then into the entry | Two subscribers. See [carry sales fields to the customer ledger](carry-sales-fields-to-customer-ledger-through-the-journal-line.md) |
| `Item Ledger Entry` | Field-by-field copy into `Item Journal Line`, then into the entry | Two subscribers. See [carry sales line fields to the item ledger](carry-sales-line-fields-to-item-ledger-through-the-item-journal-line.md) |
| Follow-up work after posting (notifications, integrations) | `OnAfterPostSalesDoc` runs after the posting commit | Guard preview and do not rely on rollback. See [OnAfterPostSalesDoc runs after the posting commit](onafterpostsalesdoc-runs-after-the-posting-commit.md) |

For each stage the plan should also name the page extensions that show the field, the permission set entries for any new objects, and a test that posts a document and reads the value back from every target. Use the test libraries for this, as [use library codeunits for test fixtures](../testing/use-library-codeunits-for-test-fixtures.md) describes.

Purchase documents follow the same map with their own tables and events: see [mirror purchase fields](mirror-purchase-fields-on-every-transferfields-target.md), [carry purchase fields to the vendor ledger](carry-purchase-fields-to-vendor-ledger-through-the-journal-line.md) and [OnAfterPostPurchaseDoc has no PreviewMode parameter](onafterpostpurchasedoc-has-no-previewmode-parameter.md). Do not copy a sales subscriber to purchases without checking the purchase event's parameters.

Copy Document copies posted and archived headers back into `Sales Header` with `TransferFields`. A field mirrored on the posted tables therefore also flows back when a user copies a posted document. Decide in the plan whether that is wanted. If it is not, clear the field on `ToSalesHeader` in a subscriber to `OnAfterCopySalesHeaderDone` on `Copy Document Mgt.`, which runs after the header is copied from any source document.

## Anti Pattern

Plan only the tables the requester named, such as `Sales Header` and `Sales Invoice Header`. The shipment, credit memo, return receipt and archive tables then stay blank, and the gap only appears in production.

Plan to fill ledger entries after posting by finding and modifying them. Posted ledger entries are outputs of posting; see [do not modify or delete posted ledger entries](../finance/do-not-modify-or-delete-posted-ledger-entries.md).

## References

- [Sales-Post, posted header creation with TransferFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
- [Sales Post Invoice, customer journal line built with CopyFromSalesHeader](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPostInvoice.Codeunit.al).
- [Copy Document Mgt., headers copied back with TransferFields](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Utilities/CopyDocumentMgt.Codeunit.al).
