# Feature design

> Routing operations get a Coating Spec code. It must appear on production order routing lines, whether the order is created and refreshed by hand or created from the planning worksheet, and on the subcontracting purchase order line created for that operation.

**Result:** Complete design. **Business process:** Manufacturing: routings, production order creation (refresh and planning carry-out), production order status changes and subcontracting purchasing. **Knowledge used:** 14 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Is Coating Spec a free code, or must it be validated against a master list (a new Coating Spec table or an existing table)? If a master table is needed, its key length sets the field length and it needs its own table, pages and permissions. _(affects: routing-line-ext, planning-routing-line-ext, prod-order-routing-line-ext, purchase-line-ext, purch-rcpt-line-ext, purch-inv-line-ext, purch-cr-memo-line-ext, return-shipment-line-ext, purchase-line-archive-ext)_
2. May users change the Coating Spec on a production order routing line? If yes, they must accept that a refresh that recalculates routings resets it to the routing value. _(affects: prod-order-routing-line-ext, prod-order-routing-page-ext, refresh-resets-manual-value)_
3. Must the Coating Spec also reach posted receipt, invoice, credit memo and return shipment lines and archived purchase lines? The design includes them because the mirroring guidance requires every TransferFields target unless you exclude a document type. _(affects: purch-rcpt-line-ext, purch-inv-line-ext, purch-cr-memo-line-ext, return-shipment-line-ext, purchase-line-archive-ext, posting-mirrors-coating-spec, archive-mirrors-coating-spec)_
4. Must planners see the Coating Spec on the subcontracting worksheet (Requisition Line)? It is not designed; if needed it is filled from OnAfterTransferProdOrderRoutingLine of the report your version uses and is not filled by the Subcontracting app's direct creation path. _(affects: coating-spec-copy-codeunit)_
5. Which BC version is targeted, and is the Microsoft Subcontracting app in use? This decides which subcontracting creation paths the tests must cover. _(affects: subcontracting-po-line-gets-coating-spec, subcontracting-direct-creation-gets-coating-spec)_
6. Must the Coating Spec appear anywhere else, such as the Planning Routing page, the purchase order printout, or the vendor's subcontracting documents? _(affects: routing-lines-page-ext, prod-order-routing-page-ext, purchase-order-subform-ext)_
7. Must existing routings, open production orders or open subcontracting purchase lines be back-filled, or does the value apply only to new orders? _(affects: routing-line-ext, prod-order-routing-line-ext, purchase-line-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Routing Line | Master value: the Coating Spec code the user enters per routing operation. Source for both the refresh path and the planning path. | Coating Spec (Code[20] (same number, type and length on every table; final length depends on q-coating-spec-master)): Editable; user-entered on the routing. Real DataClassification, never ToBeClassified. Add a TableRelation only if q-coating-spec-master confirms a master table, sized to the related key. | [1] [6] [8] |
| 2 | extend | tableextension | Planning Routing Line | Carries the value through the planning worksheet so orders created by carrying out planning get it from the planning routing lines they are built from. | Coating Spec (Code[20] (same number, type and length on every table; final length depends on q-coating-spec-master)): Same field number as on Routing Line. | [1] [5] |
| 3 | extend | tableextension | Prod. Order Routing Line | Holds the value on production order routing lines. Filled before insert on refresh and on carry-out; survives status changes (Planned/Firm Planned -> Released -> Finished) by record assignment, so no status-change code is needed. A refresh that recalculates routings deletes and rebuilds these lines, so a per-order manual change is reset to the routing value (see q-per-order-edit). | Coating Spec (Code[20] (same number, type and length on every table; final length depends on q-coating-spec-master)): Same field number as on Routing Line. Editability depends on q-per-order-edit. | [1] [3] [5] |
| 4 | extend | tableextension | Purchase Line | Holds the value on the subcontracting purchase order line created for the operation; set at the make-order step before the line is inserted. | Coating Spec (Code[20] (same number, type and length on every table; final length depends on q-coating-spec-master)): Same field number and length on every purchase TransferFields target below. | [2] [4] [5] |
| 5 | extend | tableextension | Purch. Rcpt. Line | Mirror target: posted receipt lines are created by InitFromPurchLine/TransferFields. Chosen by the mirroring article, not by the request; see q-posted-purchase-targets. | Coating Spec (Code[20] (same number, type and length on every table; final length depends on q-coating-spec-master)): Same field number, type and length as Purchase Line; non-editable. | [4] [5] |
| 6 | extend | tableextension | Purch. Inv. Line | Mirror target for posted invoice lines (TransferFields from Purchase Line). Chosen by the mirroring article; see q-posted-purchase-targets. | Coating Spec (Code[20] (same number, type and length on every table; final length depends on q-coating-spec-master)): Same field number, type and length as Purchase Line; non-editable. | [4] [5] |
| 7 | extend | tableextension | Purch. Cr. Memo Line | Mirror target for posted credit memo lines (TransferFields from Purchase Line). Chosen by the mirroring article; see q-posted-purchase-targets. | Coating Spec (Code[20] (same number, type and length on every table; final length depends on q-coating-spec-master)): Same field number, type and length as Purchase Line; non-editable. | [4] [5] |
| 8 | extend | tableextension | Return Shipment Line | Mirror target for return shipment lines (TransferFields from Purchase Line). Chosen by the mirroring article; see q-posted-purchase-targets. | Coating Spec (Code[20] (same number, type and length on every table; final length depends on q-coating-spec-master)): Same field number, type and length as Purchase Line; non-editable. | [4] [5] |
| 9 | extend | tableextension | Purchase Line Archive | Mirror target for archived purchase lines. Chosen by the mirroring article; see q-posted-purchase-targets. | Coating Spec (Code[20] (same number, type and length on every table; final length depends on q-coating-spec-master)): Same field number, type and length as Purchase Line; non-editable. | [4] [5] |
| 10 | create | codeunit | Coating Spec Copy (new subscriber codeunit) | Event subscribers that copy Coating Spec on the refresh path, the planning path, carry-out, and the subcontracting make-order step. |  | [1] [2] [7] |
| 11 | extend | pageextension | Routing lines subpage (page that lists Routing Line on the Routing card) | Lets users enter Coating Spec per operation. Tooltip on the table field (runtime 13.0+) or on the page control for earlier targets. |  | [10] [11] |
| 12 | extend | pageextension | Prod. Order Routing (page listing Prod. Order Routing Line) | Shows Coating Spec on production order routing lines, as the request requires. |  | [10] [11] |
| 13 | extend | pageextension | Purchase Order Subform | Shows Coating Spec on the subcontracting purchase order line. |  | [10] [11] |

## 3. How the data flows

- **User** → **Routing Line.Coating Spec**: entered by the user. Entered per operation on the routing. [1]
- **Routing Line** → **Prod. Order Routing Line (refresh: Refresh Production Order -> Calculate Prod. Order -> CopyFromRoutingLine)**: copied in an event subscriber. OnAfterCopyFromRoutingLine runs before insert; no Modify. Covers orders created by hand and refreshed. [1]
- **Routing Line** → **Planning Routing Line (Mfg. Planning Line Management -> TransferFromRoutingLine)**: copied in an event subscriber. OnAfterTransferFromRoutingLine runs before insert. [1]
- **Planning Routing Line** → **Prod. Order Routing Line (Mfg. Carry Out Action.TransferRouting -> CopyFromPlanningRoutingLine)**: copied in an event subscriber. OnAfterCopyFromPlanningRoutingLine; this path never reads Routing Line. [1]
- **Prod. Order Routing Line (old status)** → **Prod. Order Routing Line (new status: Released, Finished)**: other. Prod. Order Status Management copies the whole record by assignment, including extension fields; no subscriber. [3]
- **Prod. Order Routing Line (Released), read via Requisition Line keys** → **Purchase Line (Req. Wksh.-Make Order.InsertPurchOrderLine)**: copied in an event subscriber. OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine, before insert. Every subcontracting path (base Calculate Subcontracts, Subc. Calculate Subcontracts, Subcontracting app direct creation) meets here. [2]
- **Purchase Line** → **Purch. Rcpt. Line**: standard TransferFields copy. InitFromPurchLine; field number match. [4] [5]
- **Purchase Line** → **Purch. Inv. Line**: standard TransferFields copy. [4] [5]
- **Purchase Line** → **Purch. Cr. Memo Line**: standard TransferFields copy. [4] [5]
- **Purchase Line** → **Return Shipment Line**: standard TransferFields copy. [4] [5]
- **Purchase Line** → **Purchase Line Archive**: standard TransferFields copy. Archiving copies lines by field number. [4] [5]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Table "Prod. Order Routing Line" | `OnAfterCopyFromRoutingLine` | Refresh path: ProdOrderRoutingLine."Coating Spec" := RoutingLine."Coating Spec". | Assign only; runs before insert, so no Modify. | [1] |
| Table "Planning Routing Line" | `OnAfterTransferFromRoutingLine` | Planning path: PlanningRoutingLine."Coating Spec" := RoutingLine."Coating Spec". | Assign only; runs before insert, so no Modify. | [1] |
| Table "Prod. Order Routing Line" | `OnAfterCopyFromPlanningRoutingLine` | Carry-out path: ProdOrderRoutingLine."Coating Spec" := PlanningRoutingLine."Coating Spec". | Copy from the Planning Routing Line, not by looking up the master Routing Line. · Assign only; runs before insert, so no Modify. | [1] |
| Codeunit "Req. Wksh.-Make Order" | `OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine` | Set PurchOrderLine."Coating Spec" from the released Prod. Order Routing Line before the purchase line is inserted. | Exit unless RequisitionLine."Prod. Order No." and "Operation No." are filled (ordinary purchase lines use the same code) - cheap in-memory check before any database call. · Get(Status::Released, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.") with SetLoadFields("Coating Spec"); only assign when found. · Do not use the obsolete Calculate Subcontracts report events and do not patch purchase lines after carry-out. | [2] [7] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification on every Coating Spec table field (all nine table extensions) to a real classification - the manufacturing samples use CustomerContent - never ToBeClassified. Classification lives on the table fields, not on the page extensions. [8] [9]
- **other**: Tooltip: on runtime 13.0 (BC24) or later, define one ToolTip on the table field and let the bound page fields inherit it; for earlier targets add a page-level ToolTip on each page extension control. Text should say what the coating spec is used for, without inventing behavior. [10] [11]
- **permissions**: No new table or exposed object is designed, so no new permission set entry is required unless q-coating-spec-master adds a Coating Spec master table (then design its permissions with that entity). agent judgment

## 6. Tests

1. **refresh-copies-coating-spec** [1] [13] [14] [12]
    - Given An item with a routing whose operation has a random Coating Spec (fixtures built with the manufacturing/inventory Library codeunits, full chain: item, work center, routing certified, assigned to item)
    - When A released production order is created for the item and refreshed with routings calculated
    - Then The Prod. Order Routing Line for that operation has the routing line's Coating Spec
2. **planning-copies-to-planning-routing-line** [1] [13] [14] [12]
    - Given An item with demand, a certified routing whose operation has a Coating Spec, and a planning worksheet
    - When Calculate regenerative plan runs
    - Then The Planning Routing Line for that operation carries the Coating Spec
3. **carry-out-copies-from-planning-routing-line** [1] [12]
    - Given A planning line with Planning Routing Lines holding a Coating Spec (the value on the Planning Routing Line is changed so it differs from the master Routing Line)
    - When Carry Out Action Message creates a production order
    - Then The Prod. Order Routing Line has the Planning Routing Line value, not the master routing value
4. **status-change-keeps-coating-spec** [3] [12]
    - Given A firm planned production order whose routing line has a Coating Spec
    - When The order is changed to Released
    - Then The released Prod. Order Routing Line has the same Coating Spec, with no custom status-change code
5. **refresh-resets-manual-value** [1] [12]
    - Given A released production order whose routing line Coating Spec was changed by hand
    - When The order is refreshed with routings recalculated
    - Then The value is back to the master routing value (documents the behaviour for q-per-order-edit)
6. **subcontracting-po-line-gets-coating-spec** [2] [13] [14] [12]
    - Given A released production order whose operation runs on a work center with a subcontractor vendor and has a Coating Spec, plus the full vendor and posting setup
    - When Calculate Subcontracts runs and the subcontracting worksheet is carried out
    - Then The created Purchase Line for that operation has the routing line's Coating Spec
7. **subcontracting-direct-creation-gets-coating-spec** [2] [12]
    - Given The Microsoft Subcontracting app installed and a released order routing line with a Coating Spec on a subcontracting work center
    - When A subcontracting purchase order is created directly from the routing line
    - Then The Purchase Line has the Coating Spec (only if the app is in scope; see q-subcontracting-app)
8. **ordinary-purchase-line-unaffected** [2] [7] [12]
    - Given A requisition line for an item with no Prod. Order No. or Operation No.
    - When The requisition worksheet is carried out
    - Then The Purchase Line Coating Spec is blank and no error is raised (guard exits)
9. **posting-mirrors-coating-spec** [4] [14] [12]
    - Given A subcontracting purchase order line with a Coating Spec and the full posting-group chain
    - When The purchase order is posted (receive and invoice)
    - Then Purch. Rcpt. Line and Purch. Inv. Line carry the Coating Spec
10. **archive-mirrors-coating-spec** [4] [12]
    - Given A subcontracting purchase order line with a Coating Spec
    - When The purchase order is archived
    - Then Purchase Line Archive carries the Coating Spec

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Page object names for the routing lines, production order routing and purchase order subform extensions are the agent's judgment; BCQuality knowledge does not name them. Confirm against symbols.
- Permission step rests on the agent's judgment (no BCQuality article covers this case).
- bc-version, countries and application-area are unknown; ui/bound-page-field-inherits-source-field-tooltip.md applies only from BC24, and the Calculate Subcontracts obsolescence depends on the target version.

## Sources

[1] `microsoft/knowledge/manufacturing/copy-routing-line-fields-on-refresh-and-planning-paths.md`: Core mechanism: fields on Routing Line, Planning Routing Line and Prod. Order Routing Line, and the three copy subscriptions for refresh, planning and carry-out.
    - Add the field to Routing Line, Planning Routing Line and Prod. Order Routing Line.
    - Subscribe to OnAfterCopyFromRoutingLine and OnAfterCopyFromPlanningRoutingLine on Prod. Order Routing Line and OnAfterTransferFromRoutingLine on Planning Routing Line; all run before insert, so no Modify.
    - Do not rely only on Calculate Prod. Order OnAfterTransferRoutingLine: orders from the planning worksheet would have an empty field.
    - Do not fill the field in OnAfterInsertEvent by looking up Routing Line: extra Modify per operation and the wrong source for planned orders.
    - A refresh that recalculates routings deletes and rebuilds routing lines; a value typed per order is reset. State in the design whether per-order changes are allowed.
[2] `microsoft/knowledge/manufacturing/carry-routing-fields-to-subcontracting-purchase-lines.md`: Subcontracting purchase line: where every creation path meets and how to read the routing line.
    - Copy at the make-order step: subscribe to OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine on Req. Wksh.-Make Order.
    - Exit unless RequisitionLine "Prod. Order No." and "Operation No." are filled.
    - Read the routing line with Get(Status::Released, Prod. Order No., Routing Reference No., Routing No., Operation No.) and set the purchase line field before insert.
    - Do not depend on the obsolete Calculate Subcontracts report events (obsolete pending, tag 28.0; events obsolete for 29.0); the Subcontracting app direct path never passes through it.
    - Add the field to Requisition Line only if planners must see it, and the direct path does not fill it.
    - Do not patch purchase lines after Carry Out Action.
[3] `microsoft/knowledge/manufacturing/production-order-status-change-copies-whole-records.md`: Status changes of the production order carry the routing line field; no subscriber needed.
    - Add the field once on the production order table and rely on the status change record assignment to carry it.
    - Use the OnCopyFrom... events only to change a value on the way.
    - Do not re-copy in OnAfterTransProdOrder with Modify.
[4] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Posted purchase line and archive targets of the Purchase Line field.
    - Give the field the same number, name, type and length on Purchase Line and on every TransferFields target the plan needs; unless the plan states a document type never needs it, that means all four posted tables and the archive.
    - No subscriber is needed for these stages.
    - Keep the mirrored fields non-editable on the posted tables.
[5] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length agreement for every mirrored Coating Spec field.
    - Define mirrored fields with the exact same field number, data type and length on every table in the cascade at creation time.
[6] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Field length if Coating Spec gets a TableRelation to a master table (depends on q-coating-spec-master).
    - For an unconditional relation, give the field the same type and exact length as the related field; read the related field's declared length rather than assuming Code[20].
[7] `microsoft/knowledge/performance/guard-event-subscribers-before-db-call.md`: Make-order subscriber guard.
    - Open the subscriber with a cheap in-memory predicate before any database call.
    - Use SetLoadFields for the columns the body reads.
[8] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Data classification of the new fields.
    - Do not ship ToBeClassified; resolve to a real classification decided from the data's content.
[9] `microsoft/knowledge/privacy/data-classification-is-table-field-property.md`: Where classification is set.
    - DataClassification belongs on the table fields, not on page fields.
[10] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the page extension controls.
    - User-facing page fields need an explicit or inherited ToolTip; on runtime 13.0+ define it on the table field and omit duplicates; earlier targets need page-level tooltips.
    - Tooltip text should say what the value is used for and must not invent behaviour.
[11] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Tooltip inheritance on bound page fields; applies from BC24 (bc-version unknown).
    - On runtime 13.0 or later a bound page field inherits the table field ToolTip; do not add a duplicate page-level property.
[12] `microsoft/knowledge/testing/test-one-when-per-test.md`: Test shape.
    - Exactly one WHEN per test; precondition actions (refresh, release, posting) go in GIVEN unless they are the action under test.
[13] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Build items, routings, work centers, vendors and orders with the Library codeunits, parents first, validating foreign keys; no hand-rolled Init/Insert.
[14] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Test preconditions for subcontracting and posting tests.
    - GIVEN must set up every precondition the process reads, e.g. the full posting-group chain for posting tests and the subcontracting work center and vendor for subcontracting tests.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
