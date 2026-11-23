# Feature design

> Our main warehouse uses directed put-away and pick with Pick According to FEFO. Quality wants a Quarantine status per lot: quarantined lots must never be proposed on warehouse picks, and pickers must not be able to scan a quarantined lot onto a pick line. Scanners also assign lots to warehouse journal lines during adjustments. Please design it.

**Result:** Complete design. **Business process:** Warehouse handling at a Directed Put-away and Pick location: pick creation with Pick According to FEFO, lot entry and registration on warehouse picks, and warehouse journal adjustments with lot tracking. **Knowledge used:** 17 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Must a quarantined lot be stopped only on warehouse picks, or everywhere (sales, consumption, transfers, adjustments)? If everywhere, the standard Blocked field on Lot No. Information does this with no code and this design is replaced. _(affects: lot-quality-status-enum, lot-info-quality-status-ext, lot-quality-pick-guard)_
2. Should scanners be allowed to assign a quarantined lot to a warehouse journal line during adjustments (for example to scrap or count quarantined stock)? The design leaves adjustments unblocked. _(affects: lot-quality-pick-guard, whse-journal-adjustment-of-quarantined-lot)_
3. Is the scanner integration part of this app or an existing solution? Does it validate Lot No. on pick lines (so the entry check fires) and write Whse. Item Tracking Line rows for journal lines, or does it assign fields directly? _(affects: lot-quality-pick-guard, scan-quarantined-lot-on-pick-rejected, whse-journal-adjustment-of-quarantined-lot)_
4. How should a lot with no Lot No. Information record be treated: released (the design's assumption) or quarantined until Quality creates the record? _(affects: lot-quality-pick-guard, lot-info-quality-status-ext)_
5. Should quarantined lots also be stopped on warehouse movements, internal picks or movement worksheets, or must they stay movable (for example into a quarantine bin)? _(affects: lot-quality-pick-guard, movement-of-quarantined-lot-not-blocked)_
6. Should assigning a quarantined lot in item tracking on a sales or transfer line be blocked before the shipment is created, or is rejection at pick registration enough? _(affects: lot-quality-pick-guard, register-rejects-source-tracked-quarantined-lot)_
7. Which users may change Quality Status, and does Quality need a history of status changes? _(affects: lot-info-quality-status-ext, lot-info-card-ext)_
8. Are statuses other than Released and Quarantine needed (for example Rejected), and should they also stop picking? _(affects: lot-quality-status-enum, lot-quality-pick-guard)_
9. Which Business Central version does the app target? It decides whether the tooltip is defined on the table field (BC24+) or on the pages, and the events must be confirmed in that version's symbols. _(affects: lot-info-quality-status-ext, lot-info-card-ext, lot-info-list-ext, lot-quality-pick-guard)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | create | enum | Lot Quality Status | Per-lot quality status with values Released (ordinal 0) and Quarantine (ordinal 1). Extensible; later values (if Quality asks for more, see open questions) are appended at the end and never renumbered. |  | [1] [10] |
| 2 | extend | tableextension | Lot No. Information | Stores the quality status on the record the warehouse already reads per lot (item, variant, lot). The status is read from here at the moment it is needed and is not copied to warehouse entries, item ledger entries or tracking lines, because it changes after the stock is posted. | Quality Status (Enum "Lot Quality Status"): DataClassification = CustomerContent on the table field. No InitValue: Released is ordinal 0, so existing Lot No. Information rows read as Released without upgrade code. On BC24/runtime 13.0 or later, define the ToolTip here so page fields inherit it. | [1] [5] [9] [11] [12] |
| 3 | extend | pageextension | Lot No. Information Card | Lets Quality view and set Quality Status on a lot. The page carries no business logic; the tooltip is inherited from the table field (BC24+) or declared on the page for earlier runtimes. |  | [12] |
| 4 | extend | pageextension | Lot No. Information List | Shows Quality Status in the lot list so quarantined lots can be found and filtered. Tooltip handling as on the card. |  | [12] |
| 5 | create | codeunit | Lot Quality Pick Guard | Holds the three subscribers that keep quarantined lots off warehouse picks (FEFO suggestion, lot entry on pick lines, registration) and one IsQuarantined(ItemNo, VariantCode, LotNo) helper that exits on a blank lot, then reads Lot No. Information with SetLoadFields("Quality Status") and Get. The entry and registration checks act only on lines with Activity Type = Pick, so movements and warehouse journal adjustments are not blocked (see open questions). Enforcement sits where the lot is used, not in Lot No. Information triggers. |  | [1] [6] [7] [8] |

## 3. How the data flows

- **Quality user** → **Lot No. Information."Quality Status"**: entered by the user. Set on the Lot No. Information Card. The value stays only on Lot No. Information and is read live by the guard. [1] [5]
- **Lot No. Information."Quality Status"** → **Whse. Item Tracking FEFO lot suggestions used by Create Pick**: other. OnAfterIsItemTrackingBlocked sets IsBlocked for a quarantined lot, so FEFO skips it when Create Pick proposes lots. FEFO runs only with Pick According to FEFO (or Strict Expiration Posting) and warehouse tracking on the item. [1] [2] [4]
- **Shipment Whse. Item Tracking Line rows (source tracking)** → **Warehouse Activity Line."Lot No." on the created pick**: other. Create Pick uses the source line's tracking before FEFO, so a lot pre-assigned on the sales or transfer line is not filtered by the FEFO event. The registration check is the guard on this path. [2] [3] [1]
- **Scanner or picker** → **Warehouse Activity Line."Lot No." (take line and matching place line)**: field validation. The lot is validated on the take line and on its matching place line. OnBeforeValidateLotNo rejects a quarantined lot when it is entered. A scanner that assigns the field without Validate bypasses this check and is caught only at registration. [1] [2]
- **Registered pick lines** → **Warehouse Entry and source line Reservation Entry**: other. Standard registration copies the lot to the warehouse journal line and warehouse entry and synchronizes it to the source line. OnCheckWhseItemTrkgLineOnBeforeTestTracking runs first and rejects lines whose lot is quarantined, including lines created before the status changed. No custom copy of the lot or status is added. [1] [2] [5]
- **Scanner during adjustment** → **Whse. Item Tracking Line for the Warehouse Journal Line**: field validation. Lots for a warehouse journal line are written as Whse. Item Tracking Line rows keyed Source ID = batch name, Source Batch Name = template name, Source Ref. No. = line number, validating Lot No. and Quantity (Base); setting Lot No. on the journal line directly fails at registration. The quarantine guard does not act on this path in this design. [3] [4]
- **Registered warehouse adjustment** → **Item Ledger Entry (through Calculate Whse. Adjustment and Item Jnl.-Post Batch)**: other. The standard reconciliation step carries the adjustment and its tracking to the item ledger. No quarantine check is added to this path, so quarantined stock can still be reconciled. [13]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Whse. Item Tracking FEFO" | `OnAfterIsItemTrackingBlocked(var ReservEntry, ItemNo, VariantCode, LotNo, var IsBlocked, ItemTrackingSetup)` | Mark a quarantined lot as blocked so FEFO does not propose it on picks created by Create Pick. | Exit when IsBlocked is already true, so the standard Blocked flag is never cleared and no database read is spent. · Exit on a blank LotNo before any database call. · Read Lot No. Information with SetLoadFields("Quality Status") and Get; a missing record is treated as not quarantined (pending open question). | [1] [7] [8] |
| Table "Warehouse Activity Line" | `OnBeforeValidateLotNo(var WarehouseActivityLine)` | Reject a quarantined lot typed or scanned on a pick line, with an error label naming lot and item. | Exit unless Activity Type = Pick (cheap in-memory check before the database read). · Exit on a blank Lot No. · Read only Quality Status with SetLoadFields. | [1] [6] [7] [8] |
| Codeunit "Whse.-Activity-Register" | `OnCheckWhseItemTrkgLineOnBeforeTestTracking(WarehouseActivityLine, var WhseItemTrackingSetup)` | Final check before a pick is registered: reject any non-place line whose lot is quarantined, covering lines from source tracking, lines filled without Validate, and lines created before the lot was quarantined. | Exit unless Activity Type = Pick; inventory movements also raise this event and are not blocked. · Exit on a blank Lot No. · Read only Quality Status with SetLoadFields. · Runs only for items with warehouse tracking, which the setup step requires. | [1] [6] [7] [8] |

## 5. Setup, permissions and lifecycle

- **setup**: Require Lot Warehouse Tracking on the item tracking code of every lot item handled at the main warehouse, and Pick According to FEFO on the location. Decide this before the first warehouse posting, because the warehouse flags cannot change once warehouse entries exist. Any setup validation the app adds branches on GetWhseItemTrkgSetup and its Lot No. Required field, not on Item Tracking Code or Lot Specific Tracking. [4] [1]
- **install**: No install or upgrade data code: Quality Status has no InitValue and Released is ordinal 0, so existing Lot No. Information rows read as Released. Future enum values are appended at the end only. [11] [10]
- **privacy**: Classify Quality Status as CustomerContent on the table extension field; the page extensions carry no classification. [9]
- **permissions**: Ship a permission set for the new codeunit and decide which role may modify Lot No. Information to change Quality Status (see open questions). Not covered by the BCQuality knowledge selected for this design. agent judgment

## 6. Tests

1. **fefo-pick-skips-quarantined-lot** [1] [2] [16] [15] [17]
    - Given A Directed Put-away and Pick location with Pick According to FEFO, an item whose tracking code has Lot Warehouse Tracking and expiration dates, two lots put away in pick bins where the earlier-expiring lot has Quality Status = Quarantine, and a released sales order with a warehouse shipment, all created with library codeunits
    - When Create Pick runs from the warehouse shipment
    - Then Every pick take line carries the released lot; none carries the quarantined lot
2. **fefo-pick-proposes-lot-after-release** [1] [2] [15] [17]
    - Given The same setup, with the earlier-expiring lot first quarantined and then set back to Released
    - When Create Pick runs from the warehouse shipment
    - Then FEFO proposes the earlier-expiring lot first, showing the status is read live and not copied
3. **scan-quarantined-lot-on-pick-rejected** [1] [14] [15] [17]
    - Given A pick line for a warehouse-tracked lot item without a lot, and a lot in the take bin with Quality Status = Quarantine
    - When Lot No. is validated on the take line with the quarantined lot
    - Then asserterror fails with the full quarantine label text built with StrSubstNo (Assert.ExpectedError) and Assert.ExpectedErrorCode, and the line keeps a blank lot
4. **scan-released-lot-registers-to-entries** [2] [1] [16] [17]
    - Given A pick line without a lot and a released lot with enough quantity in the take bin
    - When The lot is validated on the take line and its matching place line and the pick is registered
    - Then Warehouse entries for both the take and the place carry the lot, and the sales line's item tracking shows the picked lot
5. **register-rejects-lot-quarantined-after-pick** [1] [6] [14] [17]
    - Given A pick created with a released lot on its lines, after which the lot is set to Quarantine
    - When The pick is registered
    - Then Registration fails with the quarantine error (pinned with ExpectedError and ExpectedErrorCode) and no warehouse entry is created for the lot
6. **register-rejects-source-tracked-quarantined-lot** [1] [2] [3] [14] [17]
    - Given A sales line tracked to a lot through item tracking before the warehouse shipment is created, the lot then set to Quarantine, and a pick created from the shipment
    - When The pick is registered
    - Then Registration fails with the quarantine error, because source tracking bypasses the FEFO suggestion
7. **movement-of-quarantined-lot-not-blocked** [1] [17]
    - Given A warehouse movement line for a quarantined lot
    - When The lot is validated on the movement line and the movement is registered
    - Then No quarantine error is raised and the warehouse entries carry the lot (behavior pending the open question on movements)
8. **whse-journal-adjustment-of-quarantined-lot** [3] [13] [16] [17]
    - Given A warehouse item journal line for a quarantined lot with its lot written as a Whse. Item Tracking Line keyed to the journal line
    - When The journal is registered, then Calculate Whse. Adjustment and Item Jnl.-Post Batch run on an empty dedicated item journal batch
    - Then The warehouse entry and the resulting item ledger entry carry the lot and no quarantine error is raised (behavior pending the open question on adjustments)

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Applicability dimensions bc-version, countries and application-area are unknown; no repository was supplied.
- Permission set content and the role allowed to change Quality Status rest on the agent's judgment; not covered by BCQuality knowledge selected for this design.
- Whether a custom status set through OnAfterIsItemTrackingBlocked also reduces the pickable quantity in Bin Content (as standard Blocked does through CalcQtyWithBlockedItemTracking) is not stated in the opened knowledge; Create Pick may leave quantity on blank-lot lines, which the entry and registration checks still guard.
- No opened article names an event that filters lots coming from source tracking during Create Pick; the design relies on the registration check for that path.

## Sources

[1] `microsoft/knowledge/warehouse/exclude-lots-from-warehouse-picks-through-lot-no-information.md`: Core mechanism: per-lot status on Lot No. Information, the three verified events, the pick-only guard codeunit and its tests.
    - If the lot must not be used anywhere, set Blocked on Lot No. Information and write no code; a status that stops warehouse picking only goes on Lot No. Information through a table extension.
    - Read the status by item, variant and lot when needed; do not copy it into warehouse or ledger entries, because it changes after the stock is posted.
    - Subscribe to all three events: OnAfterIsItemTrackingBlocked (FEFO suggestions), OnBeforeValidateLotNo (typed or scanned lot), OnCheckWhseItemTrkgLineOnBeforeTestTracking (final check at registration).
    - FEFO runs only with Pick According to FEFO or Strict Expiration Posting and warehouse tracking; without FEFO the FEFO event alone is not enough.
    - Do not delete pick lines with the lot after Create Pick; it leaves the shipment partly unpicked and skips the warehouse's availability logic.
[2] `microsoft/knowledge/warehouse/lot-and-serial-on-warehouse-picks-come-from-whse-tracking-and-reach-warehouse-entries.md`: Order in which Create Pick fills lots (source tracking, FEFO, blank), take and place line handling, and what registration writes.
    - Create Pick fills lots from source tracking first, then FEFO for the untracked rest, then leaves the lot blank for the worker.
    - When code sets a lot on an existing pick, validate Lot No. on the take line and on its matching place line.
    - Do not write the picked lot back to the source line's Reservation Entry rows after registration; registration already synchronizes it.
    - For expiry-driven picking use Pick According to FEFO rather than sorting lots in custom code; read lot stock per bin from Bin Content with Lot No. Filter or Warehouse Entry, not Item Ledger Entry.
[3] `microsoft/knowledge/warehouse/assign-lots-on-warehouse-documents-through-the-table-each-document-reads.md`: Scanner lot assignment on warehouse journal lines and the source-tracking path into picks.
    - For a warehouse journal line, insert Whse. Item Tracking Line rows as the page does: GetNextEntryNo, SetSource with Source ID = batch name, Source Batch Name = template name, Source Ref. No. = line number, fill item, variant, location and Qty. per Unit of Measure, then validate Lot No. and Quantity (Base).
    - Do not set Lot No. directly on a Warehouse Journal Line for a tracked item; registration requires the Whse. Item Tracking Line rows and fails.
    - Picks for a shipment read the shipment's Whse. Item Tracking Line rows copied when the shipment line was created, not Reservation Entry.
    - All of this requires warehouse tracking on the item tracking code.
[4] `microsoft/knowledge/warehouse/enable-lot-warehouse-tracking-before-relying-on-lots-in-wms-locations.md`: Setup prerequisite: Lot Warehouse Tracking on the item tracking code so FEFO, pick-line lots and registration checks apply.
    - Include warehouse tracking on the item tracking code when a feature needs lots in bins, picks or put-aways, and check it in setup validation.
    - Branch on GetWhseItemTrkgSetup and its Lot No. Required field, not on Item Tracking Code or Lot Specific Tracking.
    - Decide the setting before the first warehouse posting; the warehouse flags cannot change once warehouse entries exist.
    - Create Pick applies neither Pick According to FEFO nor Strict Expiration Posting without warehouse tracking.
[5] `microsoft/knowledge/inventory/carry-item-tracking-line-fields-to-item-ledger-entries.md`: Decision to keep the status on Lot No. Information and not carry it through tracking lines and posting.
    - When the value describes the lot itself and never differs per document, store it on Lot No. Information, keyed by item, variant and lot, and read it from there instead of copying it through posting.
[6] `microsoft/knowledge/data-modeling/check-blocked-in-referencing-code-not-in-master.md`: Placing the quarantine check at the point of use (pick line entry) and again before registration, not in Lot No. Information triggers.
    - Enforce a block in the consuming code at the point of use and re-check before posting; the master record stays logic-free on the flag.
    - An option-style block needs the specific value compared at each relevant path.
[7] `microsoft/knowledge/performance/guard-event-subscribers-before-db-call.md`: Ordering of the subscriber guards before the Lot No. Information read.
    - Open each subscriber with an in-memory check (activity type, blank lot, IsBlocked already set) before any database call.
[8] `microsoft/knowledge/performance/use-setloadfields-for-partial-records.md`: The Lot No. Information read in IsQuarantined.
    - Call SetLoadFields listing only the fields read (Quality Status) immediately before the Get.
[9] `microsoft/knowledge/privacy/data-classification-is-table-field-property.md`: Data classification of the new field.
    - DataClassification belongs on the table field; pages have no classification property.
[10] `microsoft/knowledge/upgrade/enum-values-additive-at-end.md`: Evolution of the Lot Quality Status enum.
    - Add new enum values only after the last existing value with a higher ordinal; never renumber; retire values through ObsoleteState rather than deleting.
[11] `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`: Deciding that no upgrade code is needed for existing Lot No. Information rows.
    - InitValue does not back-fill existing rows; a new field whose intended value for existing rows differs from the datatype default needs upgrade code guarded by an upgrade tag. Here the default ordinal 0 is Released, so none is needed.
[12] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltip for Quality Status on the Lot No. Information pages; table-field tooltip inheritance applies from BC24 (runtime 13.0).
    - On runtime 13.0 or later, define the tooltip on the table field and do not duplicate it on the pages; before runtime 13.0, declare it on the page fields.
    - Make the tooltip state what the value is used for (it stops the lot from being picked) without inventing behavior.
[13] `microsoft/knowledge/scm/reconcile-warehouse-adjustments-with-the-item-ledger.md`: How warehouse journal adjustments of lots reach the item ledger at a Directed Put-away and Pick location.
    - After warehouse registration, Calculate Whse. Adjustment prepares item journal lines and Item Jnl.-Post Batch posts them; a manually mirrored item journal line does not reconcile the adjustment.
[14] `microsoft/knowledge/testing/asserterror-needs-expectederror-and-code.md`: Negative tests for the quarantine error.
    - Follow every asserterror with Assert.ExpectedError using the full label text built with StrSubstNo, together with Assert.ExpectedErrorCode.
[15] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for items, locations, lots and documents.
    - Build fixtures with the Library codeunits, parents first, validating foreign keys, not with hand-rolled Init/Insert.
[16] `microsoft/knowledge/testing/given-blocks-must-cover-full-precondition-chain.md`: Complete warehouse preconditions in GIVEN blocks.
    - Set up every precondition the path reads: location with directed put-away and pick and FEFO, item tracking code with lot warehouse tracking and expiration, bins and stock per lot, and posting setup; include both a lot that should and one that should not be proposed.
[17] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit.
    - Put [FEATURE] on the codeunit and [SCENARIO], [GIVEN], [WHEN], [THEN] comments in each test.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
