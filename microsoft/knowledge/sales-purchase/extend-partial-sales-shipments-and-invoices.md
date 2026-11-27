---
bc-version: [all]
domain: sales-purchase
keywords: [partial-shipment, partial-invoicing, sales-post, qty-to-ship, qty-to-invoice, qty-shipped-not-invoiced, posted-sales-line, onbeforesalesshptlineinsert, onbeforesalesinvlineinsert]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Extend partial shipments and invoicing from a sales order

## Description

Business Central can ship and invoice a sales order separately or in the same posting. On `Sales Line`, `Quantity` is the ordered quantity; `Qty. to Ship` and `Qty. to Invoice` specify what to post in the current run. An invoice-only posting consumes shipped but not yet invoiced quantity. A ship-and-invoice posting can also invoice units shipped in that run. Each posted shipment or invoice line has its own `Quantity`, which can be smaller than the order quantity.

## Best Practice

When a feature needs to calculate or store a value for each posted line, subscribe to the event for the document that owns that value:

| Feature needs a value on | Event on `Sales-Post` | Quantity to use |
| --- | --- | --- |
| `Sales Shipment Line` | `OnBeforeSalesShptLineInsert` | `SalesShptLine.Quantity` for the units in this shipment line |
| `Sales Invoice Line` | `OnBeforeSalesInvLineInsert` | `SalesInvLine.Quantity` for the units in this invoice line |

Both events receive the initialized target line by `var` before the standard insert. Set the extension field on that record; leave `IsHandled` unchanged. Use the posted line's `Quantity (Base)` instead if the feature's rate is defined per base unit. Keep shipment and invoice calculations separate: invoicing part of a posted shipment does not produce another shipment.

See [`extend-partial-sales-shipments-and-invoices.good.al`](extend-partial-sales-shipments-and-invoices.good.al).

## Anti Pattern

Calculate points earned on an invoice line from the order quantity. An order for 10 shipped and invoiced in batches would then earn points for 10 units on every invoice, regardless of how many units that invoice actually covers.

See [`extend-partial-sales-shipments-and-invoices.bad.al`](extend-partial-sales-shipments-and-invoices.bad.al).

## Verification scenario

Order 10 units. Post **Ship** for 4, then **Invoice** for 2. Verify that the posted shipment line has quantity 4, the invoice line has quantity 2, and the order still has 6 outstanding and 2 shipped but not invoiced. Set `Qty. to Ship` to 3 and `Qty. to Invoice` to 5, then post **Ship and Invoice**. Verify that the second shipment line has quantity 3 and the second invoice line has quantity 5, covering both the 2 previously uninvoiced units and the 3 newly shipped units. At two points per unit, the invoice lines earn 4 and 10 points respectively.

## References

- [Microsoft Learn: Process partial shipments](https://learn.microsoft.com/en-us/dynamics365/business-central/sales-how-send-partial-shipments).
- [Base Application: Sales-Post](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Posting/SalesPost.Codeunit.al).
- [Base Application: Sales Shipment Line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/History/SalesShipmentLine.Table.al) and [Sales Invoice Line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/History/SalesInvoiceLine.Table.al), `InitFromSalesLine`.
