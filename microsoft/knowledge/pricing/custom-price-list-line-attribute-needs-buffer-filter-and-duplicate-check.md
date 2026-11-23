---
bc-version: [all]
domain: pricing
keywords: [price-list-line, price-calculation-buffer, onafterfillbuffer, onaftersetfilters, onaftersetassetfilters, duplicate-price-lines, onafterisimprovedline, tableextension, pricing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# A custom price list line attribute needs a buffer field, a filter and a duplicate check

## Description

Price list lines can be made to depend on an extra attribute of the document line, such as a sales channel. The standard line already depends on currency, unit of measure, variant and dates. The calculation never reads the document line directly. `Sales Line - Price`.`CopyToBuffer` fills the `Price Calculation Buffer` (a table with `TableType = Temporary`). `Price Calculation Buffer Mgt.`.`SetFiltersOnPriceListLine` then sets the filters on `Price List Line` and saves them. `RestoreFilters` puts them back before each source is searched, so filters added in its event apply to every source and level.

Three standard places ignore a new attribute:
- The buffer. `OnAfterFillBuffer` on `Sales Line - Price` passes `var PriceCalculationBuffer` with the header and line. `Purchase Line - Price` and `Job Planning Line - Price` publish their own `OnAfterFillBuffer`.
- The best-line choice. Among lines on the same level, `Price Calculation - V16` keeps the lowest amount. Only for `Currency Code` and `Variant Code` does it prefer a specific line over a blank one, through `IsImprovedLine` and `IsDegradedLine`. A cheaper generic line beats a specific one unless an extension says otherwise.
- Duplicate detection. When a price list is activated, `Price List Management` finds duplicates with `SetHeadersFilters` and `SetAssetFilters`. Lines that differ only in the new attribute are reported as duplicates, and the user is asked to remove one.

## Best Practice

Plan the attribute end to end:
1. Add the field to `Price List Line`, `Price Worksheet Line` (same number), `Price Calculation Buffer` and the document line.
2. Fill the buffer field in `OnAfterFillBuffer` of each line type in scope.
3. In `OnAfterSetFilters` of `Price Calculation Buffer Mgt.`, filter with `SetFilter(Field, '%1|%2', Value, '')`, so lines without the attribute stay generic. This is the same shape the buffer uses for currency and unit of measure.
4. If a specific line must win over a cheaper generic one, set `Result` in `OnAfterIsImprovedLine` and `OnAfterIsDegradedLine` of `Price Calculation - V16`.
5. Add the attribute to the duplicate filters in `OnAfterSetAssetFilters` of `Price List Management`.
6. Recalculate when the attribute changes on the document line; see [a new price source needs a recalculation trigger](../data-modeling/new-price-source-must-add-candidate-and-trigger-recalculation.md).

See sample: [`custom-price-list-line-attribute-needs-buffer-filter-and-duplicate-check.good.al`](custom-price-list-line-attribute-needs-buffer-filter-and-duplicate-check.good.al).

## Anti Pattern

Filter with `SetRange(Field, Value)`. Every price list line without the attribute disappears from the calculation, and documents without a channel find no prices at all. Another trap is to filter correctly but skip the duplicate filters. Activating a price list with the same item at two channels then opens the `Duplicate Price Lines` page and asks the user to remove one of two valid lines. A third is to model the attribute as a new price source. A source changes priority levels and needs the enum work in [extend Price Source Type](../data-modeling/extend-price-source-type-must-sync-document-subset-enum.md), while an attribute only narrows the lines.

See sample: [`custom-price-list-line-attribute-needs-buffer-filter-and-duplicate-check.bad.al`](custom-price-list-line-attribute-needs-buffer-filter-and-duplicate-check.bad.al).

## References

- [Price Calculation Buffer (TableType = Temporary)](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Calculation/PriceCalculationBuffer.Table.al).
- [Price Calculation Buffer Mgt.: SetFiltersOnPriceListLine, RestoreFilters, OnAfterSetFilters](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Calculation/PriceCalculationBufferMgt.Codeunit.al).
- [Sales Line - Price: CopyToBuffer, FillBuffer, OnAfterFillBuffer](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Pricing/SalesLinePrice.Codeunit.al).
- [Price Calculation - V16: IsImprovedLine, IsDegradedLine and their events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Calculation/PriceCalculationV16.Codeunit.al).
- [Price List Management: SetAssetFilters, ResolveDuplicatePrices](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/PriceList/PriceListManagement.Codeunit.al).
