# Feature design

> Sales orders carry a Project Code. It must appear in the PEPPOL invoice we send through E-Documents, and when a supplier sends us an e-invoice containing a project code, that code must land on the purchase invoice created from the e-document.

**Result:** Complete design. **Business process:** Sales order posting with outgoing PEPPOL e-invoicing through E-Document Core, and incoming e-invoice import (V2) into purchase invoices. **Knowledge used:** 9 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is "Project Code" on the sales order today: an existing field (which table extension, field number, type and length, table relation), a new field to add, a dimension (shortcut dimension) or the Job No.? The design assumes a custom Code[20] header field; a dimension or Job No. would change objects and data flow. _(affects: sales-header-ext, purchase-header-ext, edoc-purchase-header-ext, sales-invoice-header-ext)_
2. Which object ID and field number range does the app own? The same field number must be used on every TransferFields target. _(affects: sales-header-ext, purchase-header-ext)_
3. Must Project Code also reach Sales Shipment Header, Sales Cr.Memo Header, Return Receipt Header and Sales Header Archive? The article includes them unless a document type never needs it. _(affects: sales-shipment-header-ext, sales-cr-memo-header-ext, return-receipt-header-ext, sales-header-archive-ext)_
4. Must Project Code reach the posted purchase invoice and the other posted purchase tables and archive, or only the unposted purchase invoice the request names? _(affects: purch-inv-header-ext, purch-rcpt-header-ext, purch-cr-memo-hdr-ext, return-shipment-header-ext, purchase-header-archive-ext)_
5. Must Project Code reach Cust. Ledger Entry, Vendor Ledger Entry or G/L Entry? Not designed. _(affects: sales-header-ext, purchase-header-ext)_
6. Is Project Code a header-only value, or can lines carry different project codes (in the PEPPOL export and on import)? _(affects: sales-header-ext, edoc-reader-codeunit)_
7. Which UBL element carries the project code in the outgoing invoice and is read from incoming invoices (for example a project reference or accounting cost element), and at which position in the document? _(affects: edoc-project-code-subscribers, edoc-reader-codeunit)_
8. Should PEPPOL credit memos also carry the project code? The design adds it to sales invoices only. _(affects: edoc-project-code-subscribers)_
9. Must posting or release be blocked when Project Code is empty for customers that receive e-invoices? That rule would belong in a format Check, which the built-in PEPPOL format does not offer to extend. _(affects: sales-header-ext, edoc-project-code-subscribers)_
10. What should happen when an incoming project code does not exist in BC or fails validation on Purchase Header: error, store as is, or skip? _(affects: edoc-project-code-subscribers, purchase-header-ext)_
11. Is it acceptable to replace the built-in PEPPOL reader with an own reader that must also parse all standard invoice data, given the built-in reader is internal and raises no event? _(affects: edoc-reader-codeunit, read-into-draft-enumext)_
12. Should Copy Document carry Project Code back from posted or archived documents into new sales or purchase documents? _(affects: sales-header-ext, purchase-header-ext)_
13. On which pages should Project Code be visible besides Sales Order, Posted Sales Invoice, Purchase Invoice and Posted Purchase Invoice (lists, other posted documents, E-Document draft page)? _(affects: sales-pageexts, purchase-pageexts)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Sales Header | Holds the Project Code the user enters on the sales order; source of every sales TransferFields copy. | Project Code (Code[20]): Length Code[20] assumed pending q-project-code-definition; DataClassification = CustomerContent. | [4] [2] [6] [7] |
| 2 | extend | tableextension | Sales Invoice Header | Receives Project Code by TransferFields at posting; the posted invoice is the record E-Document Core maps and passes to the PEPPOL format. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [4] [1] [6] |
| 3 | extend | tableextension | Sales Shipment Header | Mirror target chosen by the article (every TransferFields target unless the plan states a document type never needs the field); confirm with q-sales-mirror-targets. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [4] [2] [6] |
| 4 | extend | tableextension | Sales Cr.Memo Header | Mirror target chosen by the article (every TransferFields target unless the plan states a document type never needs the field); confirm with q-sales-mirror-targets. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [4] [2] [6] |
| 5 | extend | tableextension | Return Receipt Header | Mirror target chosen by the article (every TransferFields target unless the plan states a document type never needs the field); confirm with q-sales-mirror-targets. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [4] [2] [6] |
| 6 | extend | tableextension | Sales Header Archive | Mirror target chosen by the article (every TransferFields target unless the plan states a document type never needs the field); confirm with q-sales-mirror-targets. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [4] [2] [6] |
| 7 | extend | tableextension | Purchase Header | Holds the Project Code on the purchase invoice created from the e-document; filled after the V2 finish step, and source of every purchase TransferFields copy. | Project Code (Code[20]): Length Code[20] assumed pending q-project-code-definition; DataClassification = CustomerContent. | [1] [5] [6] [7] |
| 8 | extend | tableextension | Purch. Inv. Header | Mirror target chosen by the article (every purchase TransferFields target unless the plan states a document type never needs the field); confirm with q-purchase-mirror-targets. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [5] [6] |
| 9 | extend | tableextension | Purch. Rcpt. Header | Mirror target chosen by the article (every purchase TransferFields target unless the plan states a document type never needs the field); confirm with q-purchase-mirror-targets. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [5] [6] |
| 10 | extend | tableextension | Purch. Cr. Memo Hdr. | Mirror target chosen by the article (every purchase TransferFields target unless the plan states a document type never needs the field); confirm with q-purchase-mirror-targets. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [5] [6] |
| 11 | extend | tableextension | Return Shipment Header | Mirror target chosen by the article (every purchase TransferFields target unless the plan states a document type never needs the field); confirm with q-purchase-mirror-targets. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [5] [6] |
| 12 | extend | tableextension | Purchase Header Archive | Mirror target chosen by the article (every purchase TransferFields target unless the plan states a document type never needs the field); confirm with q-purchase-mirror-targets. | Project Code (Code[20]): Same field number, name, type and length as on Sales Header/Purchase Header; Editable = false; DataClassification = CustomerContent. | [5] [6] |
| 13 | extend | tableextension | E-Document Purchase Header | V2 staging field that the custom reader fills from the incoming e-invoice. Core never copies an extension field from staging to Purchase Header, so the import subscriber copies it. | Project Code (Code[20]): Staging field; not part of a TransferFields cascade with Purchase Header. DataClassification = CustomerContent. | [1] [7] |
| 14 | extend | enumextension | E-Doc. Read into Draft | New reader value whose Implementation binds IStructuredFormatReader to the custom reader codeunit; the built-in PEPPOL reader is internal and raises no event. |  | [1] |
| 15 | create | codeunit | IStructuredFormatReader implementation | Reads the incoming e-invoice blob into E-Document Purchase Header and E-Document Purchase Line (InsertForEDocument), including the Project Code staging field, and returns the Purchase Invoice draft type. It must also parse the standard fields the built-in reader would fill (see unresolved). |  | [1] |
| 16 | create | codeunit | E-Document Project Code subscribers | Holds the export subscriber (adds Project Code to the PEPPOL XML) and the import subscriber (copies the staging value to the created Purchase Header). |  | [1] |
| 17 | extend | pageextension | Sales Order; Posted Sales Invoice | Show Project Code for entry on the sales order and read-only on the posted invoice. Other pages per q-pages. |  | [2] [9] |
| 18 | extend | pageextension | Purchase Invoice; Posted Purchase Invoice | Show the imported Project Code on the purchase invoice and the posted purchase invoice. Other pages per q-pages. |  | [2] [9] |
| 19 | create | permissionset | Project Code e-document feature | Permission set entries for the new codeunits created by the feature. |  | [2] |

## 3. How the data flows

- **User** → **Sales Header.Project Code**: entered by the user. Entered on the sales order (page extension). [2]
- **Sales Header.Project Code** → **Sales Invoice Header.Project Code**: standard TransferFields copy. Sales-Post TransferFields(SalesHeader); same field number and type required, no subscriber. [4] [6]
- **Sales Header.Project Code** → **Sales Shipment Header / Sales Cr.Memo Header / Return Receipt Header .Project Code**: standard TransferFields copy. Article-chosen stages; see q-sales-mirror-targets. [4] [2]
- **Sales Header.Project Code** → **Sales Header Archive.Project Code**: standard TransferFields copy. ArchiveManagement TransferFields; article-chosen stage. [4]
- **Sales Invoice Header.Project Code** → **SourceDocumentHeader RecordRef (mapped temporary copy)**: other. E-Doc. Mapping.MapRecord uses RecordRef.Copy, so the table extension field is carried; E-Document created by Core after the posting commit. [1] [3]
- **SourceDocumentHeader RecordRef** → **PEPPOL BIS 3.0 XML in Temp Blob**: copied in an event subscriber. OnAfterCreatePEPPOLXMLDocument subscriber loads the XML from the blob, adds the element and writes it back to the same blob. UBL element per q-ubl-element. [1]
- **Incoming e-invoice blob** → **E-Document Purchase Header.Project Code**: other. Custom IStructuredFormatReader bound to the new E-Doc. Read into Draft value (V2 import process). [1]
- **E-Document Purchase Header.Project Code** → **Purchase Header.Project Code**: copied in an event subscriber. OnAfterProcessIncomingEDocument with DesiredEndState = Processed; header found by E-Document Link = EDocument.SystemId; value set with Validate and Modify(true). [1]
- **Purchase Header.Project Code** → **Purch. Inv. Header / Purch. Rcpt. Header / Purch. Cr. Memo Hdr. / Return Shipment Header .Project Code**: standard TransferFields copy. Purch.-Post TransferFields(PurchHeader); article-chosen stages, see q-purchase-mirror-targets. [5] [6]
- **Purchase Header.Project Code** → **Purchase Header Archive.Project Code**: standard TransferFields copy. ArchiveManagement TransferFields; article-chosen stage. [5]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "EDoc PEPPOL BIS 3.0" | `OnAfterCreatePEPPOLXMLDocument` | Add the Project Code element to the finished PEPPOL XML for an outgoing sales invoice. | Exit unless SourceDocumentHeader.Number() = Database::"Sales Invoice Header" (other document types per q-credit-memo-peppol). · Read the value from the SourceDocumentHeader record ref (SetTable), never re-read the posted invoice by number, so the service mapping rules apply. · Exit when Project Code is empty. · Load the XML from the passed Temp Blob and write the result back to the same blob. · No blocking errors here: Create runs after the posting commit; posting-blocking rules belong in the format Check (q-require-on-posting). | [1] [3] |
| Codeunit "E-Doc. Import" | `OnAfterProcessIncomingEDocument` | Copy the staged Project Code to the purchase invoice created by the V2 finish step, which copies only named staging fields and raises no event. | Exit unless DesiredEndState = Processed. · Find Purchase Header by "E-Document Link" = EDocument.SystemId; exit if none is linked. · Exit when the staging Project Code is empty. · Do not use the V1 E-Document Create Purch. Doc. events; they never fire for a Version 2.0 service. | [1] |

## 5. Setup, permissions and lifecycle

- **setup**: E-Document Service: keep Import Process = Version 2.0 and configure the service to read incoming documents with the new E-Doc. Read into Draft value (exact configuration step unresolved). [1]
- **setup**: Outgoing: the bill-to customer document sending profile must use Electronic Document = Extended E-Document Service Flow with an enabled workflow that uses the PEPPOL BIS 3.0 service, and the service must support the outgoing sales invoice type; otherwise no E-Document is created and no error is raised. [3]
- **privacy**: Set DataClassification = CustomerContent (or the classification the requester confirms) on every Project Code field, including the staging field; no ToBeClassified ships. [7]
- **permissions**: Ship a permission set covering the new codeunits. [2]

## 6. Tests

1. **sales-order-posts-project-code-to-invoice** [4] [8]
    - Given A customer and item created with LibrarySales/LibraryInventory and a sales order with Project Code set
    - When The order is shipped and invoiced
    - Then Sales Invoice Header and Sales Shipment Header hold the same Project Code
2. **sales-credit-memo-and-return-carry-project-code** [4] [8]
    - Given A sales credit memo and a sales return order with Project Code set
    - When Each is posted
    - Then Sales Cr.Memo Header and Return Receipt Header hold the Project Code
3. **sales-archive-carries-project-code** [4]
    - Given A sales order with Project Code
    - When The order is archived
    - Then Sales Header Archive holds the Project Code
4. **peppol-export-contains-project-code** [1] [3] [8]
    - Given PEPPOL BIS 3.0 service with supported outgoing sales invoice type, enabled workflow and a customer document sending profile set to Extended E-Document Service Flow; sales order with Project Code
    - When The order is posted and the E-Document is exported
    - Then The exported PEPPOL XML in the E-Document log contains the Project Code element with the value
5. **peppol-export-without-project-code** [1] [3]
    - Given Same e-document setup; sales order without Project Code
    - When The order is posted and exported
    - Then The XML contains no Project Code element and the E-Document is not in Export Error
6. **peppol-export-ignores-other-document-types** [1]
    - Given Same e-document setup; a posted sales credit memo
    - When The credit memo E-Document is exported
    - Then The subscriber exits on the table-number guard and the XML is unchanged
7. **import-copies-project-code-to-purchase-invoice** [1]
    - Given An E-Document Service with Import Process Version 2.0 using the custom reader; an incoming e-invoice containing a project code
    - When The E-Document is processed to Processed
    - Then The Purchase Header linked by E-Document Link holds the Project Code
8. **import-not-processed-leaves-header-alone** [1]
    - Given Same service and incoming e-invoice
    - When Processing stops before Processed (draft state)
    - Then E-Document Purchase Header holds the Project Code and no Purchase Header is changed
9. **import-without-project-code** [1]
    - Given Same service; an incoming e-invoice without a project code
    - When The E-Document is processed to Processed
    - Then The purchase invoice is created and its Project Code is empty with no error
10. **purchase-invoice-posts-project-code** [5] [8]
    - Given A purchase invoice with Project Code (created by import or LibraryPurchase)
    - When It is posted
    - Then Purch. Inv. Header holds the Project Code
11. **purchase-archive-carries-project-code** [5]
    - Given A purchase document with Project Code
    - When It is archived
    - Then Purchase Header Archive holds the Project Code

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Choice and position of the UBL element for the project code is not covered by BCQuality knowledge; the sample appends AccountingCost only for brevity.
- Parsing the standard PEPPOL invoice content in the own IStructuredFormatReader rests on the agent's judgment; BCQuality knowledge only states that the reader fills the staging tables.
- How the E-Document Service is configured to use the new E-Doc. Read into Draft value is not stated in BCQuality knowledge.
- bc-version, countries and application-area are unknown (no repository supplied).

## Sources

[1] `microsoft/knowledge/e-documents/carry-custom-fields-through-e-document-export-and-import.md`: Export through the PEPPOL event and V2 import through a custom reader plus the after-processing subscriber.
    - Value must already be on the posted table (Sales Invoice Header) for export.
    - For PEPPOL subscribe to OnAfterCreatePEPPOLXMLDocument; read the field from the record ref, load the XML from the blob, add the element and write it back to the same blob.
    - Do not re-read the posted invoice by number in the PEPPOL subscriber; that bypasses the service mapping rules.
    - Add the field to E-Document Purchase Header and Purchase Header; fill the staging field in an own IStructuredFormatReader bound to a new E-Doc. Read into Draft value.
    - Subscribe to OnAfterProcessIncomingEDocument; act only when DesiredEndState is Processed, find the purchase header by E-Document Link, exit if none is linked.
    - Do not use V1 purchase-creation events for a V2 service, and do not expect Core to copy a staging extension field by matching name.
[2] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stage map for the sales field, page extensions, permission entries, Copy Document decision and posting tests.
    - Decide which stages the field must reach and plan one step per stage.
    - Name the page extensions, the permission set entries for new objects, and a test that posts and reads the value back from every target.
    - Decide whether Copy Document flowing the field back from posted documents is wanted; if not, clear it in OnAfterCopySalesHeaderDone.
    - Do not plan to fill ledger entries by modifying them after posting.
[3] `microsoft/knowledge/e-documents/e-document-creation-runs-after-the-posting-commit.md`: Where blocking checks belong and the setup needed for an E-Document to be created.
    - E-Document creation runs after the posting commit; errors in Create leave the invoice posted and set Export Error.
    - Rules that must stop posting go in the format Check.
    - Tests must enable the document sending profile, workflow and supported types or no E-Document is created and no error is raised.
    - No E-Document is created right after posting when commit is suppressed or in preview.
[4] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Sales header mirror fields on posted headers and archive.
    - Same field number, name, type and length on Sales Header and every target the plan needs: all four posted headers and the archive unless the plan states a document type never needs it.
    - No subscriber is needed for TransferFields stages.
    - Keep mirrored fields non-editable on posted tables.
[5] `microsoft/knowledge/sales-purchase/mirror-purchase-fields-on-every-transferfields-target.md`: Purchase header mirror fields on posted headers and archive.
    - Same field number, name, type and length on Purchase Header and all four posted tables and the archive unless the plan states a document type never needs it.
    - No subscriber for TransferFields stages; keep mirrored fields non-editable on posted tables.
[6] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Field definition consistency across both cascades.
    - Mirrored fields must have the exact same field number, data type and length on every table in the cascade, set at creation time.
[7] `microsoft/knowledge/privacy/resolve-tobeclassified-before-release.md`: Data classification of all new fields.
    - No field ships with DataClassification = ToBeClassified; choose the classification from the data content.
[8] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Test fixtures.
    - Create customers, vendors, items and documents with the Library codeunits; create parents first and Validate foreign keys.
[9] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: Page extension fields.
    - User-facing page fields need an explicit or inherited tooltip; on runtime 13.0+ define it on the table field and do not duplicate it on pages (applies from BC24 for inheritance).

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
