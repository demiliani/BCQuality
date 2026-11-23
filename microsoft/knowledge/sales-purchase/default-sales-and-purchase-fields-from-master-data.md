---
bc-version: [all]
domain: sales-purchase
keywords: [sales-header, purchase-header, sales-line, purchase-line, onaftercopyselltocustomeraddressfieldsfromcustomer, onaftersetfieldsbilltocustomer, onaftercopybuyfromvendorfieldsfromvendor, onaftercopypaytovendorfieldsfromvendor, onafterassignitemvalues, default-values]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Default sales and purchase fields from customer, vendor and item

## Description

When a user validates the customer or vendor on a document header, the header copies its defaults from the master record field by field, then raises an event. The events differ by party and by side:

| Party validated | Copy point | Event |
| --- | --- | --- |
| Sales `Sell-to Customer No.` | `CopySellToCustomerAddressFieldsFromCustomer` | `OnAfterCopySellToCustomerAddressFieldsFromCustomer` on `Sales Header` |
| Sales `Bill-to Customer No.` | `SetBillToCustomerAddressFieldsFromCustomer` | `OnAfterSetFieldsBilltoCustomer` on `Sales Header` |
| Purchase `Buy-from Vendor No.` | field `OnValidate` | `OnAfterCopyBuyFromVendorFieldsFromVendor` on `Purchase Header` |
| Purchase `Pay-to Vendor No.` | field `OnValidate` | `OnAfterCopyPayToVendorFieldsFromVendor` on `Purchase Header` |

On lines, validating `No.` for an item runs `CopyFromItem`, which ends with `OnAfterAssignItemValues` on `Sales Line` or `Purchase Line`. The two line events have the same name but different parameters: the sales one passes `SalesHeader`, `xSalesLine` and `CurrentFieldNo`, the purchase one passes `CurrentFieldNo` and `PurchHeader`.

## Best Practice

Pick the event by the party the value belongs to. Delivery and contact data follows the sell-to or buy-from party. Payment, pricing and posting data follows the bill-to or pay-to party, because it can differ from the sell-to or buy-from party and is set again when it changes. Copy the value in the subscriber with a plain assignment, from the master record the event passes.

For a line default from the item, subscribe to `OnAfterAssignItemValues` on the line table of each side, and declare only the parameters you use, with the names that side's publisher declares. Header defaults that every new line should inherit belong in the document's own initialization; see [initialize document defaults in InitRecord](../data-modeling/initialize-document-defaults-in-initrecord.md).

See sample: [`default-sales-and-purchase-fields-from-master-data.good.al`](default-sales-and-purchase-fields-from-master-data.good.al).

## Anti Pattern

Copy master data from the page, in `OnAfterValidate` of the customer field on the order page. Documents created from code, APIs, Copy Document or other pages never get the value. Copying a payment-related default on the sell-to event is also wrong: when bill-to differs from sell-to, the document carries the wrong party's value.

See sample: [`default-sales-and-purchase-fields-from-master-data.bad.al`](default-sales-and-purchase-fields-from-master-data.bad.al).

## References

- [Sales Header, sell-to and bill-to copy routines](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesHeader.Table.al).
- [Purchase Header, buy-from and pay-to copy events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/PurchaseHeader.Table.al).
- [Sales Line, CopyFromItem and OnAfterAssignItemValues](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al).
- [Purchase Line, CopyFromItem and OnAfterAssignItemValues](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/PurchaseLine.Table.al).
