---
bc-version: [all]
domain: pricing
keywords: [price-list-line, onaftersetprice, sales-line-price, purchase-line-price, job-planning-line-price, isrealline, amount-type, tableextension, pricing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Copy fields of the applied price list line in OnAfterSetPrice

## Description

The price calculation selects a `Price List Line` and hands it to `SetPrice` of the `Line With Price` codeunit. `SetPrice` assigns only named fields, such as `Unit Price`, `Allow Line Disc.` and `Allow Invoice Disc.` on a sales line, `Direct Unit Cost` on a purchase line, or `Line Discount %` for a discount. A custom field on the price list line never reaches the document line on its own.

`SetPrice` ends with `OnAfterSetPrice`, which is the only event that receives the applied price list line together with the document line:
- `Sales Line - Price`: `OnAfterSetPrice(var SalesLine; PriceListLine; AmountType; var SalesHeader)`.
- `Purchase Line - Price`: `OnAfterSetPrice(var PurchaseLine; PriceListLine; AmountType; CurrPriceType; var PurchaseHeader)`.
- `Job Planning Line - Price`: `OnAfterSetPrice(var JobPlanningLine; PriceListLine; AmountType; CurrPriceType)`.

The line in the codeunit is a copy. `GetLineWithCalculatedPrice` assigns it back to the document line after the calculation, so values set in the subscriber arrive on the line without a `Modify`. The event runs for the automatic calculation and for the Get Price lookup (`Pick`).

The event needs guards. It runs once for `AmountType` `Discount` and once for `Price`, possibly with two different price list lines. When no line is found, `FillBestLine` passes a filled fallback record whose `IsRealLine` returns false (`Line No.` 0), so its custom fields are blank. On sales lines of type Resource, the same codeunit also runs with the `Purchase` price type to get the unit cost. `SetPrice` for the price is skipped when `IsPriceUpdateNeeded` returns false, for example when nothing is found and `Quantity` or `Variant Code` changed.

## Best Practice

Add the field to `Price List Line` and to the document line, and copy it in `OnAfterSetPrice`. Copy only for the amount type the field belongs to, check `PriceListLine."Price Type"` on documents that compute costs too, and decide what a fallback line (`IsRealLine` false) means. Usually it means "clear the value", because the price no longer comes from a price list. Add the same field with the same number to `Price Worksheet Line`, so the worksheet keeps it; see [price worksheet and copy lines carry custom fields](price-worksheet-and-copy-lines-carry-custom-fields-by-field-number.md).

See sample: [`copy-applied-price-list-line-fields-in-onaftersetprice.good.al`](copy-applied-price-list-line-fields-in-onaftersetprice.good.al).

## Anti Pattern

Subscribe to `OnAfterApplyPrice` or `OnAfterUpdateUnitPrice` on `Sales Line` and look up the price list line again with filters on asset and source. These events do not receive the applied line, and the lookup does not repeat source levels, minimum quantity, currency or the best-price choice, so it can return a different line. Copying without checking `AmountType` lets the discount line overwrite the value taken from the price line.

See sample: [`copy-applied-price-list-line-fields-in-onaftersetprice.bad.al`](copy-applied-price-list-line-fields-in-onaftersetprice.bad.al).

## References

- [Sales Line - Price: SetPrice and OnAfterSetPrice](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Pricing/SalesLinePrice.Codeunit.al).
- [Purchase Line - Price: SetPrice and OnAfterSetPrice](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Pricing/PurchaseLinePrice.Codeunit.al).
- [Job Planning Line - Price: SetPrice and OnAfterSetPrice](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Planning/JobPlanningLinePrice.Codeunit.al).
- [Price Calculation - V16: ApplyPrice, ApplyDiscount, Pick](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Calculation/PriceCalculationV16.Codeunit.al).
- [Price List Line: IsRealLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/PriceList/PriceListLine.Table.al).
- [Sales Line: GetLineWithCalculatedPrice, ApplyResUnitCost](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al).
