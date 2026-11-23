# Feature design

> Sales order lines carry a customer project code. Planners run Calculate Plan in the planning worksheet and sometimes use Order Planning, then carry out the suggestions. The purchase order lines and production order lines created for that demand must show the customer project code so buyers and the shop floor know which project they serve.

**Result:** Complete design. **Business process:** Carry a customer project code from sales order lines through supply planning (Calculate Plan in the planning worksheet and Order Planning) and carry-out to the purchase order lines and production order lines it creates, in the base application's inventory planning and manufacturing processes. **Knowledge used:** 10 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Does the customer project code already exist on Sales Line in one of your apps? If so, give its field number, type, length and table relation (for example to Job or a custom table) so every new field matches it. _(affects: sales-line-ext, inventory-profile-ext, requisition-line-ext, purchase-line-ext, prod-order-line-ext)_
2. With Lot-for-Lot, Fixed Reorder Qty. or Maximum Qty. one planning line can cover demands from several sales lines with different projects, and only the first demand is carried. Should the feature be limited to items with Reordering Policy Order, or which demand's project should win (or should the field stay blank when demands differ)? _(affects: cust-project-planning, calc-plan-sales-to-planning-line)_
3. The design puts the project on purchase lines only. Should one purchase order hold lines for several projects, or must carry-out split purchase orders by project (a header field and CheckInsert in OnBeforeCheckInsertFinalizePurchaseOrderHeader)? _(affects: purchase-line-ext, cust-project-planning)_
4. The design mirrors the field on Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line, Return Shipment Line and Purchase Line Archive. Which of these do you need, and can credit memos and return shipments be excluded? _(affects: purch-rcpt-line-ext, purch-inv-line-ext, purch-cr-memo-line-ext, return-shipment-line-ext, purchase-line-archive-ext)_
5. Must the project also reach purchase lines created by Get Sales Orders for drop shipments and special orders, lines from the requisition worksheet, and lines carried out with Copy to Req. Wksh (which clears the demand fields)? Must it reach transfer or assembly orders carried out from planning? _(affects: cust-project-planning)_
6. Is the project needed only on production order lines, or also on the Production Order header (one carried-out order can hold lines for several demands)? _(affects: prod-order-line-ext)_
7. Besides the Purchase Order Subform and Released Prod. Order Lines, should the project be visible on the Planning Worksheet, Order Planning, Firm Planned and Planned Prod. Order Lines and the posted purchase pages? _(affects: purchase-order-subform-ext, prod-order-line-pages-ext)_
8. Should open purchase and production orders created before installation be back-filled with the project, or may they stay blank? _(affects: purchase-line-ext, prod-order-line-ext)_
9. May buyers or planners change the project on the purchase or production order line after carry-out, or should it be read-only? _(affects: purchase-line-ext, prod-order-line-ext, purchase-order-subform-ext, prod-order-line-pages-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Sales Line | Source of the value. The request says sales order lines already carry the customer project code; reuse that field if it exists in an app and add this extension only if it does not. | Customer Project (Code[20]): Source field. DataClassification = CustomerContent. | [2] [7] |
| 2 | extend | tableextension | Inventory Profile | Holds the value on the demand profile that Calculate Plan builds from the sales line, so it can reach the planning line. | Customer Project (Code[20]): Same field number, name, type and length as the Sales Line field; type and length are an open question (cust-project-field-definition). DataClassification = CustomerContent. | [2] [7] |
| 3 | extend | tableextension | Requisition Line | Holds the value on planning worksheet and Order Planning lines; carry-out reads only the requisition line. | Customer Project (Code[20]): Same field number, name, type and length as the Sales Line field; type and length are an open question (cust-project-field-definition). DataClassification = CustomerContent. | [2] [7] |
| 4 | extend | tableextension | Purchase Line | Shows buyers which project the planned purchase line serves; filled before insert by carry-out. | Customer Project (Code[20]): Same field number, name, type and length as the Sales Line field; type and length are an open question (cust-project-field-definition). DataClassification = CustomerContent. | [2] [5] [6] [7] |
| 5 | extend | tableextension | Purch. Rcpt. Line | Mirror of the Purchase Line field so InitFromPurchLine TransferFields carries it to posted receipts. Non-editable. | Customer Project (Code[20]): Same field number, name, type and length as the Sales Line field; type and length are an open question (cust-project-field-definition). DataClassification = CustomerContent. Editable = false. | [5] [6] [7] |
| 6 | extend | tableextension | Purch. Inv. Line | Mirror of the Purchase Line field on posted invoices. Non-editable. | Customer Project (Code[20]): Same field number, name, type and length as the Sales Line field; type and length are an open question (cust-project-field-definition). DataClassification = CustomerContent. Editable = false. | [5] [6] [7] |
| 7 | extend | tableextension | Purch. Cr. Memo Line | Mirror of the Purchase Line field on posted credit memos, unless the requester excludes this document type. Non-editable. | Customer Project (Code[20]): Same field number, name, type and length as the Sales Line field; type and length are an open question (cust-project-field-definition). DataClassification = CustomerContent. Editable = false. | [5] [6] [7] |
| 8 | extend | tableextension | Return Shipment Line | Mirror of the Purchase Line field on posted return shipments, unless the requester excludes this document type. Non-editable. | Customer Project (Code[20]): Same field number, name, type and length as the Sales Line field; type and length are an open question (cust-project-field-definition). DataClassification = CustomerContent. Editable = false. | [5] [6] [7] |
| 9 | extend | tableextension | Purchase Line Archive | Mirror of the Purchase Line field so archived purchase orders keep it. Non-editable. | Customer Project (Code[20]): Same field number, name, type and length as the Sales Line field; type and length are an open question (cust-project-field-definition). DataClassification = CustomerContent. Editable = false. | [5] [6] [7] |
| 10 | extend | tableextension | Prod. Order Line | Shows the shop floor which project the production order line serves; filled before insert by carry-out. The status change from Planned/Firm Planned to Released and Finished copies it by record assignment, so no mirror table and no copy subscriber are needed. | Customer Project (Code[20]): Same field number, name, type and length as the Sales Line field; type and length are an open question (cust-project-field-definition). DataClassification = CustomerContent. | [2] [4] [7] |
| 11 | create | codeunit | Cust. Project Planning | Event subscribers that copy the value at every planning and carry-out hop, each before the insert so no Modify is needed. |  | [2] [3] |
| 12 | extend | pageextension | Purchase Order Subform | Shows the field to buyers on purchase order lines, read-only. The page field binds to the table field and inherits its ToolTip when the target runtime supports it. |  | [8] |
| 13 | extend | pageextension | Released Prod. Order Lines | Shows the field to the shop floor on released production order lines, read-only. The same extension is needed on Firm Planned Prod. Order Lines and Planned Prod. Order Lines if planners must see it there (open question). The page field inherits the table field's ToolTip when the target runtime supports it. |  | [8] |

## 3. How the data flows

- **Sales Line** → **Inventory Profile**: copied in an event subscriber. Calculate Plan: OnAfterTransferInventoryProfileFromSalesLine on Sales Line Invt. Profile. [2]
- **Inventory Profile** → **Requisition Line**: copied in an event subscriber. Calculate Plan: OnMaintainPlanningLineOnBeforeReqLineInsert on Inventory Profile Offsetting, from DemandInvtProfile, only when its Source Type is Sales Line. Planning-engine lines have no Demand Order No., so the value cannot be looked up later. [2]
- **Sales Line** → **Requisition Line**: copied in an event subscriber. Order Planning: OnAfterTransferFromUnplannedDemand on Requisition Line; when Demand Type is Sales, get the sales line from the demand keys and copy the value. [2]
- **Requisition Line** → **Purchase Line**: copied in an event subscriber. Carry-out to purchase (planning worksheet and Order Planning share Req. Wksh.-Make Order): OnAfterInitPurchOrderLine, before the insert. Carry-out stays in the standard workflow. [2] [3]
- **Requisition Line** → **Prod. Order Line**: copied in an event subscriber. Carry-out to production: OnInsertProdOrderLineWithReqLine on Mfg. Carry Out Action, before the Prod. Order Line insert. [2]
- **Prod. Order Line (Planned / Firm Planned)** → **Prod. Order Line (Released / Finished)**: other. Prod. Order Status Management copies the whole record by assignment; no code needed. [4]
- **Purchase Line** → **Purch. Rcpt. Line, Purch. Inv. Line, Purch. Cr. Memo Line, Return Shipment Line**: standard TransferFields copy. InitFromPurchLine TransferFields by field number during purchase posting. [5] [6]
- **Purchase Line** → **Purchase Line Archive**: standard TransferFields copy. Archiving copies lines with TransferFields by field number. [5] [6]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Sales Line Invt. Profile | `OnAfterTransferInventoryProfileFromSalesLine` | Copy the customer project from the sales line to the demand inventory profile during Calculate Plan. |  | [2] |
| Inventory Profile Offsetting | `OnMaintainPlanningLineOnBeforeReqLineInsert` | Copy the customer project from DemandInvtProfile to the new planning line before insert. | Exit unless DemandInvtProfile."Source Type" = Database::"Sales Line"; some call sites pass a supply profile in that parameter. · Assign without Modify; the event runs before the insert. | [2] |
| Requisition Line | `OnAfterTransferFromUnplannedDemand` | Order Planning: read the sales line identified by the unplanned demand keys and copy the customer project. | Exit unless UnplannedDemand."Demand Type" is Sales. · Get the sales line with SetLoadFields on the project field only; skip if not found. | [2] |
| Req. Wksh.-Make Order | `OnAfterInitPurchOrderLine` | Copy the customer project from the requisition line to the purchase line before insert. | Assign without Modify; the event runs before the insert. · Do not look up the sales line from Demand Order No.; copy from the requisition line only. | [2] [3] |
| Mfg. Carry Out Action | `OnInsertProdOrderLineWithReqLine` | Copy the customer project from the requisition line to the production order line before insert. | Assign without Modify; the event runs before the insert. | [2] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification = CustomerContent on every table extension field; a tableextension has no table-level value to inherit, so each field sets its own. [7]
- **upgrade**: No InitValue and no upgrade code: existing requisition lines, purchase lines, production order lines and posted lines stay blank, which is a valid state for an informational field. Back-filling open orders is an open question. [10]
- **other**: Put the Caption and ToolTip on the table fields so bound page fields inherit the ToolTip on runtime 13.0 (BC24) or later; on earlier runtimes add the ToolTip on each page field. [8]
- **permissions**: No new tables are created, so no new permission set is designed; the extension fields follow the permissions of their base tables. Rests on judgment. agent judgment

## 6. Tests

1. **calc-plan-sales-to-planning-line** [2] [9]
    - Given An item with Reordering Policy Order and Replenishment System Purchase, and a sales order line with a customer project code, created with LibraryInventory and LibrarySales
    - When Calculate Plan runs in the planning worksheet for the item
    - Then The planning line for that sales demand has the same customer project code
2. **order-planning-sales-to-req-line** [2] [9]
    - Given An Order item and a sales order line with a customer project code, created with library codeunits
    - When Order Planning calculates the plan
    - Then The requisition line for the sales demand has the customer project code
3. **carry-out-to-purchase-line** [2] [3] [9]
    - Given An accepted New/Purchase planning line with a customer project code, created by Calculate Plan from a sales line
    - When The action message is carried out through the standard Carry Out Action Msg. - Plan. workflow
    - Then The created purchase line has the customer project code
4. **carry-out-order-planning-to-purchase-line** [2] [3] [9]
    - Given An accepted Order Planning line for sales demand with a customer project code
    - When Make Orders carries it out to a purchase order
    - Then The created purchase line has the customer project code
5. **carry-out-to-prod-order-line** [2] [3] [9]
    - Given An item with Replenishment System Prod. Order and Reordering Policy Order, a sales order line with a customer project code, and an accepted planning line from Calculate Plan
    - When The action message is carried out to a firm planned production order
    - Then The created production order line has the customer project code
6. **status-change-keeps-project** [4] [9]
    - Given A firm planned production order line with a customer project code
    - When The production order is changed to Released
    - Then The released production order line has the same customer project code
7. **guard-non-sales-demand** [2] [9]
    - Given A manufactured parent item whose component demand creates a planning line for a component item, with no sales demand for the component
    - When Calculate Plan runs
    - Then The component's planning line has a blank customer project code and no error occurs
8. **purchase-receipt-mirror** [5] [6] [9]
    - Given A purchase line created by carry-out with a customer project code
    - When The purchase order is posted as received
    - Then The posted Purch. Rcpt. Line has the same customer project code
9. **purchase-invoice-mirror** [5] [6] [9]
    - Given A purchase line created by carry-out with a customer project code
    - When The purchase order is posted as received and invoiced
    - Then The posted Purch. Inv. Line has the same customer project code
10. **purchase-archive-mirror** [5] [6] [9]
    - Given A purchase order line created by carry-out with a customer project code
    - When The purchase order is archived
    - Then The Purchase Line Archive row has the same customer project code

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown: no repository or app.json was supplied. The ToolTip inheritance applies from BC24 (runtime 13.0).
- Page extensions on Purchase Order Subform and the production order line pages rest on the agent's judgment: no BCQuality article covers which pages show a planning-carried field; only the ToolTip placement is knowledge-backed.
- The permissions decision (no new permission set for table extension fields) is not covered by BCQuality knowledge and rests on the agent's judgment.
- Using the same field number on Inventory Profile, Requisition Line and Prod. Order Line as on Sales Line is a convention from the sample; these hops copy by event, not by TransferFields.

## Sources

[1] `microsoft/knowledge/feature-design/plan-a-custom-field-across-a-process.md`: Map of field paths: selected the Inventory planning-to-supply-orders row, the Production status-change row and the cross-cutting rows (mirrored definitions, privacy, upgrade back-fill, tests).
    - Plan one row group per process the request touches and open every linked article for the chosen stages.
    - Whether the field should reach a stage the request does not name, such as archives or posted documents, is a question for the requester; raise one question per group of stages.
    - Do not plan only the source and one named target and patch other records with subscribers after posting.
[2] `microsoft/knowledge/inventory/carry-demand-fields-through-planning-lines-to-supply-orders.md`: Core design of every planning and carry-out hop, the objects, the subscriptions and their guards.
    - Add the field to Sales Line, Inventory Profile, Requisition Line and each target table.
    - Subscribe once per hop: OnAfterTransferInventoryProfileFromSalesLine, OnMaintainPlanningLineOnBeforeReqLineInsert, OnAfterTransferFromUnplannedDemand, OnAfterInitPurchOrderLine, OnInsertProdOrderLineWithReqLine.
    - In OnMaintainPlanningLineOnBeforeReqLineInsert, check DemandInvtProfile."Source Type" is Database::"Sales Line" first.
    - In OnAfterTransferFromUnplannedDemand, act only when Demand Type is Sales.
    - OnAfterInitPurchOrderLine and OnInsertProdOrderLineWithReqLine run before the insert; assign without Modify.
    - A planning line maps to one demand only with Reordering Policy Order; with Lot-for-Lot, Fixed Reorder Qty. or Maximum Qty. one line can cover several demands and only the first demand is seen. State which demand wins or limit the feature to Order items.
    - A header field that must split purchase orders needs CheckInsert in OnBeforeCheckInsertFinalizePurchaseOrderHeader.
    - Never look up the sales line from Demand Order No. at carry-out; Calculate Plan lines have none, and Copy to Req. Wksh clears the demand fields.
    - Never patch the purchase line in OnAfterPurchOrderLineInsert with Modify.
[3] `microsoft/knowledge/scm/carry-out-requisition-actions-through-the-standard-workflow.md`: Keeps carry-out in the standard workflow, both in the feature and in its tests.
    - Carry out through Req. Wksh.-Make Order (Set, then CarryOutBatchAction) or the standard Carry Out Action dispatch, never by creating supply from a requisition line and deleting it.
    - Each action's supply change and reservation transfer precede proposal finalization; not every action creates a new order.
[4] `microsoft/knowledge/manufacturing/production-order-status-change-copies-whole-records.md`: Decides that no copy code is needed when the production order changes status.
    - Add the field once on the production order table that owns it and rely on the status change to carry it.
    - Use the OnCopyFrom... events of Prod. Order Status Management only to change the value on the way.
    - Do not copy the field again in OnAfterTransProdOrder with Modify.
[5] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Mirrors the Purchase Line field on posted purchase lines and the purchase line archive.
    - Give the field the same number, name, type and length on Purchase Line and every target the plan needs: all four posted line tables and the archive, unless the plan states a document type never needs it.
    - No subscriber is needed for these stages; keep the mirrored fields non-editable on the posted tables.
[6] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definitions of the mirrored purchase fields.
    - Define a mirrored field with the exact same field number, data type and length on every table in the TransferFields cascade, at creation time.
[7] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Classification of every new table extension field.
    - Every Normal field a tableextension adds must set its own DataClassification matching the data stored; ToBeClassified or SystemMetadata for customer data is a privacy bug.
[8] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Where the ToolTip lives for the page fields; applies from BC24 (runtime 13.0).
    - On runtime 13.0 or later a bound page field inherits the source table field's ToolTip; do not add a duplicate page-level ToolTip.
    - On earlier runtimes the inheritance is not available.
[9] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for all tests.
    - Build items, customers and sales documents with the Library codeunits, parents first, validating foreign keys, not with hand-rolled Init/Insert.
[10] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: Upgrade decision for rows that exist when the fields are added.
    - Existing rows get the datatype default, not an InitValue; ship upgrade code only when existing rows must carry a value.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v3. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._

