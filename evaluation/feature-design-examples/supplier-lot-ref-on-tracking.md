# Feature design

> When we receive lot-tracked items, the warehouse clerk types the supplier's own lot reference next to each lot on the item tracking lines. That supplier lot reference must be stored on the item ledger entries created for each lot, so quality can trace complaints back to the supplier's lot.

**Result:** Complete design. **Business process:** Inbound lot tracking on receipt (Item Tracking Lines) and item ledger posting through Item Jnl.-Post Line. **Knowledge used:** 11 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What type and length should Supplier Lot Ref. have (Code uppercases input; Text preserves case), and is that long enough for every supplier's lot reference? It must be identical on all four tables. _(affects: tracking-spec-ext, reserv-entry-ext, item-jnl-line-ext, item-ledger-entry-ext)_
2. Can the same lot of an item ever arrive with different supplier lot references (for example, on two receipts)? Posting keeps only the first value per lot within one posting; if the reference always describes the lot itself, should it be stored on Lot No. Information instead of, or as well as, on item ledger entries? _(affects: tracking-spec-ext, reserv-entry-ext, item-ledger-entry-ext, supplier-lot-ref-subscribers, two-lots-keep-their-own-refs)_
3. How will quality look up the reference: as a column on Item Ledger Entries (or filtering/Navigate), or from a FactBox? A stored field is justified when it is a native list column read on almost every access; otherwise a related table keyed by Entry No. is preferred. No Item Ledger Entries page change is designed until this is answered. _(affects: item-ledger-entry-ext)_
4. Which postings should carry the reference: only inbound receipts (purchase orders, warehouse receipts, inventory put-aways), or also transfer receipts, sales returns and positive adjustments? Should outbound entries of the same lot (shipments, consumption) also show the supplier reference, which this design does not copy unless it is typed on their tracking lines? _(affects: supplier-lot-ref-subscribers, item-ledger-entry-ext)_
5. Is the supplier lot reference mandatory when receiving lot-tracked items (for all items, or only some vendors or items), and if so, at which point should missing values be blocked? _(affects: item-tracking-lines-ext, supplier-lot-ref-subscribers)_
6. Is item tracking for receipts ever assigned outside the Item Tracking Lines page, for example from code, an import or a scanner app? Those paths would need their own way to set the value. _(affects: supplier-lot-ref-subscribers)_
7. Must item ledger entries posted before go-live carry the reference? This design does not back-fill posted entries. _(affects: item-ledger-entry-ext)_
8. Confirm the DataClassification for the supplier lot reference (the design assumes CustomerContent; it is not personal data). _(affects: tracking-spec-ext, reserv-entry-ext, item-jnl-line-ext, item-ledger-entry-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Tracking Specification | Holds the supplier lot reference typed per lot on the Item Tracking Lines page and in the specifications posting rebuilds from reservation entries with TransferFields. | Supplier Lot Ref. (TBD: identical type and length on all four tables (see open question field-type-and-length)): Same field number, type and length as on Tracking Specification, Reservation Entry, Item Journal Line and Item Ledger Entry. DataClassification set on the field (CustomerContent unless the classification question decides otherwise). Must share its number with the Reservation Entry field so both TransferFields hops carry it. | [1] [4] [5] |
| 2 | extend | tableextension | Reservation Entry | Persists the supplier lot reference on the source line's tracking rows between page close and posting. | Supplier Lot Ref. (TBD: identical type and length on all four tables (see open question field-type-and-length)): Same field number, type and length as on Tracking Specification, Reservation Entry, Item Journal Line and Item Ledger Entry. DataClassification set on the field (CustomerContent unless the classification question decides otherwise). Must share its number with the Tracking Specification field. | [1] [4] [5] |
| 3 | extend | tableextension | Item Journal Line | Carries the value on the per-lot split journal line inside Item Jnl.-Post Line. | Supplier Lot Ref. (TBD: identical type and length on all four tables (see open question field-type-and-length)): Same field number, type and length as on Tracking Specification, Reservation Entry, Item Journal Line and Item Ledger Entry. DataClassification set on the field (CustomerContent unless the classification question decides otherwise). | [1] [5] |
| 4 | extend | tableextension | Item Ledger Entry | Stores the supplier lot reference on each item ledger entry created for a lot, as the request requires. The related-table alternative for hot ledgers (BC23+) was weighed; a stored field is kept because the request asks for the value on the item ledger entries themselves. Revisit if quality does not need it as a native list column (open question ile-visibility). | Supplier Lot Ref. (TBD: identical type and length on all four tables (see open question field-type-and-length)): Same field number, type and length as on Tracking Specification, Reservation Entry, Item Journal Line and Item Ledger Entry. DataClassification set on the field (CustomerContent unless the classification question decides otherwise). | [1] [3] [5] |
| 5 | extend | pageextension | Item Tracking Lines | Adds the Supplier Lot Ref. column next to Lot No. so the warehouse clerk can type it per lot. Tooltip defined on the table field and inherited on BC24+ (runtime 13.0); add a page-level tooltip only when targeting earlier runtimes. |  | [1] [6] [7] |
| 6 | create | codeunit | Supplier Lot Ref. Tracking | Event subscribers that copy the value on each hop: creation and modification of reservation entries, change detection on the page, journal-line split and ledger-entry initialization. |  | [1] |

## 3. How the data flows

- **Warehouse clerk** → **Tracking Specification (temporary, Item Tracking Lines page)**: entered by the user. Clerk types the supplier lot reference next to each lot line. [1]
- **Tracking Specification** → **Reservation Entry (new tracking line)**: copied in an event subscriber. RegisterChange builds the entry with Create Reserv. Entry; copy in OnCreateReservEntryExtraFields before CreateEntry. [1]
- **Tracking Specification** → **Reservation Entry (changed tracking line)**: copied in an event subscriber. ModifyFieldsWithinFilter raises OnAfterMoveFields; OnAfterEntriesAreIdentical must report a difference so a change to only this field is registered. [1]
- **Reservation Entry** → **Tracking Specification (page reload and SumUpItemTracking at posting)**: standard TransferFields copy. Requires the same field number, type and length on both tables. Posting sums per lot and serial, so only the first entry's value survives when entries of the same lot differ. [1] [4]
- **Tracking Specification** → **Item Journal Line (per-lot split in Item Jnl.-Post Line)**: copied in an event subscriber. CopyTrackingFromSpec raises OnAfterCopyTrackingFromSpec. [1]
- **Item Journal Line** → **Item Ledger Entry**: copied in an event subscriber. InitItemLedgEntry calls CopyTrackingFromItemJnlLine, which raises OnAfterCopyTrackingFromItemJnlLine. Never patch posted entries afterwards. [1] [2]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Create Reserv. Entry" | `OnCreateReservEntryExtraFields` | Copy Supplier Lot Ref. from NewTrackingSpecification to InsertReservEntry when a tracking line is created. |  | [1] |
| Page "Item Tracking Lines" | `OnAfterEntriesAreIdentical` | Report a difference in IdenticalArray[2] when Supplier Lot Ref. differs, so a change to only this field is saved. | Only AND the comparison into IdenticalArray[2]; never set it to true. | [1] |
| Page "Item Tracking Lines" | `OnAfterMoveFields` | Copy Supplier Lot Ref. from TrkgSpec to ReservEntry when an existing tracking line is modified. |  | [1] |
| Table "Item Journal Line" | `OnAfterCopyTrackingFromSpec` | Copy Supplier Lot Ref. from the Tracking Specification to the split Item Journal Line. |  | [1] |
| Table "Item Ledger Entry" | `OnAfterCopyTrackingFromItemJnlLine` | Copy Supplier Lot Ref. from the Item Journal Line to the new Item Ledger Entry. | Assign the field only; do not insert, modify or patch Item Ledger Entry records outside the posting engine. | [1] [2] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification on the Supplier Lot Ref. field in each of the four table extensions (a tableextension has no table-level value to inherit); never leave ToBeClassified or use SystemMetadata for business data. [5]
- **other**: No install or upgrade code: the new fields start empty. Existing item ledger entries are not back-filled by editing posted entries (see open question historic-entries). [1] [2]

## 6. Tests

1. **receipt-posts-supplier-lot-ref-to-ile** [1] [8] [9] [10] [11]
    - Given A lot-tracked item and a purchase order line created with the Library codeunits; on Item Tracking Lines (page handler) a lot number and a supplier lot reference are entered.
    - When The purchase order is posted as received.
    - Then The item ledger entry for that lot carries the entered supplier lot reference.
2. **two-lots-keep-their-own-refs** [1] [8] [9] [11]
    - Given A purchase line for a lot-tracked item with two lots, each with a different supplier lot reference entered on Item Tracking Lines.
    - When The purchase order is posted as received.
    - Then Each lot's item ledger entry carries its own supplier lot reference.
3. **changed-ref-only-is-saved** [1] [9] [11]
    - Given A purchase line with a lot and supplier lot reference already registered on Item Tracking Lines.
    - When The page is reopened and only the supplier lot reference is changed, then the page is closed.
    - Then The reservation entry for that lot holds the new supplier lot reference (OnAfterEntriesAreIdentical and OnAfterMoveFields hops).
4. **reopened-page-shows-ref** [1] [9] [11]
    - Given A purchase line with a lot and supplier lot reference registered and the page closed.
    - When Item Tracking Lines is reopened for the line.
    - Then The page handler captures the stored supplier lot reference on the lot line, proving the Reservation Entry to Tracking Specification TransferFields hop.
5. **journal-line-receives-ref-on-split** [1] [2] [11]
    - Given A purchase line with a lot and supplier lot reference registered.
    - When The purchase order is posted as received.
    - Then The posted value matches on the item ledger entry, confirming the Item Journal Line split copy and the ledger-entry copy; no item ledger entry is modified after posting.

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area are unknown (no repository); performance guidance applies from BC23 and table-field tooltip inheritance from BC24, so both are conditional.
- Field type and length rest on an open question, not on knowledge.

## Sources

[1] `microsoft/knowledge/inventory/carry-item-tracking-line-fields-to-item-ledger-entries.md`: Backbone of the design: the four-record path, the five events and the field-mirroring rule.
    - Give the field the same number and type on Tracking Specification and Reservation Entry so both TransferFields hops carry it; add it to Item Journal Line and Item Ledger Entry.
    - Subscribe to OnCreateReservEntryExtraFields, OnAfterEntriesAreIdentical (report a difference in IdenticalArray[2]), OnAfterMoveFields, OnAfterCopyTrackingFromSpec and OnAfterCopyTrackingFromItemJnlLine.
    - Posting sums reservation entries per lot and serial, so a value that differs between entries of the same lot keeps only the first entry's value.
    - When the value describes the lot itself and never differs per document, store it on Lot No. Information instead of copying it through posting.
    - Do not add the field only to Tracking Specification and the page, or give it a different number on Reservation Entry; do not patch Item Ledger Entry after posting by lot number.
[2] `microsoft/knowledge/scm/post-item-ledger-changes-through-item-journals.md`: Guard that the value reaches item ledger entries only through the posting engine, never by editing posted entries.
    - Item ledger entries are created by the owning posting workflow (Item Jnl.-Post Line, document posting); supported posting events enrich data within that workflow.
    - Independent inserts, deletes or overwrites of posted Item Ledger Entry transaction rows bypass the coordinated posting workflow.
[3] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Weighed against storing the field on Item Ledger Entry; applies from BC23.
    - Put optional, sparse or integration attributes of hot ledgers such as Item Ledger Entry in a related table keyed by Entry No., shown from a FactBox or FlowField.
    - Use a tableextension stored field only when the value must appear as a native list column and is read on almost every access.
[4] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definition rule across the Tracking Specification and Reservation Entry TransferFields hops.
    - A field mirrored across a TransferFields cascade must have the exact same field number, data type and length on every table in that cascade, defined at creation time.
[5] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: DataClassification on the four new table-extension fields.
    - A tableextension has no table-level classification to inherit, so every Normal field it adds must set its own DataClassification.
    - Choose the classification that matches the stored data at definition time; ToBeClassified and SystemMetadata for business data are under-classifications.
[6] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Tooltip on the Item Tracking Lines column; applies from BC24 (runtime 13.0).
    - On runtime 13.0 or later a bound page field inherits its source table field's ToolTip; do not add a duplicate page-level ToolTip.
    - A field with neither an inline nor an inherited ToolTip is a genuine gap.
[7] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltip text and placement for the new field.
    - On runtime 13.0 or later define shared tooltip text on the table field; before runtime 13.0 user-facing page fields need page-level tooltips.
    - Tooltip text should say what the value is used for, not merely repeat the caption, and must not invent behavior.
[8] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for items, vendors and purchase documents.
    - Build prerequisite records with the test Library codeunits, parents first, and Validate foreign keys instead of hand-rolled Init/Insert.
[9] `microsoft/knowledge/testing/ui-handlers-in-tests.md`: Driving Item Tracking Lines in tests through a modal page handler.
    - Every UI call on the executed path needs a handler listed in HandlerFunctions, and every nonoptional listed handler must run.
    - Handlers must contribute meaningful evidence, such as capturing a page value asserted after RunModal.
[10] `microsoft/knowledge/testing/test-data-must-be-random-and-complete.md`: Test data for lot numbers and supplier lot references.
    - Create the records the test owns instead of assuming existing data; fill every mandatory field.
    - Generate incidental values with the library codeunits; keep values that define the scenario explicit.
[11] `microsoft/knowledge/testing/test-one-when-per-test.md`: Test structure: one action per test, posting as GIVEN where it is a precondition.
    - Each test has exactly one WHEN; a precondition action such as posting belongs in GIVEN.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
