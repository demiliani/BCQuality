---
bc-version: [all]
domain: pricing
keywords: [price-worksheet-line, price-list-line, transferfields, implementnewprices, copylines, addlines, suggest-price-lines, tableextension, field-number, pricing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Price worksheet and copy lines carry custom fields by field number

## Description

Users maintain prices in bulk with the `Price Worksheet` page and the Suggest Lines and Copy Lines actions on price lists. These actions run `Price List Management` and move data in three different ways:
- Price worksheet: `CopyToWorksheetLine` and `InsertWorksheetLine` fill `Price Worksheet Line` with `TransferFields` from `Price List Line`. `ImplementNewPrices` moves the rows back with `PriceListLine.TransferFields(PriceWorksheetLine)`, inserts or modifies the price list lines (a modified line is set to Draft), and then activates them with `ActivateDraftLines`. The worksheet line repeats the price list line fields with the same numbers (1 to 37) and adds its own from 100.
- Copy Lines (`CopyLines`): `CopyLine` assigns the whole source record (`ToPriceListLine := FromPriceListLine`), then applies the target header with `CopyFrom(ToPriceListHeader, ForceDefaults)`.
- Suggest Lines (`AddLines`): `AddLine` builds a new line from the header and a `Price Asset`, so it starts without any custom value.

A custom field on `Price List Line` therefore survives Copy Lines, but it is lost on a round trip through the worksheet unless `Price Worksheet Line` has a field with the same number and a compatible type. Suggest Lines never fills it.

## Best Practice

Give every custom `Price List Line` field a twin on `Price Worksheet Line` with the same field number, name and type, and show it on the worksheet page. Fill values that Suggest Lines cannot know in `OnAddLineOnAfterPopulatePriceListLineFields`. Adjust copied values in `OnCopyLineOnAfterAdjustAmounts`, which runs for both the price list and the worksheet target, before the insert. Use `OnCopyToWorksheetLineOnBeforeInsert` for values that exist only on the worksheet line. Code that implements worksheet lines should call `ImplementNewPrices` and should not write `Price List Line` itself; the rules for direct writes are in [create price lists from code](create-price-lists-from-code-through-header-defaults-and-status-validation.md).

See sample: [`price-worksheet-and-copy-lines-carry-custom-fields-by-field-number.good.al`](price-worksheet-and-copy-lines-carry-custom-fields-by-field-number.good.al).

## Anti Pattern

Extend only `Price List Line`, or give the worksheet field a different number. The field compiles, works on the price list page and survives Copy Lines. After Implement Price Change, every line that went through the worksheet is written without its value. `ImplementNewPrice` reuses one `Price List Line` variable for all rows, so the field holds a blank or the value left from the previous row, and no error is shown.

See sample: [`price-worksheet-and-copy-lines-carry-custom-fields-by-field-number.bad.al`](price-worksheet-and-copy-lines-carry-custom-fields-by-field-number.bad.al).

## References

- [Price List Management: AddLine, CopyLine, CopyToWorksheetLine, InsertWorksheetLine, ImplementNewPrice](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/PriceList/PriceListManagement.Codeunit.al).
- [Price Worksheet Line](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Worksheet/PriceWorksheetLine.Table.al).
- [Price Worksheet page: SuggestLines, CopyLines, ImplementPriceChange actions](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Worksheet/PriceWorksheet.Page.al).
