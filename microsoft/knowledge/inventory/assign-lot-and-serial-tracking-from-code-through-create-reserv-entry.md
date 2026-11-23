---
bc-version: [all]
domain: inventory
keywords: [item-tracking, lot-no, serial-no, reservation-entry, create-reserv-entry, createreserventryfor, createentry, tracking-specification, item-journal-line, prospect]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Assign lot and serial tracking from code through Create Reserv. Entry

## Description

Lot and serial numbers on an unposted source line are not fields of the line. They are `Reservation Entry` rows that point to the line through `Source Type`, `Source Subtype`, `Source ID`, `Source Batch Name`, `Source Prod. Order Line` and `Source Ref. No.`. When an item journal line posts, `Item Jnl.-Post Line` reads those entries through `"Item Tracking Management".RetrieveItemTracking`, sums them per lot and serial, and splits the line into one item ledger entry per tracking combination.

The Item Tracking Lines page creates these entries with codeunit `"Create Reserv. Entry"`: `CreateReservEntryFor` sets the source, quantities and tracking, `SetDates` sets warranty and expiration dates, and `CreateEntry` inserts the row with a reservation status. `CreateReservEntryFor` applies the sign of the source itself, so callers pass positive quantities. The page uses status `Surplus` for order-network sources such as sales and purchase order lines, and `Prospect` for other sources such as journal lines; `"Item Tracking Management".IsOrderNetworkEntity` makes that decision.

## Best Practice

A feature that assigns lots or serials from code, for example from a scanner or an import, follows the same calls as the page:

1. Put the tracking values on a `Reservation Entry` variable with its tracking fields, such as `"Lot No."`.
2. Call `CreateReservEntryFor` with the source identity of the line, its quantity per unit of measure, and the positive quantity and base quantity to track.
3. Call `SetDates` when the item tracking code needs expiration or warranty dates.
4. Call `CreateEntry` with item, variant, location and description from the line, and the status the page would use for that source.

Validate that the tracked base quantity does not exceed the line's base quantity before calling. Moving existing tracking between two document lines is a different operation; see [transfer item tracking through source reservation codeunits](../scm/transfer-item-tracking-through-source-reservation-codeunits.md).

See sample: [`assign-lot-and-serial-tracking-from-code-through-create-reserv-entry.good.al`](assign-lot-and-serial-tracking-from-code-through-create-reserv-entry.good.al).

## Anti Pattern

Insert `Reservation Entry` rows directly with a computed `Entry No.` and hand-filled source and quantity fields. The insert bypasses the sign handling, the status choice and the other fields `Create Reserv. Entry` maintains, so posting can reject the tracking or split the line on the wrong quantities. Deleting or rewriting reservation entries later has the same problem; see [cancel reservations through reservation management](../scm/cancel-reservations-through-reservation-management.md).

See sample: [`assign-lot-and-serial-tracking-from-code-through-create-reserv-entry.bad.al`](assign-lot-and-serial-tracking-from-code-through-create-reserv-entry.bad.al).

## References

- [Create Reserv. Entry](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/CreateReservEntry.Codeunit.al).
- [Item Tracking Lines page, RegisterChange insert path](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingLines.Page.al).
- [Item Tracking Management, RetrieveItemTracking and IsOrderNetworkEntity](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Inventory/Tracking/ItemTrackingManagement.Codeunit.al).
- [Design details: Item Tracking Lines window](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-item-tracking-lines-window).
