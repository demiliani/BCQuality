# Feature design

> Add Storage Zone and New Storage Zone to the item reclassification journal so the outbound item ledger entry keeps the old zone and every inbound entry gets the new zone, and make scanner-imported journal lines refuse items that need a variant when none is given, following the Business Central variant setup.

**Result:** Complete design. **Business process:** Inventory item journals: item reclassification journal posting through Item Jnl.-Post Line, plus creation of item journal lines from an external scanner import. **Knowledge used:** 17 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. Is Storage Zone a free code, a reference to an existing table (for example the warehouse Zone table, which is keyed by location), or a new master table you want created? This decides the TableRelation, the field length and whether a new entity with page, permissions and data rules is needed. _(affects: item-jnl-line-storage-zone, item-ledger-entry-storage-zone, storage-zone-permissionset)_
2. When New Storage Zone is blank on a reclassification line, should the inbound entries keep the old zone, get a blank zone, or should posting be refused? Should New Storage Zone default from Storage Zone when the line is created? _(affects: storage-zone-reclass-posting, reclass-inbound-entries-get-new-zone)_
3. Where does the old Storage Zone come from: entered by the user/scanner, or defaulted from the item ledger entries being moved? Must posting check that it matches the zone of the applied entries? _(affects: item-jnl-line-storage-zone, storage-zone-reclass-posting)_
4. How does the scanner app deliver lines to Business Central (API page, OData web service, XMLport/file, or another integration)? Which journal template and batch receive them, and are the lines always reclassification lines? _(affects: scanner-reclass-line-import, storage-zone-permissionset)_
5. When one scanned line is refused for a missing variant, should the whole import fail, or should the other lines be created and the refused ones reported back to the scanner app? _(affects: scanner-reclass-line-import, import-refuses-missing-variant-setup-default)_
6. Does the scanner payload include Storage Zone and New Storage Zone, or are they entered in Business Central after import? _(affects: scanner-reclass-line-import)_
7. OnAfterInitItemLedgEntry also runs for other item journals and for transfer orders. Should Storage Zone also be recorded for those postings (positive/negative adjustments, transfer orders), or only for reclassification? _(affects: storage-zone-reclass-posting, transfer-order-entries-unaffected)_
8. At locations with bins, should Warehouse Entries also carry the storage zone? This needs fields on Warehouse Journal Line and Warehouse Entry and a confirmed path for reclassification lines, which is not designed here. _(affects: item-ledger-entry-storage-zone)_
9. Should Storage Zone be shown on the Item Ledger Entries page or other inquiry pages? _(affects: item-ledger-entry-storage-zone)_
10. Which Business Central version does the app target? From BC24 (runtime 13.0) tooltips can live on the table fields; earlier targets need page-level tooltips. _(affects: item-reclass-journal-page-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Item Journal Line | Holds the old zone (Storage Zone) and the zone after reclassification (New Storage Zone), following the standard New ... pattern of reclassification fields such as New Location Code. | Storage Zone (Code[10]): Copied to every item ledger entry the line posts. DataClassification = CustomerContent (never ToBeClassified). Type and length follow the sample; if a TableRelation is added (see open question), size it exactly to the related key field.; New Storage Zone (Code[10]): Applied only to the positive (inbound) entries of a reclassification. Same type and length as Storage Zone. DataClassification = CustomerContent. | [1] [9] [10] |
| 2 | extend | tableextension | Item Ledger Entry | Stores the zone of each posted entry: the old zone on the negative entry and the new zone on each positive entry. Non-editable; filled only by the posting subscribers, never patched after posting. | Storage Zone (Code[10]): Editable = false. DataClassification = CustomerContent. Same type and length as the journal field. | [1] [2] [5] |
| 3 | create | codeunit | Storage Zone Reclass Posting | Holds the two posting subscribers on Item Jnl.-Post Line: copy Storage Zone in OnAfterInitItemLedgEntry (all entries), then overwrite with New Storage Zone in OnBeforeInsertTransferEntry (positive entries only). |  | [1] [2] |
| 4 | extend | pageextension | Item Reclass. Journal | Shows Storage Zone and New Storage Zone on the reclassification journal lines so users can enter them. Presentation only; no business logic on the page. Tooltips are defined on the table fields and inherited from BC24 (runtime 13.0); before that the page controls need their own ToolTip. |  | [13] [14] |
| 5 | create | codeunit | Scanner Item Jnl. Line Import | Creates item journal lines from scanner data. Before building a line it calls Item.IsVariantMandatory() and raises a clear error when it returns true and no variant code was supplied; it never reads Inventory Setup or the item option itself. It then validates fields in order: Item No., Variant Code, Location Code, Bin Code, Unit of Measure Code, Quantity, and the storage-zone fields. The line is posted only through the journal (Item Jnl.-Post Batch / Item Jnl.-Post Line), never by inserting ledger entries. The transport that calls this codeunit (API page, XMLport, file) is not designed here; see open question. |  | [3] [4] [5] [14] |
| 6 | create | permissionset | Storage Zone - Edit | Grants execute on the new codeunits and on whatever object the scanner app calls; composed from a non-assignable building block through IncludedPermissionSets. |  | [11] [12] [8] |

## 3. How the data flows

- **User or scanner input** → **Item Journal Line.Storage Zone / New Storage Zone (reclassification journal)**: entered by the user. Entered on the Item Reclass. Journal page or set by the scanner import codeunit with Validate. [1]
- **Item Journal Line.Storage Zone** → **Item Ledger Entry.Storage Zone (negative/outbound entry and initial value of every positive entry)**: copied in an event subscriber. Subscriber to Item Jnl.-Post Line OnAfterInitItemLedgEntry. Runs for the negative entry and every positive entry; it must not try to tell the sides apart. [1] [2]
- **Item Journal Line.New Storage Zone** → **Item Ledger Entry.Storage Zone (each positive/inbound entry)**: copied in an event subscriber. Subscriber to Item Jnl.-Post Line OnBeforeInsertTransferEntry, which runs only for the positive entries; one line can produce several positive entries unless the item uses average cost. [1]
- **Scanner line data (item, variant, location, bin, unit of measure, quantity, zones)** → **Item Journal Line**: field validation. Item.IsVariantMandatory() check first; then Validate in the order Item No., Variant Code, Location Code, Bin Code, Unit of Measure Code, Quantity so blocked-variant checks run, the bin is not cleared, and base quantity is derived. [3] [4]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Item Jnl.-Post Line" | `OnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: BigInteger)` | Copy Item Journal Line.Storage Zone to every item ledger entry the line creates (negative entry and the initial state of each positive entry). | Do not branch on NewItemLedgEntry.Quantity > 0 or Location Code here: every transfer entry of a normal line is still negative and at the old location at this point. · Do not set the new zone here and do not rely on the positive entry inheriting from the negative entry; it is rebuilt from the journal line. | [1] [2] |
| Codeunit "Item Jnl.-Post Line" | `OnBeforeInsertTransferEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")` | Overwrite Storage Zone with New Storage Zone on each positive (inbound) transfer entry. | Apply only when New Storage Zone is not blank, as the sample does; transfer orders also reach this event and their journal lines carry no New Storage Zone (blank-handling rule pending open question). | [1] [6] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification = CustomerContent on Storage Zone and New Storage Zone in both table extensions; no field may ship as ToBeClassified. [10]
- **permissions**: Ship a non-assignable building-block permission set with execute on Storage Zone Reclass Posting and Scanner Item Jnl. Line Import, plus an explicit = X entry for the API page, query or web-service object the scanner app calls; include it from an assignable role set through IncludedPermissionSets. [11] [12]
- **setup**: No new setup table: the variant rule is read from the standard Inventory Setup and Item fields only through Item.IsVariantMandatory(). [3]

## 6. Tests

1. **reclass-outbound-entry-keeps-old-zone** [1] [15] [17]
    - Given An item with inventory created through LibraryInventory, and a reclassification journal line with Storage Zone = A and New Storage Zone = B (random codes from library helpers).
    - When The reclassification journal line is posted.
    - Then The negative item ledger entry for the line has Storage Zone = A.
2. **reclass-inbound-entries-get-new-zone** [1] [15]
    - Given A FIFO (non-average-cost) item with two separate positive inventory entries, and one reclassification line whose quantity applies to both, with Storage Zone = A and New Storage Zone = B.
    - When The reclassification journal line is posted.
    - Then Every positive item ledger entry created by the line (two of them) has Storage Zone = B.
3. **transfer-order-entries-unaffected** [6]
    - Given A transfer order for an item, with the extension installed.
    - When The transfer order is shipped and received.
    - Then Posting succeeds and the resulting item ledger entries have a blank Storage Zone (unless the transfer-order open question decides otherwise).
4. **import-refuses-missing-variant-setup-default** [3] [16]
    - Given Inventory Setup Variant Mandatory if Exists = true, an item with Variant Mandatory if Exists = Default and at least one item variant.
    - When The scanner import creates a line for the item with no variant code.
    - Then The import raises the variant-required error; asserterror is followed by Assert.ExpectedError with the full label text built with StrSubstNo, and no journal line exists.
5. **import-refuses-missing-variant-item-yes** [3] [16]
    - Given Inventory Setup Variant Mandatory if Exists = false, an item with Variant Mandatory if Exists = Yes and at least one item variant.
    - When The scanner import creates a line for the item with no variant code.
    - Then The import raises the variant-required error, verified with Assert.ExpectedError.
6. **import-accepts-item-no-or-without-variants** [3]
    - Given Inventory Setup Variant Mandatory if Exists = true, and either an item with Variant Mandatory if Exists = No that has variants, or a Default item with no item variants.
    - When The scanner import creates a line for the item with no variant code.
    - Then The journal line is created with a blank Variant Code.
7. **import-rejects-blocked-variant** [3] [16]
    - Given An item with a variant that is Blocked.
    - When The scanner import creates a line for that item and variant.
    - Then Validating Variant Code raises the standard blocked-variant error, verified with Assert.ExpectedError.
8. **import-keeps-bin-and-base-quantity** [3] [4]
    - Given A bin-mandatory location, an item with a variant and a non-base unit of measure (Qty. per Unit of Measure > 1).
    - When The scanner import creates a line with variant, bin, unit of measure and quantity.
    - Then The line keeps the imported Bin Code and Quantity (Base) equals Quantity times Qty. per Unit of Measure.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown; all cited articles apply to bc-version [all], countries [w1] and application-area [all], so applicability is not affected.
- The page name "Item Reclass. Journal" as the extension target is not named in any opened article; confirm it in the target version's symbols (agent judgment).
- The transport object for the scanner import (API page, XMLport or other) is not designed because the request does not say how lines arrive; see open question scanner-transport.

## Sources

[1] `microsoft/knowledge/inventory/item-reclassification-posts-two-entries-from-one-journal-line.md`: Core mechanism: journal fields, the two posting subscribers, and the tests for outbound and inbound entries.
    - A reclassification line posts a negative entry and one positive entry per applied entry (unless average cost); OnAfterInitItemLedgEntry runs for all of them with the same journal line.
    - For a value the reclassification changes, add a second New ... journal field; copy the old value in OnAfterInitItemLedgEntry and overwrite it with the new value in OnBeforeInsertTransferEntry, which runs only for positive entries.
    - Do not tell the sides apart in OnAfterInitItemLedgEntry with Quantity > 0 or Location Code; every transfer entry is still negative and at the old location there.
    - Do not set the value on the negative entry and expect the positive entry to inherit it; the positive entry is rebuilt from the journal line.
[2] `microsoft/knowledge/inventory/carry-item-journal-fields-to-item-and-phys-inventory-ledger.md`: Confirms OnAfterInitItemLedgEntry as the subscriber that copies a journal field to the item ledger entry, and that table extension fields survive the tracking split.
    - Add the field to Item Journal Line and to each ledger table needed; copy it to the item ledger entry in OnAfterInitItemLedgEntry on Item Jnl.-Post Line.
    - Do not patch ledger entries after posting by document number.
[3] `microsoft/knowledge/inventory/check-variant-requirements-through-item-is-variant-mandatory.md`: Variant rule for scanner-imported lines and its tests.
    - When lines are created from an import, decide the variant before release or posting: call Item.IsVariantMandatory() and stop with a clear error when it returns true and no variant is known.
    - Do not rebuild the rule from Inventory Setup alone or test only the item field for Yes; IsVariantMandatory combines setup, the item's Default/No/Yes option, and whether any variant (blocked included) exists.
    - Set the variant with Validate after Item No. and before quantity, unit of measure and bin, so blocked checks run and the bin is not cleared; never assign Variant Code directly.
[4] `microsoft/knowledge/scm/derive-base-quantities-through-the-line-unit-of-measure.md`: Field order and quantity handling in the scanner import.
    - Validate Unit of Measure Code before Quantity, and validate both; never assign Quantity, Qty. per Unit of Measure or a (Base) field directly on a line that is posted.
[5] `microsoft/knowledge/scm/post-item-ledger-changes-through-item-journals.md`: Imported lines and zone values reach the ledger only through journal posting.
    - Post prepared journal lines through Item Jnl.-Post Line.RunWithCheck or persisted batches through Item Jnl.-Post Batch.
    - Do not insert, delete or overwrite posted quantity, application or cost fields of Item Ledger Entry or Value Entry outside posting; a custom annotation field filled within posting is outside this concern.
[6] `microsoft/knowledge/warehouse/carry-transfer-line-fields-to-item-ledger.md`: Shows that transfer-order posting also runs OnAfterInitItemLedgEntry for both entries, which motivates the blank guard and the transfer-order test and open question.
    - Transfer journal lines are built by the transfer posting codeunits and post a negative and a positive entry through InsertTransferEntry; OnAfterInitItemLedgEntry runs for each.
    - If only some transfer legs should carry the value, decide in the journal-line subscribers of the transfer codeunits, not in OnAfterInitItemLedgEntry.
[7] `microsoft/knowledge/warehouse/carry-fields-to-warehouse-entries-through-the-warehouse-journal-line.md`: Basis for the open question on whether warehouse entries at bin locations must also carry the zone; not designed because the request does not ask for it.
    - A custom field reaches Warehouse Entry only if it is on Warehouse Journal Line and copied in OnBeforeInsertWhseEntry on Whse. Jnl.-Register Line.
    - For a path other than document posting, confirm in the target version where its warehouse journal line is built before designing the subscriber; do not modify warehouse entries after posting.
[8] `microsoft/knowledge/feature-design/plan-a-new-business-entity-end-to-end.md`: Decision list applied to the open question of a Storage Zone master table and to permissions and tests.
    - If Storage Zone becomes a new record type, plan table type, numbering, setup, data rules, privacy, pages, permissions, install/upgrade and tests together.
    - A decision the request does not settle is a question for the requester, not a default to assume.
[9] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Applies if the zone fields get a TableRelation (open question).
    - For an unconditional TableRelation the field must have the same type and exact length as the related field; read the related field's declared length rather than assuming Code[10] or Code[20].
[10] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Data classification of the new fields.
    - Do not ship any field with DataClassification = ToBeClassified; choose a real classification from the data's content.
[11] `microsoft/knowledge/security/exposed-objects-must-be-in-a-permission-set.md`: Permission entry for the object the scanner app calls.
    - Every page, query or codeunit reachable from outside the app's UI needs an explicit = X entry in a permission set the app ships; prefer an API page over a new SOAP codeunit web service.
[12] `microsoft/knowledge/security/compose-permission-sets-with-included-sets.md`: Structure of the permission set.
    - Ship focused building blocks with Assignable = false and assemble assignable role sets through IncludedPermissionSets instead of duplicating object lists.
[13] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the journal page fields; applies from BC24 (runtime 13.0) for inheritance from table fields.
    - From runtime 13.0 define the tooltip on the table field and let the bound page field inherit it; before runtime 13.0 user-facing page fields need a page-level ToolTip.
    - Tooltip text must say what the value is used for or what changing it affects, not just repeat the caption, and must not invent behavior.
[14] `microsoft/knowledge/style/pages-must-not-contain-business-logic.md`: Keeps the variant check and line creation in a codeunit, not in a page.
    - A rule that must hold regardless of entry point belongs in a codeunit or the table, not only in a page trigger.
[15] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for items, variants, inventory and journals.
    - Build items, variants, journals and inventory with the Library codeunits (LibraryInventory, LibraryRandom) top-down and Validate foreign keys; do not hand-roll Init/Insert records.
[16] `microsoft/knowledge/testing/asserterror-needs-expectederror-and-code.md`: Negative tests for the variant refusal and the blocked variant.
    - Follow every asserterror with Assert.ExpectedError using text only the intended error produces, ideally the full label built with StrSubstNo; ExpectedErrorCode alone is not enough.
[17] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit.
    - Tag the codeunit with [FEATURE] and each test with [SCENARIO], [GIVEN], [WHEN], [THEN] comments.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
