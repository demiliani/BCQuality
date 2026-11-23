# Feature design

> Add a 'By Freight Factor' distribution method to the purchase item charge suggestion, next to Equally, By Amount, By Weight and By Volume, that splits a freight item charge across the received items in proportion to a Freight Factor maintained on each item.

**Result:** Complete design. **Business process:** Purchasing: item charge assignment on purchase invoices (Suggest Item Charge Assignment in codeunit "Item Charge Assgnt. (Purch.)"). **Knowledge used:** 12 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Should 'By Freight Factor' also be offered for sales item charges ("Item Charge Assgnt. (Sales)")? The request names purchase invoices only. _(affects: freight-factor-item-charge, freight-factor-item-charge-tests)_
2. When every item on the assignment lines has Freight Factor 0, is the standard 'No item charges were assigned.' error acceptable, or should the method fall back to another distribution? _(affects: freight-factor-item-charge, all-factors-zero-raises-error)_
3. Should items with Freight Factor 0 receive no share of the freight when other items have a factor, or should that be blocked or warned about? _(affects: freight-factor-item-charge, distributes-by-freight-factor)_
4. Which values are allowed for Freight Factor (negative values, maximum, decimal places)? _(affects: item-freight-factor)_
5. After rounding each Amount to Assign, should any rounding difference be placed on one line so the assigned total equals the charge amount exactly? _(affects: freight-factor-item-charge, foreign-currency-rounding)_
6. With a single assignment line the standard code picks the first menu option without asking; is that acceptable for this method? _(affects: freight-factor-item-charge)_
7. Do existing items need an initial Freight Factor at install or upgrade, or do buyers maintain it manually? _(affects: item-freight-factor)_
8. What caption should the method show in the menu, and where on the Item Card should the Freight Factor field appear? _(affects: freight-factor-item-charge, item-card-freight-factor)_
9. Which BC version and runtime does the app target? It decides whether the ToolTip is defined on the table field (runtime 13.0 / BC24 or later) or on the page. _(affects: item-freight-factor, item-card-freight-factor)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Item | Stores the Freight Factor each item contributes to the freight distribution. | Freight Factor (Decimal): Explicit DataClassification on the field (a tableextension inherits no table-level default); never ToBeClassified at release. ToolTip on the table field when the target is runtime 13.0 (BC24) or later. Allowed range and decimal places are an open question. | [1] [2] [3] [4] |
| 2 | extend | pageextension | Item Card | Lets buyers maintain the Freight Factor on the item. The bound field inherits the table-field ToolTip on runtime 13.0 or later; on earlier targets it needs a page-level ToolTip. Placement on the card is an open question. |  | [4] [5] |
| 3 | create | codeunit | Freight Factor Item Charge | Holds the two event subscribers on "Item Charge Assgnt. (Purch.)" that add the 'By Freight Factor' caption to the suggestion menu and distribute Qty. to Assign and Amount to Assign for that caption only. The caption is a Label without a comma, used in both subscribers. |  | [1] [6] [7] |
| 4 | create | codeunit | Freight Factor Item Charge Tests | Test codeunit (Subtype = Test) tagged with [FEATURE], with a StrMenu handler that picks the 'By Freight Factor' caption, fixtures from the Library codeunits and explicit factor values that define the expected split. |  | [8] [9] [10] [11] |

## 3. How the data flows

- **Buyer on Item Card** → **Item."Freight Factor"**: entered by the user. Maintained per item through the Item Card page extension. [4]
- **Suggest Item Charge Assignment menu (StrMenu) on the purchase invoice item charge line** → **SelectionTxt of OnAssignItemCharges**: entered by the user. The menu is shown only when the charge has more than one assignment line; with one line the standard code picks the first option without asking. [1]
- **Item."Freight Factor" of each assignment line's item** → **Item Charge Assignment (Purch)."Qty. to Assign" and "Amount to Assign"**: other. Read in the OnAssignItemCharges subscriber over the filtered assignment set the event passes; each line gets TotalQtyToAssign and TotalAmtToAssign times its factor divided by the total factor, amounts rounded with the currency's Amount Rounding Precision. [1] [7]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Item Charge Assgnt. (Purch.)" | `OnBeforeShowSuggestItemChargeAssignStrMenu` | Append the 'By Freight Factor' caption, with a leading comma, to SuggestItemChargeMenuTxt so it is offered next to Equally, By Amount, By Weight and By Volume. | Append only one caption, taken from the extension's own Label. · The caption must not contain a comma, because the menu is split on commas. · Do not replace the standard menu or subscribe to OnBeforeSuggestAssgnt with IsHandled. | [1] |
| Codeunit "Item Charge Assgnt. (Purch.)" | `OnAssignItemCharges` | When the user chose 'By Freight Factor', fill Qty. to Assign and Amount to Assign on every assignment line in the filtered set in proportion to each item's Freight Factor and set ItemChargesAssigned to true. | Exit unless SelectionTxt equals the same Label value used in the menu subscriber; never match a literal English word, and never handle other captions. · Check SelectionTxt before any database call. · Use SetLoadFields("Freight Factor") before reading Item, when the loop is large enough to justify it. · Round Amount to Assign with Currency."Amount Rounding Precision". · Set ItemChargesAssigned to true only after the lines are filled; if it stays false the standard code raises 'No item charges were assigned.' | [1] [6] [7] |

## 5. Setup, permissions and lifecycle

- **privacy**: Give the Freight Factor field an explicit DataClassification chosen from the data it stores; resolve any ToBeClassified before release. [2] [3]
- **setup**: No setup table or install code is designed: existing items start with a Freight Factor of 0. Whether existing items need an initial value is an open question. agent judgment

## 6. Tests

1. **distributes-by-freight-factor** [1] [8] [10] [11] [9]
    - Given Items A and B created with LibraryInventory with explicit Freight Factors 1 and 3, a posted purchase receipt for both, and a purchase invoice with an item charge line assigned to both receipt lines.
    - When Suggest Item Charge Assignment runs and the StrMenu handler selects the 'By Freight Factor' caption.
    - Then Qty. to Assign and Amount to Assign on the two assignment lines are 25 % and 75 % of the totals, amounts rounded with the currency's Amount Rounding Precision, and the handler executed.
2. **freight-factor-entered-on-item-card** [8] [9]
    - Given An item created with LibraryInventory.
    - When A Freight Factor is entered on the Item Card test page.
    - Then The Item record holds the entered Freight Factor.
3. **standard-method-unaffected** [1] [10]
    - Given The same invoice setup as distributes-by-freight-factor.
    - When The StrMenu handler selects By Amount instead.
    - Then The assignment matches the standard By Amount result, proving the subscriber ignores captions it does not own.
4. **all-factors-zero-raises-error** [1] [12]
    - Given Two items with Freight Factor 0 on the invoice's assignment lines.
    - When Suggest Item Charge Assignment runs with 'By Freight Factor' selected.
    - Then The standard 'No item charges were assigned.' error is raised, verified with asserterror followed by Assert.ExpectedError on the full message.
5. **foreign-currency-rounding** [1] [11]
    - Given A purchase invoice in a currency with an explicit Amount Rounding Precision and factors chosen so the split does not divide evenly.
    - When Suggest Item Charge Assignment runs with 'By Freight Factor' selected.
    - Then Each Amount to Assign is rounded to that currency's Amount Rounding Precision.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown: no repository or app.json was supplied.
- The 'setup' lifecycle step (no install or upgrade code) rests on agent judgment; no BCQuality article covers it for this feature.

## Sources

[1] `microsoft/knowledge/inventory/add-a-custom-item-charge-distribution-method.md`: Core mechanism: the two events on "Item Charge Assgnt. (Purch.)" that add and handle a custom distribution method.
    - Distribution methods are captions in a comma-separated StrMenu string, not an enum.
    - Append one caption from your own Label to SuggestItemChargeMenuTxt with a leading comma; the caption must not contain a comma.
    - In OnAssignItemCharges act only when SelectionTxt equals that caption, compared against the same Label value; never match a literal English word.
    - Fill Qty. to Assign and Amount to Assign on every line in the filtered set, round amounts with the currency's rounding precision, and set ItemChargesAssigned to true; otherwise the standard code raises 'No item charges were assigned.'
    - The menu event runs only when the charge has more than one assignment line.
    - Implement both the purchase and the sales codeunit when the method applies to both.
    - Do not replace the suggestion with OnBeforeSuggestAssgnt and IsHandled, or rewrite assignment rows after the standard suggestion.
[2] `microsoft/knowledge/privacy/table-level-data-classification-cascades.md`: Classification of the Freight Factor field added by the Item tableextension.
    - A tableextension inherits no table-level DataClassification; every Normal field it adds needs an explicit valid DataClassification.
[3] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Release-readiness of the new field's classification.
    - ToBeClassified must be resolved to a real classification before the code ships, decided from the data's content.
[4] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: ToolTip for the Freight Factor field on the Item Card.
    - On runtime 13.0 (BC24) or later, define the tooltip on the table field and omit a duplicate page-level ToolTip.
    - Before runtime 13.0, user-facing page fields need a page-level ToolTip.
    - Tooltip text should say what the value is used for and expected values, not just repeat the caption; do not invent behavior.
[5] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Whether the Item Card extension field needs its own ToolTip (applies from BC24 / runtime 13.0).
    - A bound page field inherits the source table field's ToolTip on runtime 13.0 or later; add a page-level override only when different help is needed or nothing can be inherited.
[6] `microsoft/knowledge/performance/guard-event-subscribers-before-db-call.md`: Order of checks in the OnAssignItemCharges subscriber.
    - Open the subscriber with a cheap in-memory check that filters out calls it does not handle before any database call.
[7] `microsoft/knowledge/performance/use-setloadfields-for-partial-records.md`: Reading Item."Freight Factor" per assignment line (conditional on the loop size heuristics the article states).
    - Call SetLoadFields immediately before the read, listing the normal fields the code reads.
    - Skip it when the loop runs ten or fewer iterations or the code reads most fields (BCQuality heuristics).
[8] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for items, vendor, receipt and invoice in the tests.
    - Create records with the Library codeunits (LibraryInventory, LibraryPurchase, LibraryRandom), parents before dependents, and Validate foreign keys.
[9] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit.
    - [FEATURE] once before the codeunit's opening brace; [SCENARIO] as the first comment in each test; [GIVEN]/[WHEN]/[THEN] marking setup, single action and assertions.
[10] `microsoft/knowledge/testing/ui-handlers-in-tests.md`: Handling the Suggest Item Charge Assignment StrMenu in headless tests.
    - Every UI call on the executed path needs a handler listed in HandlerFunctions, and every nonoptional listed handler must execute.
    - Each executed handler must contribute meaningful evidence; assert the semantic outcome, not a Boolean set before the action.
[11] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Choosing test values for Freight Factors, amounts and rounding precision.
    - Generate incidental fixture data with library codeunits, but keep values that define the expected outcome (factors, amounts, rounding precision) explicit and deliberately chosen.
[12] `microsoft/knowledge/testing/asserterror-needs-expectederror-and-code.md`: The negative test for all-zero Freight Factors.
    - Follow every asserterror with Assert.ExpectedError on text only the intended error produces, and ExpectedErrorCode where known, not the code alone.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
