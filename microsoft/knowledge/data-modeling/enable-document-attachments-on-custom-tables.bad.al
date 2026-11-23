// Demonstration only; independently authored, not copied from BaseApp.
// The factbox is wired, but Document Attachment Mgmt cannot map the table's key:
// filters, delete and rename fall back to "Table ID" only.
table 50100 "Equipment Request"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[100]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnDelete()
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
    begin
        // Without OnAfterTableHasNumberFieldPrimaryKey this deletes the files of every request.
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;
}

page 50100 "Equipment Request Card"
{
    PageType = Card;
    SourceTable = "Equipment Request";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { }
        }
        area(FactBoxes)
        {
            part(Attachments; "Doc. Attachment List Factbox")
            {
                SubPageLink = "Table ID" = const(Database::"Equipment Request"), "No." = field("No.");
            }
        }
    }
}

codeunit 50101 "Post Equipment Request"
{
    local procedure CopyAttachmentsToPosted(EquipmentRequest: Record "Equipment Request"; PostedEquipmentRequest: Record "Posted Equipment Request")
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        FromRecRef.GetTable(EquipmentRequest);
        ToRecRef.GetTable(PostedEquipmentRequest);
        // Reads field 1 as a document type enum and field 3 as "No.": built for sales and purchase headers only.
        DocumentAttachmentMgmt.CopyAttachmentsForPostedDocs(FromRecRef, ToRecRef);
    end;
}
