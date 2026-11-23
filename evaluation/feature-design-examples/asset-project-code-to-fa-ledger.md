# Feature design

> Fixed asset postings need an Asset Project Code so controllers can group acquisition and depreciation costs by investment project. Users enter it on FA journal and FA G/L journal lines and on purchase invoice lines that acquire a fixed asset, and depreciation calculated by the Calculate Depreciation batch must carry the project from the asset's setup. The code must be stored on the FA ledger entries.

**Result:** Complete design. **Business process:** Fixed asset posting: FA journals, FA G/L journals, purchase invoice posting of fixed asset lines and the Calculate Depreciation batch, ending in FA ledger entries. **Knowledge used:** 14 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What does Asset Project Code refer to: an existing table (for example a dimension value or a project), a new Asset Project master table, or free text? This decides the TableRelation and the exact type and length on every table; a new master table would also need its own pages, permissions and setup. _(affects: fa-journal-line-ext, gen-journal-line-ext, fa-ledger-entry-ext, fixed-asset-ext, purchase-line-ext, invoice-posting-buffer-ext, purch-inv-line-ext)_
2. Which record is the asset's setup for depreciation: the Fixed Asset card, or the FA Depreciation Book (so the code can differ per depreciation book)? _(affects: fixed-asset-ext, fixed-asset-card-ext, depreciation-fa-journal-line-carries-asset-code, depreciation-gen-journal-line-carries-asset-code)_
3. Should FA journal, FA G/L journal and purchase invoice lines default the code from the asset when the FA No. is entered, or is it entered manually only? _(affects: fa-journal-line-ext, gen-journal-line-ext, purchase-line-ext)_
4. Should the code be editable on purchase lines of other types, and on purchase orders and credit memos, or only on invoice lines of type Fixed Asset? Credit memos and orders post through the same buffer path. _(affects: purchase-line-ext, purch-invoice-subform-ext)_
5. The mirroring guidance adds the field to Purch. Rcpt. Line, Purch. Cr. Memo Line, Return Shipment Line and Purchase Line Archive unless excluded. Are any of these not needed? _(affects: purch-rcpt-line-ext, purch-cr-memo-line-ext, return-shipment-line-ext, purchase-line-archive-ext)_
6. Are maintenance postings in scope? If so, Maintenance Ledger Entry also needs the field and both copy events of Make Maintenance Ledger Entry. _(affects: asset-project-posting-codeunit)_
7. Do controllers also need the code on G/L entries, or only on FA ledger entries? The request names only FA ledger entries, so G/L Entry is not extended. _(affects: gen-journal-line-ext, fa-ledger-entry-ext)_
8. Is a stored FA Ledger Entry field required for list grouping, or is a related table keyed by Entry No. acceptable? The request says stored; the performance guidance prefers a related table for sparse attributes. _(affects: fa-ledger-entry-ext)_
9. Where will controllers group the costs: a column on the FA Ledger Entries page, a report, or an analysis view? No page or report is designed for this yet. _(affects: fa-ledger-entry-ext)_
10. Should FA ledger entries posted before installation get a value, or stay blank? _(affects: fa-ledger-entry-ext)_
11. Must reversed FA transactions keep the original code on the reversing FA ledger entries? Confirm the expected behavior with a reversal test. _(affects: fa-ledger-entry-ext)_
12. Which Business Central version does the app target? It decides whether tooltips can be inherited from table fields (runtime 13.0, BC24) or must be declared on each page. _(affects: fa-journal-page-ext, fa-gl-journal-page-ext, purch-invoice-subform-ext, fixed-asset-card-ext)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | FA Journal Line | Holds the code the user enters on FA journal lines and the value Calculate Depreciation sets when depreciation is not integrated with G/L. | Asset Project Code (Code[20] (provisional; see open question project-code-source)): DataClassification set on the field (a tableextension has no table-level value to inherit). Same number, type and length as on every other table in this design. | [1] [2] [10] [9] |
| 2 | extend | tableextension | Gen. Journal Line | Holds the code on FA G/L journal lines (account type Fixed Asset), on journal lines built from purchase invoice fixed asset lines, and on depreciation lines when depreciation is integrated with G/L. | Asset Project Code (Code[20] (provisional; see open question project-code-source)): DataClassification set on the field. Same number, type and length as on every other table in this design. | [1] [2] [4] [10] [9] |
| 3 | extend | tableextension | FA Ledger Entry | Stores the code on every FA ledger entry, whichever source posted it, so acquisition and depreciation costs can be grouped by investment project. Stored as a field because the request requires storage on the FA ledger entry; set only in the copy events, never by modifying entries after posting. | Asset Project Code (Code[20] (provisional; see open question project-code-source)): Editable = false. DataClassification set on the field. A code, not an amount, so no sign handling is needed if the entry is reversed (see open question fa-reversal). | [1] [5] [8] [4] [10] |
| 4 | extend | tableextension | Fixed Asset | The asset's setup value that Calculate Depreciation copies onto the depreciation lines it creates. | Asset Project Code (Code[20] (provisional; see open question project-code-source)): DataClassification set on the field. Placement on Fixed Asset rather than FA Depreciation Book is pending open question depreciation-source. | [2] [10] [9] |
| 5 | extend | tableextension | Purchase Line | Holds the code the user enters on a purchase invoice line of type Fixed Asset. | Asset Project Code (Code[20] (provisional; see open question project-code-source)): DataClassification set on the field. Same field number, type and length as on the posted line tables and the archive, because those are filled by TransferFields. | [2] [6] [7] [10] [9] |
| 6 | extend | tableextension | Invoice Posting Buffer | Carries the purchase line value through invoice posting, because a fixed asset purchase line never posts through an FA journal and no hop on this path uses TransferFields from the purchase line. | Asset Project Code (Code[20] (provisional; see open question project-code-source)): Part of Group ID so that lines with different codes are not merged into one buffer line. | [2] [3] [10] |
| 7 | extend | tableextension | Purch. Inv. Line | Mirror target of Purchase Line; TransferFields copies the value when the invoice is posted. | Asset Project Code (Code[20] (provisional; see open question project-code-source)): Same field number, name, type and length as on Purchase Line; Editable = false. | [6] [7] [10] |
| 8 | extend | tableextension | Purch. Rcpt. Line | Mirror target of Purchase Line, chosen by the mirroring article unless the requester excludes it (open question posted-mirrors). | Asset Project Code (Code[20] (provisional; see open question project-code-source)): Same field number, name, type and length as on Purchase Line; Editable = false. | [6] [7] [10] |
| 9 | extend | tableextension | Purch. Cr. Memo Line | Mirror target of Purchase Line, chosen by the mirroring article unless the requester excludes it (open question posted-mirrors). | Asset Project Code (Code[20] (provisional; see open question project-code-source)): Same field number, name, type and length as on Purchase Line; Editable = false. | [6] [7] [10] |
| 10 | extend | tableextension | Return Shipment Line | Mirror target of Purchase Line, chosen by the mirroring article unless the requester excludes it (open question posted-mirrors). | Asset Project Code (Code[20] (provisional; see open question project-code-source)): Same field number, name, type and length as on Purchase Line; Editable = false. | [6] [7] [10] |
| 11 | extend | tableextension | Purchase Line Archive | Mirror target of Purchase Line for archiving, chosen by the mirroring article unless the requester excludes it (open question posted-mirrors). | Asset Project Code (Code[20] (provisional; see open question project-code-source)): Same field number, name, type and length as on Purchase Line; Editable = false. | [6] [7] [10] |
| 12 | extend | pageextension | Fixed Asset Journal | Lets users enter the code on FA journal lines. Tooltip inherited from the table field on runtime 13.0 (BC24) or later; on earlier targets add a page-level ToolTip. |  | [11] |
| 13 | extend | pageextension | Fixed Asset G/L Journal | Lets users enter the code on FA G/L journal lines. Tooltip rule as for the FA journal page. |  | [11] |
| 14 | extend | pageextension | Purch. Invoice Subform | Lets users enter the code on purchase invoice lines that acquire a fixed asset. Tooltip rule as for the FA journal page. |  | [11] |
| 15 | extend | pageextension | Fixed Asset Card | Lets users maintain the asset's setup value used for depreciation. Tooltip rule as for the FA journal page. |  | [11] |
| 16 | create | codeunit | Asset Project FA Posting | Holds every event subscriber of the feature: both copy events of Make FA Ledger Entry, the purchase invoice buffer hops, and both Calculate Depreciation insert events. |  | [1] [2] [3] |

## 3. How the data flows

- **User** → **FA Journal Line**: entered by the user. Entered on the Fixed Asset Journal page. [1]
- **User** → **Gen. Journal Line**: entered by the user. Entered on the Fixed Asset G/L Journal page. [1]
- **User** → **Purchase Line**: entered by the user. Entered on purchase invoice lines of type Fixed Asset. [2]
- **User** → **Fixed Asset**: entered by the user. The asset's setup value, entered on the Fixed Asset Card. [2]
- **FA Journal Line** → **FA Ledger Entry**: copied in an event subscriber. Make FA Ledger Entry.OnAfterCopyFromFAJnlLine; used for posting types the depreciation book does not integrate with G/L. FA Insert Ledger Entry.InsertFA keeps the value. [1]
- **Gen. Journal Line** → **FA Ledger Entry**: copied in an event subscriber. Make FA Ledger Entry.OnAfterCopyFromGenJnlLine; covers FA G/L journals, purchase invoice fixed asset lines and G/L-integrated depreciation. [1] [2]
- **Purchase Line** → **Invoice Posting Buffer**: copied in an event subscriber. Purch. Post Invoice Events.OnPrepareLineOnAfterFillInvoicePostingBuffer; the field is also added to Group ID in Invoice Posting Buffer.OnAfterBuildPrimaryKey. [2] [3]
- **Invoice Posting Buffer** → **Gen. Journal Line**: copied in an event subscriber. Invoice Posting Buffer.OnAfterCopyToGenJnlLineFA, raised when Purch. Post Invoice builds the journal line for a fixed asset buffer line. The journal line then reaches the FA ledger entry through the Gen. Journal Line hop above. [2]
- **Fixed Asset** → **FA Journal Line**: copied in an event subscriber. Calculate Depreciation.OnBeforeFAJnlLineInsert, when depreciation is not integrated with G/L; the subscriber reads the Fixed Asset of the line's FA No. [2]
- **Fixed Asset** → **Gen. Journal Line**: copied in an event subscriber. Calculate Depreciation.OnBeforeGenJnlLineInsert, when depreciation is integrated with G/L; the subscriber reads the Fixed Asset of the line's account. [2]
- **Purchase Line** → **Purch. Inv. Line**: standard TransferFields copy. InitFromPurchLine; no subscriber needed. [6]
- **Purchase Line** → **Purch. Rcpt. Line**: standard TransferFields copy. InitFromPurchLine; no subscriber needed. [6]
- **Purchase Line** → **Purch. Cr. Memo Line**: standard TransferFields copy. InitFromPurchLine; no subscriber needed. [6]
- **Purchase Line** → **Return Shipment Line**: standard TransferFields copy. InitFromPurchLine; no subscriber needed. [6]
- **Purchase Line** → **Purchase Line Archive**: standard TransferFields copy. Archiving copies the line; no subscriber needed. [6]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Make FA Ledger Entry" | `OnAfterCopyFromFAJnlLine` | Copy the code from the FA journal line to the FA ledger entry. | Assign the field only; do not find and Modify FA ledger entries after posting. | [1] [5] |
| Codeunit "Make FA Ledger Entry" | `OnAfterCopyFromGenJnlLine` | Copy the code from the general journal line to the FA ledger entry. | Name the publisher exactly: VAT Entry and Bank Account Ledger Entry publish events with the same name. · Assign the field only; do not find and Modify FA ledger entries after posting. | [1] [5] |
| Codeunit "Purch. Post Invoice Events" | `OnPrepareLineOnAfterFillInvoicePostingBuffer` | Copy the purchase line code into the invoice posting buffer. | Leave IsHandled untouched so the standard buffer update still runs. · Subscribe on Purch. Post Invoice Events, not on Purch. Post Invoice. | [3] [2] |
| Table "Invoice Posting Buffer" | `OnAfterBuildPrimaryKey` | Add the code to Group ID so fixed asset lines with different codes do not merge and keep only the first line's value. | Pad the value with PadField as the standard key does; Group ID is Text[1000]. | [3] [2] |
| Table "Invoice Posting Buffer" | `OnAfterCopyToGenJnlLineFA` | Copy the code from the fixed asset buffer line to the general journal line that is posted to the FA ledger. |  | [2] |
| Report "Calculate Depreciation" | `OnBeforeFAJnlLineInsert` | Set the asset's code on depreciation FA journal lines (book not integrated with G/L for depreciation). | Handle together with OnBeforeGenJnlLineInsert so the value does not depend on the book's G/L integration. | [2] |
| Report "Calculate Depreciation" | `OnBeforeGenJnlLineInsert` | Set the asset's code on depreciation general journal lines (book integrated with G/L for depreciation). | Handle together with OnBeforeFAJnlLineInsert so the value does not depend on the book's G/L integration. | [2] |

## 5. Setup, permissions and lifecycle

- **privacy**: Set DataClassification on the Asset Project Code field in every table extension; a tableextension has no table-level value to inherit, and ToBeClassified is not a valid default. [10]
- **setup**: Users maintain the asset's Asset Project Code on the Fixed Asset Card before running Calculate Depreciation; depreciation lines take the value from there. [2]

## 6. Tests

1. **fa-journal-acquisition-carries-code** [1] [12] [13] [14]
    - Given A fixed asset and a depreciation book that does not integrate acquisition cost with G/L, created with the library codeunits, and an FA journal acquisition line with a random Asset Project Code
    - When The FA journal line is posted
    - Then The FA ledger entry for the asset has the same Asset Project Code
2. **fa-gl-journal-acquisition-carries-code** [1] [12] [13] [14]
    - Given A fixed asset and a depreciation book that integrates acquisition cost with G/L, and an FA G/L journal line of account type Fixed Asset with a random Asset Project Code
    - When The general journal line is posted
    - Then The FA ledger entry for the asset has the same Asset Project Code
3. **purchase-invoice-fa-line-carries-code** [2] [3] [12] [13] [14]
    - Given A purchase invoice with one line of type Fixed Asset (acquisition cost) and a random Asset Project Code on the line
    - When The purchase invoice is posted
    - Then The FA ledger entry for the asset has the same Asset Project Code, and its amount equals the line amount (standard buffer update not skipped)
4. **purchase-invoice-lines-with-different-codes-stay-separate** [3] [2] [12] [13] [14]
    - Given A purchase invoice with two Fixed Asset lines for the same asset and posting setup but different Asset Project Codes
    - When The purchase invoice is posted
    - Then Two FA ledger entries exist, each carrying its own line's Asset Project Code and amount
5. **posted-purchase-invoice-line-mirrors-code** [6] [12] [13] [14]
    - Given A purchase invoice with a Fixed Asset line carrying a random Asset Project Code
    - When The purchase invoice is posted
    - Then The Purch. Inv. Line has the same Asset Project Code
6. **archived-purchase-line-mirrors-code** [6] [12] [13] [14]
    - Given A purchase invoice with a Fixed Asset line carrying a random Asset Project Code
    - When The document is archived
    - Then The Purchase Line Archive line has the same Asset Project Code
7. **depreciation-fa-journal-line-carries-asset-code** [2] [12] [13] [14]
    - Given A fixed asset with an Asset Project Code and posted acquisition cost in a depreciation book that does not integrate depreciation with G/L
    - When Calculate Depreciation is run for the asset
    - Then The created FA Journal Line has the asset's Asset Project Code
8. **depreciation-gen-journal-line-carries-asset-code** [2] [12] [13] [14]
    - Given A fixed asset with an Asset Project Code and posted acquisition cost in a depreciation book that integrates depreciation with G/L
    - When Calculate Depreciation is run for the asset
    - Then The created Gen. Journal Line has the asset's Asset Project Code

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- bc-version, countries and application-area could not be determined; no repository or app.json was supplied.
- Page names Fixed Asset Journal, Fixed Asset G/L Journal, Purch. Invoice Subform and Fixed Asset Card are not named by an opened article; confirm against the target's symbols.
- Reading the asset's code inside the Calculate Depreciation subscribers (from the line's FA No. or account) rests on agent judgment; the article sample leaves the lookup to a setup function.
- Behavior of FA ledger entries under reversal is not covered by an opened article.

## Sources

[1] `microsoft/knowledge/finance-extensions/carry-fields-to-fa-ledger-entries-from-fa-and-gen-journal-lines.md`: FA ledger entry copy events from both FA journal and general journal lines; fields on FA Journal Line, Gen. Journal Line and FA Ledger Entry.
    - Add the field to FA Journal Line, Gen. Journal Line and FA Ledger Entry, and to Maintenance Ledger Entry when maintenance is in scope.
    - Subscribe to both OnAfterCopyFromFAJnlLine and OnAfterCopyFromGenJnlLine on Make FA Ledger Entry; which source is used depends on the depreciation book's G/L integration.
    - Name the publisher exactly; OnAfterCopyFromGenJnlLine also exists on VAT Entry and Bank Account Ledger Entry.
    - Do not find FA ledger entries after posting and Modify them.
[2] `microsoft/knowledge/finance-extensions/carry-purchase-and-depreciation-fields-to-fixed-asset-entries.md`: Purchase invoice fixed asset path through Invoice Posting Buffer and depreciation path through Calculate Depreciation.
    - A purchase line field must be put into Invoice Posting Buffer, including its grouping key when values may differ per line.
    - Copy it from buffer to journal line in OnAfterCopyToGenJnlLine or OnAfterCopyToGenJnlLineFA on Invoice Posting Buffer.
    - The last hop is OnAfterCopyFromGenJnlLine on Make FA Ledger Entry.
    - Set a depreciation value in both OnBeforeFAJnlLineInsert and OnBeforeGenJnlLineInsert of Calculate Depreciation.
    - Do not rely on matching field numbers: no hop on the purchase-to-FA path uses TransferFields from the purchase line.
[3] `microsoft/knowledge/sales-purchase/carry-sales-and-purchase-line-fields-to-gl-through-the-invoice-posting-buffer.md`: Filling the buffer from the purchase line and keeping lines with different codes in separate groups.
    - Subscribe to OnPrepareLineOnAfterFillInvoicePostingBuffer on Purch. Post Invoice Events and leave IsHandled untouched.
    - Add the field to Group ID in OnAfterBuildPrimaryKey when lines with different values must post separately, padded with PadField; Group ID is Text[1000].
    - Leaving the field out of Group ID merges lines and keeps only the first line's value.
[4] `microsoft/knowledge/finance-extensions/carry-gen-journal-line-fields-to-gl-vat-and-bank-entries.md`: Deciding which entries besides the FA ledger entry store the code, and what reversal does to it.
    - Decide per entry whether it needs the value; do not store the field on a ledger entry only because it exists on the journal line.
    - For every custom field on an entry, state what reversal must do; a reference or code can stay as copied, a custom amount or quantity must be negated.
[5] `microsoft/knowledge/finance/do-not-modify-or-delete-posted-ledger-entries.md`: Guard: the code is set during posting, never by editing posted entries.
    - Do not persist changes to posted financial entries outside the supported posting, correction and entry-edit workflows.
[6] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Mirroring the purchase line field on posted purchase lines and the archive.
    - Give the field the same number, name, type and length on Purchase Line and every TransferFields target the plan needs; unless the plan excludes a document type, that means all four posted line tables and the archive.
    - No subscriber is needed for these stages; keep the mirrored fields non-editable on posted tables.
[7] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length agreement across the mirrored purchase line tables.
    - Define a mirrored field with the exact same field number, data type and length on every table in the TransferFields cascade.
[8] `microsoft/knowledge/performance/prefer-related-table-over-extension-on-hot-ledgers.md`: Choice between a stored field and a related table on ledger entries.
    - Put optional, sparse or integration attributes in a related table keyed by the ledger entry number.
    - Use a stored tableextension field only when the value must appear as a native list column and is read on almost every access.
[9] `microsoft/knowledge/data-modeling/tablerelation-field-length-must-match-related-field.md`: Sizing the Asset Project Code field once its TableRelation target is decided.
    - For an unconditional TableRelation, give the field the same type and exact length as the related field.
    - Read the related field's declared type and length before adding the relation; do not assume Code[10] or Code[20].
[10] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: DataClassification on every new table extension field.
    - A tableextension has no table-level classification to inherit, so every Normal field it adds must set its own.
    - Set the classification that matches the stored data; ToBeClassified is not a safe default.
[11] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Tooltips for the new page fields.
    - On runtime 13.0 (BC24) or later, define the tooltip on the table field and let bound page fields inherit it.
    - Before runtime 13.0, user-facing page fields need page-level tooltips.
    - Describe what the value is used for; do not invent effects or constraints.
[12] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures for fixed assets, depreciation books, journals and purchase invoices.
    - Create prerequisite records with the test Library codeunits, parents first, and Validate foreign keys; do not hand-roll Init/Insert.
[13] `microsoft/knowledge/testing/test-feature-scenario-tags.md`: Structure of the test codeunit.
    - Tag the codeunit with [FEATURE] and each test with [SCENARIO], [GIVEN], [WHEN] and [THEN].
[14] `microsoft/knowledge/testing/test-one-when-per-test.md`: Shape of each test scenario.
    - Give each test exactly one [WHEN]; a precondition action such as posting belongs in [GIVEN].

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
