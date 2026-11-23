---
bc-version: [all]
domain: pricing
keywords: [purchase-line-price, job-planning-line-price, price-type, direct-unit-cost, unit-cost, purchase-price-source-type, job-price-source-type, project-prices, price-list-header, pricing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Purchase and project prices use their own price type, sources and amount fields

## Description

The price list model is shared, but each document reads a different slice of it. A design that only covers sales misses these differences:
- Price type. `Purchase Line` asks for `Price Type` Purchase, and `Sales Line - Price` adds the sources for `Sale`. `Job Planning Line`.`FindPriceAndDiscount` calls `ApplyPrice` twice, for `Sale` and for `Purchase`, and calls `ApplyDiscount` only for `Sale`. A sales line of type Resource also runs a `Purchase` calculation to get `Unit Cost (LCY)`.
- Sources. `Purchase Line - Price` adds `All Vendors`, `Vendor` (Buy-from Vendor), `Contact` and `Campaign`. The purchase subset enum `Purchase Price Source Type` has the values 20, 21, 50 and 51. Project sources (`All Jobs`, `Job`, `Job Task`, enum `Job Price Source Type` 30 to 32) come from `AddJobAsSources` on higher levels. A purchase line adds them whenever it has a project number, but a sales line adds them only on invoices. `Job Planning Line - Price` takes the customer from the project, or from the project task when `Task Billing Method` is not "One customer".
- Amount fields. `Price List Line` has `Unit Price` for sales, `Direct Unit Cost` for purchases, and `Unit Cost` for costs. `Cost Factor` is for project sales prices, and its validation tests that `Source Group` is Job. `Purchase Line - Price`.`SetPrice` copies `Direct Unit Cost`. `Job Planning Line - Price` copies `Unit Price` and `Cost Factor` for `Sale`. For `Purchase` it copies `Direct Unit Cost (LCY)` for items, both `Unit Cost` and `Direct Unit Cost (LCY)` for resources, and `Unit Cost`, or else `Direct Unit Cost`, for G/L accounts.
- Order and guards. A purchase line applies the price before the discount, a sales line the discount before the price. `Purchase Line - Price`.`IsPriceUpdateNeeded` returns false when `Prepmt. Amt. Inv.` is not zero.
- Price list headers. Validating `Source Type` derives `Price Type` and `Source Group` for customer and vendor sources. A project price list has `Source Group` Job and can be a sale or a purchase list, so `Price Type` must be set before `Source Type` is validated. The number series comes from `Sales & Receivables Setup`, `Purchases & Payables Setup` or `Jobs Setup`, by source group. `Allow Editing Active Price` is read from the sales or the purchase setup, by price type.

## Best Practice

For each document in scope, name the price type, the `Line With Price` codeunit and the amount field that the rule changes. Subscribe to that codeunit's own events, such as `OnAfterAddSources`, `OnAfterFillBuffer` and `OnAfterSetPrice`, because the sales, purchase and project codeunits each publish their own, with different parameters. Write purchase prices to `Direct Unit Cost` and project cost prices to `Unit Cost`. Set `Price Type` explicitly when creating project price lists; see [create price lists from code](create-price-lists-from-code-through-header-defaults-and-status-validation.md). A new source type must extend the matching subset enum; see [extend Price Source Type with the document subset enum](../data-modeling/extend-price-source-type-must-sync-document-subset-enum.md).

See sample: [`purchase-and-project-prices-use-their-own-price-type-sources-and-fields.good.al`](purchase-and-project-prices-use-their-own-price-type-sources-and-fields.good.al).

## Anti Pattern

Reuse a sales subscriber for purchases by writing `Unit Price` on a purchase price list line, or subscribe only to `Sales Line - Price` for a rule that the request also applies to purchase or project lines. The purchase calculation reads `Direct Unit Cost`, finds zero or the fallback item cost, and the rule does nothing for purchases. A project price list created with only `Validate("Source Type", Job)` keeps the `Price Type` it had before, often `Any`, and is never found.

See sample: [`purchase-and-project-prices-use-their-own-price-type-sources-and-fields.bad.al`](purchase-and-project-prices-use-their-own-price-type-sources-and-fields.bad.al).

## References

- [Purchase Line - Price: AddSources, FillBuffer, SetPrice, IsPriceUpdateNeeded](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Pricing/PurchaseLinePrice.Codeunit.al).
- [Purchase Line: UpdateDirectUnitCostByField](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/PurchaseLine.Table.al).
- [Job Planning Line - Price: AddSources, SetPrice](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Planning/JobPlanningLinePrice.Codeunit.al).
- [Job Planning Line: FindPriceAndDiscount, ApplyPrice](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Planning/JobPlanningLine.Table.al).
- [Purchase Price Source Type](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Pricing/PurchasePriceSourceType.Enum.al), [Job Price Source Type](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Projects/Project/Pricing/JobPriceSourceType.Enum.al).
- [Price List Header: GetNoSeries, CopyFrom(Price Source)](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/PriceList/PriceListHeader.Table.al).
