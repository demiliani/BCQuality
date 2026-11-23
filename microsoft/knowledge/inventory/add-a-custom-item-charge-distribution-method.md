---
bc-version: [all]
domain: inventory
keywords: [item-charge, item-charge-assignment, suggestassgnt, onbeforeshowsuggestitemchargeassignstrmenu, onassignitemcharges, itemchargesassigned, item-charge-assgnt-purch, item-charge-assgnt-sales, distribution-method]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Add a custom item charge distribution method

## Description

The Suggest Item Charge Assignment action calls `SuggestAssgnt` in `"Item Charge Assgnt. (Purch.)"` or `"Item Charge Assgnt. (Sales)"`. The distribution methods are not an enum. They are captions in a comma-separated menu string, such as Equally, By Amount, By Weight and By Volume, shown with `StrMenu`. `AssignItemCharges` then compares the chosen caption with the standard ones in a `case` statement and raises an event for any other caption.

Two events make a method extensible, on both codeunits:

- `OnBeforeShowSuggestItemChargeAssignStrMenu(PurchLine or SalesLine, var SuggestItemChargeMenuTxt, var SuggestItemChargeMessageTxt, var Selection)` lets a subscriber append its caption to the menu.
- `OnAssignItemCharges(SelectionTxt, var ItemChargeAssignment..., Currency, PurchaseHeader or SalesHeader, TotalQtyToAssign, TotalAmtToAssign, var ItemChargesAssigned)` runs for a caption the standard `case` does not know. If no subscriber sets `ItemChargesAssigned` to true, the codeunit raises "No item charges were assigned."

The menu event runs only when the charge has more than one assignment line. With a single line, the standard code selects the first menu option without asking.

## Best Practice

Append one caption, from your own label, to `SuggestItemChargeMenuTxt` with a leading comma. In `OnAssignItemCharges`, act only when `SelectionTxt` equals that caption. Fill `"Qty. to Assign"` and `"Amount to Assign"` on every assignment line in the filtered set the event passes, round amounts with the currency's rounding precision, and set `ItemChargesAssigned` to true. Implement both the purchase and the sales codeunit when the method applies to both.

The caption must not contain a comma, because the menu is split on commas. Compare against the same label value in both events; the standard captions are translated, so never match on a literal English word.

See sample: [`add-a-custom-item-charge-distribution-method.good.al`](add-a-custom-item-charge-distribution-method.good.al).

## Anti Pattern

Replace the whole suggestion with `OnBeforeSuggestAssgnt` and `IsHandled`, or rewrite `Item Charge Assignment (Purch)` rows after the user has run the standard suggestion. Both remove the standard methods or override the user's choice. Handling every `SelectionTxt` in `OnAssignItemCharges` without checking the caption takes over methods that belong to other extensions.

See sample: [`add-a-custom-item-charge-distribution-method.bad.al`](add-a-custom-item-charge-distribution-method.bad.al).

## References

- [Item Charge Assgnt. (Purch.), SuggestAssgnt and AssignItemCharges](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Purchases/Document/ItemChargeAssgntPurch.Codeunit.al).
- [Item Charge Assgnt. (Sales)](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Sales/Document/ItemChargeAssgntSales.Codeunit.al).
- [Extending item charges](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extending-item-charges).
