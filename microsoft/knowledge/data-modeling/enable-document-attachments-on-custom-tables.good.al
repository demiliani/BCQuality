// Demonstration only; independently authored, not copied from BaseApp.
// "Equipment Request" (50100) and "Posted Equipment Request" (50101) both have field 1 "No." Code[20] as their key.
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
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    trigger OnRename()
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        FromRecRef.GetTable(xRec);
        ToRecRef.GetTable(Rec);
        DocumentAttachmentMgmt.MoveAttachmentsWithinSameRecordType(FromRecRef, ToRecRef);
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
            field(Description; Rec.Description) { }
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

codeunit 50100 "Equipment Request Attachments"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasNumberFieldPrimaryKey', '', false, false)]
    local procedure SetNumberField(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        if TableNo in [Database::"Equipment Request", Database::"Posted Equipment Request"] then begin
            FieldNo := 1;
            Result := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterGetRefTable', '', false, false)]
    local procedure ResolveRecord(var RecRef: RecordRef; DocumentAttachment: Record "Document Attachment")
    var
        EquipmentRequest: Record "Equipment Request";
        PostedEquipmentRequest: Record "Posted Equipment Request";
    begin
        case DocumentAttachment."Table ID" of
            Database::"Equipment Request":
                if EquipmentRequest.Get(DocumentAttachment."No.") then
                    RecRef.GetTable(EquipmentRequest);
            Database::"Posted Equipment Request":
                if PostedEquipmentRequest.Get(DocumentAttachment."No.") then
                    RecRef.GetTable(PostedEquipmentRequest);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableIsEntity', '', false, false)]
    local procedure MarkAsEntity(TableNo: Integer; var IsEntity: Boolean)
    begin
        if TableNo = Database::"Equipment Request" then
            IsEntity := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsOnAfterSetFromParameters', '', false, false)]
    local procedure FilterSource(FromRecRef: RecordRef; var FromDocumentAttachment: Record "Document Attachment"; var FromAttachmentDocumentType: Enum "Attachment Document Type")
    begin
        if FromRecRef.Number() = Database::"Equipment Request" then
            FromDocumentAttachment.SetRange("No.", Format(FromRecRef.Field(1).Value()));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsOnAfterSetToParameters', '', false, false)]
    local procedure SetTarget(var ToDocumentAttachment: Record "Document Attachment"; ToRecRef: RecordRef; var ToFieldRef: FieldRef; var ToNo: Code[20]; var ToLineNo: Integer; var ToAttachmentDocumentType: Enum "Attachment Document Type")
    begin
        if ToRecRef.Number() = Database::"Posted Equipment Request" then begin
            ToFieldRef := ToRecRef.Field(1);
            ToNo := ToFieldRef.Value();
        end;
    end;

    // Called by the posting codeunit after the posted record is inserted.
    procedure CopyToPosted(EquipmentRequest: Record "Equipment Request"; PostedEquipmentRequest: Record "Posted Equipment Request")
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        FromRecRef: RecordRef;
        ToRecRef: RecordRef;
    begin
        FromRecRef.GetTable(EquipmentRequest);
        ToRecRef.GetTable(PostedEquipmentRequest);
        DocumentAttachmentMgmt.CopyAttachments(FromRecRef, ToRecRef);
    end;
}
