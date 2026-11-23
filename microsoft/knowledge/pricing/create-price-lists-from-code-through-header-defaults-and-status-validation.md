---
bc-version: [all]
domain: pricing
keywords: [price-list-header, price-list-line, price-status, allow-updating-defaults, activatedraftlines, allow-editing-active-price, copyfrom, price-list-management, pricing]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Create price lists from code through header defaults and the Status validation

## Description

A price list is a `Price List Header` with `Price List Line` records, and each line has its own `Status` and `Price Type`. The calculation filters on the line fields, not the header: `SetFiltersOnPriceListLine` and `CalcBestAmount` both keep only lines with `Status` Active and with the `Price Type` of the document. A line inserted with assigned fields keeps the enum defaults, `Price Type` Any and `Status` Draft, so it is never found.

The header fills the line. `CopyFrom(PriceListHeader)` sets `Price Type`, `Status` Draft and the discount and VAT defaults. While `Allow Updating Defaults` is off it also copies the source, dates and currency, and the line validations then test that these values equal the header. Validating `Asset Type` calls `InitHeaderDefaults`, which runs the same `CopyFrom` when the header exists. On the header, validating `Source Type` sets `Price Type` and `Source Group` from the source for customers and vendors. For project price lists, set `Price Type` first, because the project group does not derive it.

Activation is a validation. `Validate(Status, Status::Active)` on the header runs `UpdateStatus`: it verifies the source and every line, resolves duplicate prices, and copies the status to all lines with `ModifyAll`. `ResolveDuplicatePrices` opens the `Duplicate Price Lines` page when duplicates exist. The confirmation uses `Confirm Management`.`GetResponseOrDefault`, which takes Yes when no UI is available.

Editing an active line also changes its status. When `Allow Editing Active Price` is on in `Sales & Receivables Setup` or `Purchases & Payables Setup`, a `Modify(true)` on an active line sets it back to Draft (the `OnBeforeModifyEvent` subscriber in `Price List Management`). The line leaves the calculation until it is activated again. When the setting is off, validations on an active line fail on `TestStatusDraft`.

## Best Practice

- Header: `Init`, set `Price Type` for project lists, validate `Source Type` and `Source No.` (and `Parent Source No.` for project tasks), currency and dates, then `Insert(true)`. With a blank `Code`, the number series supplies one.
- Line: set `Price List Code`, call `SetNextLineNo` and `CopyFrom(PriceListHeader)`, validate `Asset Type`, `Asset No.`, unit of measure, `Minimum Quantity` and the amount, then `Insert(true)`. With `Allow Updating Defaults` on, `CopyFrom` leaves the source, dates and currency to the line, so validate them on the line too.
- Activate: `Validate(Status, Status::Active)` on the header and `Modify(true)`.
- After code changes to an active list, call `PriceListManagement.ActivateDraftLines(PriceListHeader, true)`. It activates only the Draft lines last modified by the current user.

`Library - Price Calculation` in the test library builds headers and lines the same way (`CreatePriceHeader`, `CreatePriceListLine`).

See sample: [`create-price-lists-from-code-through-header-defaults-and-status-validation.good.al`](create-price-lists-from-code-through-header-defaults-and-status-validation.good.al).

## Anti Pattern

Assign `PriceListHeader.Status := Status::Active` and call `Modify`. The header looks active, but its lines stay Draft and no document finds the prices. Another trap is to insert lines by assigning `Source Type`, `Asset No.` and `Unit Price` without `CopyFrom`. The lines then have `Price Type` Any and no `Source Group`, so the calculation filters them out and copy actions skip them.

See sample: [`create-price-lists-from-code-through-header-defaults-and-status-validation.bad.al`](create-price-lists-from-code-through-header-defaults-and-status-validation.bad.al).

## References

- [Price List Header: Status validation, UpdateStatus, CopyFrom(Price Source)](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/PriceList/PriceListHeader.Table.al).
- [Price List Line: CopyFrom(Price List Header), InitHeaderDefaults, TestHeadersValue](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/PriceList/PriceListLine.Table.al).
- [Price List Management: ActivateDraftLines, ResolveDuplicatePrices, MarkLineAsDraft](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/PriceList/PriceListManagement.Codeunit.al).
- [Price Calculation Buffer Mgt.: SetFiltersOnPriceListLine](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Pricing/Calculation/PriceCalculationBufferMgt.Codeunit.al).
- [Library - Price Calculation](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/Tests/ApplicationTestLibrary/LibraryPriceCalculation.Codeunit.al).
- [Record sales prices and discounts](https://learn.microsoft.com/dynamics365/business-central/sales-how-record-sales-price-discount-payment-agreements).
