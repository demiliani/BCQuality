---
bc-version: [all]
domain: data-modeling
keywords: [document-attachment, document-attachment-mgmt, doc-attachment-list-factbox, onaftertablehasnumberfieldprimarykey, onaftergetreftable, oncopyattachmentsonaftersetfromparameters, copyattachments, deleteattacheddocuments, moveattachmentswithinsamerecordtype, posted-document]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Enable document attachments on a custom table through Document Attachment Mgmt

## Description

Table 1173 `Document Attachment` stores files for any record by `Table ID`, `No.`, `Document Type` and `Line No.`. It does not know the key of a custom table. Codeunit 1173 `Document Attachment Mgmt` maps a record to those fields only for the base tables it lists, and asks extensions for the rest through events.

For a custom table nothing is mapped until the extension subscribes. The result is not an error but wrong data:

- `SetDocumentAttachmentFiltersForRecRef` filters only on `Table ID`. The details page and `AttachedDocumentsExist` then see the attachments of every record of the table.
- `DeleteAttachedDocuments` uses the same filter and calls `DeleteAll(true)`. Deleting one record deletes the attachments of all records of the table.
- `InitFieldsFromRecRef` on `Document Attachment` leaves `No.` blank, so a new file is stored without its owner.
- The factbox `Doc. Attachment List Factbox` resolves the source record with `GetRefTable`. It returns no record for an unknown table, and the upload action raises an error.
- `MoveAttachmentsWithinSameRecordType` filters on `No.` only when `TableIsEntity` is true. Otherwise a rename moves every attachment of the table to the new number.
- `CopyAttachments` sets the "from" filter and the "to" `No.` only for base tables. For a custom pair it copies all attachments of the source table with a blank `No.`.

`CopyAttachmentsForPostedDocs` is not an option for a custom table. It reads field 1 as the document type and field 3 as `No.`, which fits sales and purchase headers only.

## Best Practice

Treat the custom table like Base App treats `Service Item` in `Serv. Document Attachment Mgt.`:

- Subscribe to `OnAfterTableHasNumberFieldPrimaryKey` and return the field number of the `Code[20]` key for the table and for its posted counterpart. This drives filters, `InitFieldsFromRecRef` and delete.
- Subscribe to `OnAfterGetRefTable` and `Get` the record from `DocumentAttachment."No."`.
- Subscribe to `OnAfterTableIsEntity` so a rename moves only that record's files.
- Add the part `Doc. Attachment List Factbox` with `SubPageLink = "Table ID" = const(Database::<table>), "No." = field("No.")`, as `Customer Card` does. For a full action, call `OpenForRecRef` on page `Document Attachment Details`.
- Call `DeleteAttachedDocuments` from the table's `OnDelete` and `MoveAttachmentsWithinSameRecordType` from `OnRename`. Base App subscribes these only for its own tables.
- In the posting codeunit, after the posted record is inserted, call `CopyAttachments(FromRecRef, ToRecRef)`. Subscribe to `OnCopyAttachmentsOnAfterSetFromParameters` to filter on the source `No.`, and to `OnCopyAttachmentsOnAfterSetToParameters` to set `ToNo`.

A table whose key is wider than `Code[20]`, or not a code at all, cannot use `No.` directly. Decide that before choosing this mechanism.

See sample: [`enable-document-attachments-on-custom-tables.good.al`](enable-document-attachments-on-custom-tables.good.al).

## Anti Pattern

Build a custom attachment table with its own BLOB field and upload page. It duplicates storage, loses the Media handling, the file viewer, OneDrive sharing and the attachment APIs, and is invisible to every standard attachment feature.

A milder form is a factbox wired with `SubPageLink` and no subscribers. It shows nothing wrong in a demo with one record, and then deletes or reassigns other records' files in production.

See sample: [`enable-document-attachments-on-custom-tables.bad.al`](enable-document-attachments-on-custom-tables.bad.al).

Related: [owning tables delete their dependents in OnDelete](owning-table-must-delete-dependents-in-ondelete.md), [pictures use Media, not BLOB](pictures-must-use-media-not-blob.md).

## References

- [Document Attachment Mgmt: GetRefTable, filters, delete, CopyAttachments, CopyAttachmentsForPostedDocs, events](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Foundation/Attachment/DocumentAttachmentMgmt.Codeunit.al).
- [Document Attachment: key, InitFieldsFromRecRef, OnAfterInitFieldsFromRecRef](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Foundation/Attachment/DocumentAttachment.Table.al).
- [Doc. Attachment List Factbox: ResolveSourceRecRef](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Foundation/Attachment/DocAttachmentListFactbox.Page.al).
- [Serv. Document Attachment Mgt.: reference subscriber set for Service Item](https://github.com/microsoft/BCApps/blob/e98908c676e733b5519c84e3cb2eca62ae7aeb03/src/Layers/W1/BaseApp/Service/Document/ServDocumentAttachmentMgt.Codeunit.al).
