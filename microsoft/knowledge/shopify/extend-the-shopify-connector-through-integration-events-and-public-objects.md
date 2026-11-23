---
bc-version: [all]
domain: shopify
keywords: [shopify-connector, internalevent, access-internal, shpfy-order-events, shpfy-product-events, shpfy-customer-events, onbeforemapcustomer, onafterimportshopifyorderheader, allow-background-syncs, app-json-dependency]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Extend the Shopify Connector through integration events and public objects

## Description

A design that extends Shopify needs a dependency on the `Shopify Connector` app: id `ec255f57-31d0-4ca2-b751-f2fa7c745abb`, publisher `Microsoft`. Most of the connector's code cannot be called from another app. `Shpfy Process Order`, `Shpfy Process Orders`, `Shpfy Import Order`, `Shpfy Order Mapping` and `Shpfy Product Export` all have `Access = Internal`. A per-tenant extension also cannot change the GraphQL calls the connector sends.

The extension points are the event codeunits `Shpfy Order Events`, `Shpfy Product Events` and `Shpfy Customer Events`. Most of their publishers are `[IntegrationEvent]`. The procedures are declared `internal`, but that does not block subscribers. Some publishers are `[InternalEvent]`, and those can only be subscribed to from inside the connector. They include `OnBeforeMapCustomer`, `OnBeforeMapCompany` and the `OnBeforeConvertTo...` status events on `Shpfy Order Events`. They also include `OnAfterSetProductTitle` on `Shpfy Product Events`, and `OnBeforeFindCustomerTemplate`, `OnAfterFindCustomerTemplate` and `OnAfterFindMapping` on `Shpfy Customer Events`. A subscriber to one of these does not compile. The connector's own extensibility notes describe some of them as override points, but that does not make them reachable.

Shopify syncs often run in the background. When the shop has `Allow Background Syncs` turned on, the connector queues the sync report, for example `Shpfy Sync Orders from Shopify`, as a job queue entry. Order import and sales-document creation run each order through `Codeunit.Run`. An error marks that order with `Has Error` and the next order continues.

## Best Practice

Before you design, check that each event exists and is an `[IntegrationEvent]`. To choose the customer for an order, fill `Sell-to Customer No.` and `Bill-to Customer No.` on the Shopify order header in `OnAfterImportShopifyOrderHeader`. Built-in customer mapping runs only while `Bill-to Customer No.` is blank. To adjust the result of the built-in mapping, use `OnAfterMapCustomer` instead. To add an item to Shopify from code, call the public facade codeunit `Shpfy Product` (`AddItemToShopify`), not the internal export codeunits. Subscribers must not need UI and must not `Commit`; see [job queue handlers must not require UI](../performance/job-queue-handlers-must-not-require-ui.md). If an event you need is missing, ask for it in the BCApps repository. Do not copy connector code.

See sample: [`extend-the-shopify-connector-through-integration-events-and-public-objects.good.al`](extend-the-shopify-connector-through-integration-events-and-public-objects.good.al).

## Anti Pattern

A plan that subscribes to `OnBeforeMapCustomer` with `Handled := true`, or calls `Shpfy Process Order` to rebuild a sales document. Neither compiles in a separate app. Asking the user with `Confirm` inside an order event fails when the sync runs as a job queue entry. The difference between an `internal` procedure and an `[InternalEvent]` is explained in [treat local and internal events as subscriber contracts](../events/treat-local-and-internal-events-as-subscriber-contracts.md).

See sample: [`extend-the-shopify-connector-through-integration-events-and-public-objects.bad.al`](extend-the-shopify-connector-through-integration-events-and-public-objects.bad.al).

## References

- [Shopify Connector app.json](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/app.json).
- [Shpfy Order Events, integration and internal events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Order%20handling/Codeunits/ShpfyOrderEvents.Codeunit.al).
- [Shpfy Order Mapping, customer mapping only when Bill-to is blank](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Order%20handling/Codeunits/ShpfyOrderMapping.Codeunit.al).
- [Shpfy Customer Events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Customers/Codeunits/ShpfyCustomerEvents.Codeunit.al).
- [Shpfy Product, public facade](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Products/Codeunits/ShpfyProduct.Codeunit.al).
- [Shpfy Background Syncs, job queue entries per shop](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Apps/W1/Shopify/App/src/Base/Codeunits/ShpfyBackgroundSyncs.Codeunit.al).
- [Extend the Shopify Connector](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extending-shopify).
