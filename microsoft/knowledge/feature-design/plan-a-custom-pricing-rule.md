---
bc-version: [all]
domain: feature-design
keywords: [feature-design, pricing, price-list-line, price-calculation, price-source, price-calculation-handler, price-worksheet, sales-line-price, purchase-line-price]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Plan a custom pricing rule

## Description

Requests such as "channel prices", "prices agreed with the parent company" or "show which agreement set the price" change how Business Central prices document lines. Since the new pricing experience, prices are `Price List Header` and `Price List Line` records. A `Line With Price` codeunit per document type (`Sales Line - Price`, `Purchase Line - Price`, `Job Planning Line - Price`) fills the `Price Calculation Buffer`, and the `Price Calculation` implementation chosen in `Price Calculation Setup` selects the line. By default this is `Price Calculation - V16`. A design that skips this structure tends to replace the calculation with its own query, and it then loses dates, levels, currency conversion, rounding and the price worksheet.

The old tables (`Sales Price`, `Sales Line Discount`, `Purchase Price`) and the `SalesPrices` feature key still exist in version 30.0. With the key off, the `Version 15.0` implementation reads the old tables. A pricing extension built on price lists must state that it requires the new experience.

## Best Practice

Plan one decision per row and open the linked articles before designing that part:

| Decision | What to settle | Knowledge |
| --- | --- | --- |
| Where the rule lives | Prefer price list data plus events of the standard calculation over code that computes prices | [selection by source level, then best price](../pricing/document-line-price-selection-runs-by-source-level-then-best-price.md) |
| Who the price is for | A new party (new source type) needs both enums with the same ID, a candidate in `OnAfterAddSources`, a level and a recalculation trigger | [extend Price Source Type with the subset enum](../data-modeling/extend-price-source-type-must-sync-document-subset-enum.md), [candidate and recalculation](../data-modeling/new-price-source-must-add-candidate-and-trigger-recalculation.md) |
| Extra condition on a price | An attribute that narrows lines needs a buffer field, a filter with a blank fallback, a best-line preference and a duplicate key | [custom price list line attribute](../pricing/custom-price-list-line-attribute-needs-buffer-filter-and-duplicate-check.md) |
| Different calculation method | Only a replacement engine justifies a new `Price Calculation Handler`, and it must register itself | [activate a handler through OnFindSupportedSetup](../data-modeling/activate-new-price-calculation-handler-via-onfindsupportedsetup.md) |
| Values shown on documents | Copy fields of the applied line in `OnAfterSetPrice`, with amount-type and fallback guards | [copy applied price list line fields](../pricing/copy-applied-price-list-line-fields-in-onaftersetprice.md) |
| Documents in scope | Sales, purchase and project lines use different price types, sources, events and amount fields | [purchase and project prices](../pricing/purchase-and-project-prices-use-their-own-price-type-sources-and-fields.md) |
| Price list maintenance | Create lines from header defaults and activate through the `Status` validation | [create price lists from code](../pricing/create-price-lists-from-code-through-header-defaults-and-status-validation.md) |
| Worksheets and copy | Mirror custom fields on `Price Worksheet Line` by field number and fill them in suggest and copy events | [worksheet and copy lines](../pricing/price-worksheet-and-copy-lines-carry-custom-fields-by-field-number.md) |
| Amounts computed in code | Round to the currency's unit-amount precision and respect `Prices Including VAT` | [round calculated unit prices](../data-modeling/round-calculated-unit-prices-to-unit-amount-precision.md), [prices follow Prices Including VAT](../data-modeling/document-line-prices-follow-prices-including-vat.md) |
| Tests | Enable the new calculation with `Library - Price Calculation`, create lists with its helpers, activate them, and test both a winning and a losing candidate | [create price lists from code](../pricing/create-price-lists-from-code-through-header-defaults-and-status-validation.md) |

Whether a new rule should outrank existing customer or project prices is a business decision. When the request does not say so, raise it as an open question instead of choosing a level.

## Anti Pattern

Subscribe to `OnUpdateUnitPriceOnBeforeFindPrice` with `IsHandled` and compute the price from a custom table, or store rule data in fields that only the price list page shows. The rule ignores the price list status, levels and dates, does not appear in the price worksheet, and works for sales only.

## References

- [Pricing calculation objects](https://github.com/microsoft/BCApps/tree/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing).
- [Price Calculation Mgt.: IsExtendedPriceCalculationEnabled](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Calculation/PriceCalculationMgt.Codeunit.al).
- [Extending price calculations](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extending-best-price-calculations).
