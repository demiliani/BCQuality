---
bc-version: [all]
domain: pricing
keywords: [price-list-line, price-calculation-v16, line-with-price, price-source-list, onafteraddsources, setlevel, price-calculation-buffer, sales-line-price, lowest-price, pricing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# A document line price is selected by source level first, then by best price

## Description

`Sales Line`.`UpdateUnitPriceByField` gets a `Line With Price` implementation (`Sales Line - Price` by default) and asks `Price Calculation Mgt.`.`GetHandler` for the `Price Calculation` implementation named in `Price Calculation Setup`. With the standard setup this is `Price Calculation - V16`. The sales line calls `ApplyDiscount` and then `ApplyPrice`. `Purchase Line` calls `ApplyPrice` and then `ApplyDiscount`.

Each call copies the line into the temporary `Price Calculation Buffer` through `CopyToBuffer`. `Price Calculation Buffer Mgt.`.`SetFiltersOnPriceListLine` then filters `Price List Line` on line `Status` Active, `Price Type`, `Amount Type`, dates, currency and unit of measure. `FindLines` walks the `Price Source List` from the highest level down and stops at the first level that returns lines. Only inside that level does `CalcBestAmount` keep the cheapest line, after currency, unit of measure and VAT conversion. The chosen line reaches the document through `SetPrice` on the `Line With Price` codeunit.

Levels decide the outcome before amounts do. `Sales Line - Price` adds the customer, contact, campaign, price group and discount group sources at level 0. On a sales invoice with a project, `AddJobAsSources` adds `All Jobs`, `Job` and `Job Task` on levels 1 to 3. A project price therefore wins over a cheaper customer price. `OnAfterAddSources` runs after these calls, so `Price Source List`.`Add` in a subscriber uses whatever level was current. The same source can land on level 0 or on the project-task level, depending on the document.

The old tables `Sales Price`, `Sales Line Discount` and `Purchase Price` still exist in version 30.0 and are not obsolete. `IsExtendedPriceCalculationEnabled` still checks the `SalesPrices` feature key. When the key is off, `FindSetup` returns the `Business Central (Version 15.0)` implementation, which reads the old tables. Price list lines are then ignored.

## Best Practice

Change the result through the events of the calculation, and leave the selection to it:
- Add candidates in `OnAfterAddSources` of `Sales Line - Price`, `Purchase Line - Price` or `Job Planning Line - Price`. Call `PriceSourceList.SetLevel` before `Add`, so the priority of the new source is a design decision. Level 0 means "compete on price with the customer sources". Check the `PriceType` parameter first: `Sales Line - Price` also runs with `Purchase` for the unit cost of resource lines, and `Price Source List` raises an error when a customer source is added to a purchase list.
- Narrow the candidate lines in `OnAfterSetFilters` of `Price Calculation Buffer Mgt.`; see [add a custom filter attribute](custom-price-list-line-attribute-needs-buffer-filter-and-duplicate-check.md).
- Change the choice between found lines in `OnAfterIsBetterLine`, `OnAfterIsImprovedLine` or `OnAfterCalcBestAmount` of `Price Calculation - V16`.
- Read the applied line in `OnAfterSetPrice`; see [carry price list line fields](copy-applied-price-list-line-fields-in-onaftersetprice.md).

A new source type also needs the enum work in [extend Price Source Type with the document subset enum](../data-modeling/extend-price-source-type-must-sync-document-subset-enum.md), and the recalculation trigger in [a new price source needs a candidate and a recalculation trigger](../data-modeling/new-price-source-must-add-candidate-and-trigger-recalculation.md). A replacement engine is a new `Price Calculation Handler`; see [activate a new handler through OnFindSupportedSetup](../data-modeling/activate-new-price-calculation-handler-via-onfindsupportedsetup.md). Tests bind `Library - Price Calculation` and call `EnableExtendedPriceCalculation`, because the feature key decides which engine runs.

See sample: [`document-line-price-selection-runs-by-source-level-then-best-price.good.al`](document-line-price-selection-runs-by-source-level-then-best-price.good.al).

## Anti Pattern

Set `IsHandled` in `OnUpdateUnitPriceOnBeforeFindPrice` and read `Price List Line` with a custom query. The query skips line status, ending dates, minimum quantity, levels and the currency, unit of measure and VAT conversion of the buffer, and it skips rounding too; see [round calculated unit prices](../data-modeling/round-calculated-unit-prices-to-unit-amount-precision.md). Another trap is to add a source in `OnAfterAddSources` without `SetLevel` and to expect the lowest price to win. On project invoices, the source then outranks or competes with sources other than the ones that were planned.

See sample: [`document-line-price-selection-runs-by-source-level-then-best-price.bad.al`](document-line-price-selection-runs-by-source-level-then-best-price.bad.al).

## References

- [Sales Line: UpdateUnitPriceByField, GetPriceCalculationHandler, ApplyPrice](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/SalesLine.Table.al).
- [Price Calculation - V16: FindLines, CalcBestAmount, PickBestLine and events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Calculation/PriceCalculationV16.Codeunit.al).
- [Price Calculation Buffer Mgt.: SetFiltersOnPriceListLine, OnAfterSetFilters](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Calculation/PriceCalculationBufferMgt.Codeunit.al).
- [Price Calculation Mgt.: GetHandler, FindSetup, IsExtendedPriceCalculationEnabled](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Calculation/PriceCalculationMgt.Codeunit.al).
- [Sales Line - Price: AddSources, AddCustomerSources, OnAfterAddSources](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Pricing/SalesLinePrice.Codeunit.al).
- [Price Source List: SetLevel, IncLevel, AddJobAsSources](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Source/PriceSourceList.Codeunit.al).
- [Extending price calculations](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extending-best-price-calculations).
