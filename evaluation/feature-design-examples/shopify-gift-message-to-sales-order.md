# Feature design

> Our Shopify checkout collects a gift message as an order note attribute called gift-message. When the Shopify connector creates the sales order in Business Central, the gift message must be on the sales order and on the posted sales invoice.

**Result:** Complete design. **Business process:** Shopify order import into sales orders, then sales posting (Shopify Connector order processing feeding Sales-Post). **Knowledge used:** 11 BCQuality articles.

## 1. Questions to answer before implementation

The request does not settle these points. Answer them, then approve the design.

1. What is the maximum gift-message length the checkout allows? Choose the Gift Message field length from it; longer values are truncated by CopyStr. _(affects: sales-header-gift-message, sales-invoice-header-gift-message, sales-shipment-header-gift-message, sales-cr-memo-header-gift-message, return-receipt-header-gift-message, sales-header-archive-gift-message, long-gift-message-truncated)_
2. The request names only the sales order and the posted sales invoice. The mirroring rule also adds Gift Message to Sales Shipment Header, Sales Cr.Memo Header, Return Receipt Header and Sales Header Archive. Should any of these be excluded? _(affects: sales-shipment-header-gift-message, sales-cr-memo-header-gift-message, return-receipt-header-gift-message, sales-header-archive-gift-message, gift-message-on-posted-invoice-and-shipment, gift-message-on-return-receipt, gift-message-on-archive, gift-message-on-corrective-credit-memo)_
3. When a posted invoice is cancelled, corrected or copied with Copy Document, should the gift message be copied to the new document (default, no code) or cleared? _(affects: gift-message-on-corrective-credit-memo)_
4. Must the gift message also appear on the printed sales invoice or other report layouts, or only on the posted invoice record and page? _(affects: posted-sales-invoice-page-gift-message)_
5. May users edit the gift message on the sales order after it is created from Shopify? _(affects: sales-order-page-gift-message)_
6. Should Shopify sales orders created before the extension is installed be back-filled from Shpfy Order Attribute, or only new orders? _(affects: sales-header-gift-message)_
7. Which Business Central version does the app target? It decides whether page fields can inherit the table-field ToolTip. _(affects: sales-order-page-gift-message, posted-sales-invoice-page-gift-message)_

## 2. Objects

| # | Action | Type | Object | Purpose | Fields | Sources |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | extend | tableextension | Sales Header | Stores the gift message on the sales document the Shopify Connector creates. A stored field (not a FlowField to Shpfy Order Header) is chosen because the value must reach the posted sales invoice through TransferFields. | Gift Message (Text[250]): Field number and length are reused unchanged on every TransferFields target. Length depends on open question gift-message-length. DataClassification = CustomerContent. ToolTip on the table field when the target is BC24 or later. | [1] [4] [5] [6] [10] |
| 2 | extend | tableextension | Sales Invoice Header | Receives the gift message when the order is invoiced; required by the request. | Gift Message (Text[250]): Same field number, name, type and length as on Sales Header; non-editable on this posted or archive table. | [4] [5] [6] |
| 3 | extend | tableextension | Sales Shipment Header | Receives the gift message on posted shipments. Chosen by the mirroring rule, not by the request; see open question other-posted-targets. | Gift Message (Text[250]): Same field number, name, type and length as on Sales Header; non-editable on this posted or archive table. | [4] [5] [6] |
| 4 | extend | tableextension | Sales Cr.Memo Header | Receives the gift message on posted credit memos, including corrective credit memos created by Cancel or Correct. Chosen by the mirroring rule, not by the request; see open question other-posted-targets. | Gift Message (Text[250]): Same field number, name, type and length as on Sales Header; non-editable on this posted or archive table. | [4] [5] [6] |
| 5 | extend | tableextension | Return Receipt Header | Receives the gift message on posted return receipts. Chosen by the mirroring rule, not by the request; see open question other-posted-targets. | Gift Message (Text[250]): Same field number, name, type and length as on Sales Header; non-editable on this posted or archive table. | [4] [5] [6] |
| 6 | extend | tableextension | Sales Header Archive | Keeps the gift message when the order is archived. Chosen by the mirroring rule, not by the request; see open question other-posted-targets. | Gift Message (Text[250]): Same field number, name, type and length as on Sales Header; non-editable on this posted or archive table. | [4] [5] [6] |
| 7 | create | codeunit | Shopify Gift Message | Holds the subscriber to Shpfy Order Events OnAfterCreateSalesHeader that reads the gift-message order attribute and writes it to the created sales header. Requires an app.json dependency on the Shopify Connector app. |  | [1] [2] [7] |
| 8 | extend | pageextension | Sales Order | Shows the gift message on the sales order. The field inherits the table-field ToolTip on BC24 or later; on earlier targets the page field needs its own ToolTip. |  | [3] [10] [11] |
| 9 | extend | pageextension | Posted Sales Invoice | Shows the gift message, read-only, on the posted sales invoice. Same ToolTip rule as on the sales order page. |  | [3] [10] [11] |

## 3. How the data flows

- **Shpfy Order Attribute (Key = 'gift-message', Attribute Value)** → **Sales Header.Gift Message**: copied in an event subscriber. Shpfy Import Order stores note attributes in Shpfy Order Attribute keyed by Order Id and Key. In OnAfterCreateSalesHeader, Get the attribute by OrderHeader."Shopify Order Id" and 'gift-message', assign with CopyStr to the field length, and call Modify because the header already exists. Shpfy Process Order builds the sales header field by field, not with TransferFields. [1]
- **Sales Header.Gift Message** → **Sales Invoice Header.Gift Message**: standard TransferFields copy. Sales-Post creates the posted invoice header with TransferFields; no subscriber needed. [4] [5] [3]
- **Sales Header.Gift Message** → **Sales Shipment Header.Gift Message**: standard TransferFields copy. [4] [5] [3]
- **Sales Header.Gift Message** → **Sales Cr.Memo Header.Gift Message**: standard TransferFields copy. [4] [5] [3]
- **Sales Header.Gift Message** → **Return Receipt Header.Gift Message**: standard TransferFields copy. [4] [5] [3]
- **Sales Header.Gift Message** → **Sales Header Archive.Gift Message**: standard TransferFields copy. ArchiveManagement archives the header with TransferFields. [4] [3]
- **Sales Invoice Header.Gift Message** → **Sales Header.Gift Message (corrective credit memo or copied document)**: standard TransferFields copy. Copy Document Mgt. copies the posted invoice header back with TransferFields for Cancel, Correct and manual Copy Document. The gift message is treated as business data, so it stays mirrored with no code; if the requester does not want it copied back, clear it in OnAfterCopySalesHeaderDone (see open question copy-document-behavior). [8] [3]

## 4. Event subscriptions

| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |
| --- | --- | --- | --- | --- |
| Codeunit "Shpfy Order Events" (30162) | `OnAfterCreateSalesHeader(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")` | Copy the gift-message order attribute to Sales Header.Gift Message after the connector has inserted and filled the header. Fires even when an OnBeforeCreateSalesHeader subscriber handled creation. | Exit without error when no Shpfy Order Attribute with Key 'gift-message' exists for the order. · Truncate with CopyStr to MaxStrLen of the field. · Call Modify on SalesHeader because the record already exists. · No Commit in the subscriber. · No Confirm, Message-based reporting, or pages: processing can run in a job queue session. · An error raised here marks the Shopify order Has Error and deletes the created sales document; raise one only deliberately. | [1] [2] [7] |

## 5. Setup, permissions and lifecycle

- **other**: Add an app.json dependency on Shopify Connector (id ec255f57-31d0-4ca2-b751-f2fa7c745abb, publisher Microsoft). Use only its integration events; Shpfy Process Order and Shpfy Import Order are Access = Internal and cannot be called. [2]
- **privacy**: Set DataClassification = CustomerContent on Gift Message in every table extension; a tableextension field has no table-level value to inherit. [6]
- **background**: Keep the subscriber non-interactive: Shopify order sync and sales-document creation can run as a job queue entry when Allow Background Syncs is on. [2] [7]

## 6. Tests

1. **gift-message-copied-on-order-creation** [1]
    - Given A Shopify order header and a Shpfy Order Attribute with Key 'gift-message' and a random text value.
    - When The connector creates the sales order for that Shopify order (OnAfterCreateSalesHeader runs).
    - Then Sales Header.Gift Message equals the attribute value.
2. **no-gift-message-attribute-leaves-field-blank** [1]
    - Given A Shopify order with no 'gift-message' attribute.
    - When The connector creates the sales order.
    - Then The sales order is created without error and Gift Message is blank.
3. **long-gift-message-truncated** [1]
    - Given A 'gift-message' attribute longer than the Gift Message field.
    - When The connector creates the sales order.
    - Then The order is created without error and Gift Message holds the first MaxStrLen characters.
4. **gift-message-on-posted-invoice-and-shipment** [4] [5] [3] [9]
    - Given A customer, an item and a sales order created with Library - Sales, with Gift Message set to a random text of full field length.
    - When The order is posted with ship and invoice.
    - Then Sales Invoice Header and Sales Shipment Header carry the same Gift Message.
5. **gift-message-on-return-receipt** [4] [9]
    - Given A sales return order created with Library - Sales with Gift Message set.
    - When The return order is posted with receive.
    - Then Return Receipt Header carries the Gift Message.
6. **gift-message-on-archive** [4] [9]
    - Given A sales order with Gift Message set.
    - When The order is archived.
    - Then Sales Header Archive carries the Gift Message.
7. **gift-message-on-corrective-credit-memo** [8] [4] [9]
    - Given A posted sales invoice with Gift Message filled.
    - When The user runs Cancel on the posted invoice.
    - Then The posted Sales Cr.Memo Header carries the Gift Message (or is blank if copy-document-behavior decides to clear it).

## 7. Limits of this design

These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.

- Context dimensions unknown: bc-version, countries and application-area; tooltip inheritance articles apply only from BC24.
- How a test app drives the Shopify Connector's order processing to raise OnAfterCreateSalesHeader is not covered by BCQuality knowledge; Shpfy Process Order is Access = Internal. The tests gift-message-copied-on-order-creation, no-gift-message-attribute-leaves-field-blank and long-gift-message-truncated rest on the agent's judgment for their When step (for example, calling the copy logic through a procedure the subscriber also uses).
- Page names Sales Order and Posted Sales Invoice as extension targets are the agent's judgment; the cited articles require a page extension but do not name the pages.

## Sources

[1] `microsoft/knowledge/shopify/carry-shopify-order-values-to-the-created-sales-document.md`: Mechanism and event for moving the gift-message note attribute from the Shopify order to the created sales header.
    - Shpfy Process Order builds Sales Header field by field without TransferFields, so a custom value needs code.
    - Note attributes are stored in Shpfy Order Attribute keyed by Order Id and Key, with the text in Attribute Value; read the stored value, do not fetch the order again.
    - Subscribe to Shpfy Order Events OnAfterCreateSalesHeader, assign the value and call Modify, because the header already exists.
    - A stored field reaches posted documents through TransferFields; a FlowField to Shpfy Order Header is not copied on posting.
    - Do not Commit in the subscriber; do not use Confirm or pages.
    - Do not use Sales Header OnAfterInsertEvent (Shpfy Order Id is not yet set) or OnAfterImportShopifyOrderHeader (no sales document exists yet).
[2] `microsoft/knowledge/shopify/extend-the-shopify-connector-through-integration-events-and-public-objects.md`: Dependency and extension-point constraints for the Shopify Connector.
    - Depend on Shopify Connector, id ec255f57-31d0-4ca2-b751-f2fa7c745abb, publisher Microsoft.
    - Use only [IntegrationEvent] publishers; check each event exists and is an integration event before designing.
    - Shpfy Process Order, Shpfy Import Order and related codeunits are Access = Internal and cannot be called.
    - Subscribers must not need UI and must not Commit; syncs can run as job queue entries.
    - If a needed event is missing, request it in BCApps; do not copy connector code.
[3] `microsoft/knowledge/sales-purchase/plan-the-full-path-of-a-custom-sales-field.md`: Stage map for where the sales header field must travel, and the Copy Document decision.
    - Plan one step per stage the field must reach; posted headers and the archive are reached by TransferFields.
    - Name the page extensions that show the field and add a test that posts a document and reads the value back from every target.
    - Copy Document copies posted and archived headers back with TransferFields; decide whether that is wanted and, if not, clear the field in OnAfterCopySalesHeaderDone.
    - Do not plan only the tables the requester named.
[4] `microsoft/knowledge/sales-purchase/mirror-sales-fields-on-every-transferfields-target.md`: Mirroring Gift Message on every TransferFields target of Sales Header.
    - Same field number, name, type and length on Sales Header and on Sales Shipment Header, Sales Invoice Header, Sales Cr.Memo Header, Return Receipt Header and Sales Header Archive, unless the plan states a document type never needs it.
    - No subscriber is needed for these stages.
    - Keep mirrored fields non-editable on posted tables.
    - Do not copy with OnAfter...Insert subscribers and Modify.
[5] `microsoft/knowledge/data-modeling/transferfields-mirrored-fields-must-match-type-and-length.md`: Type and length agreement for the mirrored Gift Message field.
    - Define the mirrored field with the exact same field number, data type and length on every table in the cascade at creation time.
    - A shorter length on a target compiles but fails at runtime once a value exceeds it.
[6] `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`: Data classification of the gift message.
    - Every Normal field added by a tableextension must set its own DataClassification.
    - Customer-provided content is CustomerContent; do not leave ToBeClassified or use SystemMetadata.
[7] `microsoft/knowledge/performance/job-queue-handlers-must-not-require-ui.md`: Non-interactive subscriber, because order processing can run in a job queue session.
    - No Confirm, Page.Run/RunModal, Report.Run/RunModal, Hyperlink, upload or download in code run by the job queue.
    - Do not use Message as the only result notification; let failures propagate.
[8] `microsoft/knowledge/sales-purchase/corrective-credit-memo-copies-custom-fields-from-the-posted-invoice.md`: Behavior of Gift Message on Cancel and Correct of the posted invoice.
    - A field mirrored on the posted invoice is copied to the corrective credit memo and its posted header.
    - Business data stays mirrored with no code; per-document state is cleared in OnAfterCopySalesHeaderDone on Copy Document Mgt.
    - Test Cancel on an invoice with the field filled and read the posted credit memo back.
[9] `microsoft/knowledge/testing/use-library-codeunits-for-test-fixtures.md`: Fixtures for the posting, return, archive and corrective credit memo tests.
    - Create customers, items and sales documents with Library - Sales, Library - Inventory and Library - Random, not with hand-rolled Init/Insert.
    - Create parents before dependent records and Validate foreign keys.
[10] `microsoft/knowledge/style/tooltip-required-on-page-fields.md`: ToolTip for Gift Message on the sales order and posted invoice pages. Applies from BC24 (runtime 13.0) for table-field inheritance; target version unknown.
    - On runtime 13.0 or later, define the ToolTip on the table field and omit duplicate page-level ToolTips.
    - Before runtime 13.0, user-facing page fields need page-level ToolTips.
    - Tooltip text must say what the value is used for, not just repeat the caption, and must not invent behavior.
[11] `microsoft/knowledge/ui/bound-page-field-inherits-source-field-tooltip.md`: Confirms bound page fields inherit the table-field ToolTip. Applies from BC24 (runtime 13.0); target version unknown.
    - A page field bound to a table field with a non-empty ToolTip inherits it on runtime 13.0 or later.
    - A control with neither an inline nor an inherited ToolTip is a real gap.

_Context: BC version unknown; countries unknown; application areas unknown. Unknown: bc-version, countries, application-area. Produced by BCQuality `al-feature-design` v1. The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._
