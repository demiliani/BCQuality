---
bc-version: [all]
domain: shopify
keywords: [shopify-connector, shpfy-order-header, shpfy-order-attribute, shpfy-order-line-attribute, onaftercreatesalesheader, onaftercreateitemsalesline, shpfy-order-events, sales-header, sales-line, custom-attributes]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Carry Shopify order values to the created sales document

## Description

The Shopify Connector (app `Shopify Connector`, publisher `Microsoft`, id `ec255f57-31d0-4ca2-b751-f2fa7c745abb`) works in two steps. First, `Shpfy Import Order` reads the order from Shopify. It stores the order in `Shpfy Order Header` and `Shpfy Order Line`. It stores the order's custom attributes (note attributes) in `Shpfy Order Attribute`, keyed by `Order Id` and `Key`, with the text in `Attribute Value`. Line custom attributes go to `Shpfy Order Line Attribute`, keyed by `Order Id`, `Order Line Id` (the order line's `SystemId`) and `Key`. Then `Shpfy Process Order` builds the `Sales Header` and `Sales Line` records field by field. It does not use `TransferFields`, so a custom field on the Shopify tables never reaches the sales document without your code.

`Shpfy Order Events` (codeunit 30162) raises `OnAfterCreateSalesHeader(OrderHeader, var SalesHeader)` once the header is inserted and filled. This event fires even when a subscriber to `OnBeforeCreateSalesHeader` handled the creation. For each item, tip or gift-card line it raises `OnAfterCreateItemSalesLine(ShopifyOrderHeader, ShopifyOrderLine, SalesHeader, var SalesLine)`. At that point the sales line is already inserted. Your extension cannot add fields to the GraphQL order query, so read values the connector has already stored. Do not try to fetch the order again.

## Best Practice

Add the field to `Sales Header` (or `Sales Line`). Subscribe to `OnAfterCreateSalesHeader` and read the value from the Shopify order header or from `Shpfy Order Attribute` by the order id and key. Assign it to the sales header and call `Modify`, because the record already exists. For line values, subscribe to `OnAfterCreateItemSalesLine`. Read `Shpfy Order Line Attribute` with `ShopifyOrderLine.SystemId` and call `Modify` on the sales line. Shipping-cost lines have their own event, `OnAfterCreateShippingCostSalesLine`.

Values that come from the Shopify tables themselves can also be shown with a FlowField that looks up `Shpfy Order Header` through `Sales Header."Shpfy Order Id"`. That needs no subscriber, but the value is not stored and is not copied when the document is posted. A stored field reaches the posted documents through the standard `TransferFields`. See [mirror sales fields on every TransferFields target](../sales-purchase/mirror-sales-fields-on-every-transferfields-target.md).

The connector runs `Shpfy Process Order` with `Codeunit.Run`. If your subscriber raises an error, the order gets `Has Error` and the error text, and the sales document already created is deleted. So an error in a subscriber blocks the order but leaves no half-filled document. Do not `Commit` in the subscriber. Processing often runs in a job queue session, so do not use `Confirm` or pages; see [Shopify connector extension points](extend-the-shopify-connector-through-integration-events-and-public-objects.md).

See sample: [`carry-shopify-order-values-to-the-created-sales-document.good.al`](carry-shopify-order-values-to-the-created-sales-document.good.al).

## Anti Pattern

Subscribe to `Sales Header` `OnAfterInsertEvent` and look up the Shopify order through `"Shpfy Order Id"`. The connector inserts the header before it sets `Shpfy Order Id`, so the lookup finds nothing and the field stays blank. Writing the value from `OnAfterImportShopifyOrderHeader` is also wrong: no sales document exists yet at import time.

See sample: [`carry-shopify-order-values-to-the-created-sales-document.bad.al`](carry-shopify-order-values-to-the-created-sales-document.bad.al).

## References

- [Shpfy Order Events, the order and sales-document events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Order%20handling/Codeunits/ShpfyOrderEvents.Codeunit.al).
- [Shpfy Process Order, sales header and lines built field by field](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Order%20handling/Codeunits/ShpfyProcessOrder.Codeunit.al).
- [Shpfy Import Order, custom attributes stored per order and line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Order%20handling/Codeunits/ShpfyImportOrder.Codeunit.al).
- [Shpfy Order Attribute table](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Order%20handling/Tables/ShpfyOrderAttribute.Table.al).
- [Extend the Shopify Connector](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extending-shopify).
