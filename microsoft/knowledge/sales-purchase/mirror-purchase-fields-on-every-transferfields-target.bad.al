// Demonstration only; independently authored, not copied from BaseApp.
// Only the invoice header is extended, with a different field number, and a subscriber patches the value.
tableextension 50140 "Purch. Header Supplier Ref." extends "Purchase Header"
{
    fields
    {
        field(50140; "Supplier Contract Ref."; Code[20])
        {
            Caption = 'Supplier Contract Ref.';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50142 "Purch. Inv. Hdr. Supplier Ref." extends "Purch. Inv. Header"
{
    fields
    {
        // Field number differs from Purchase Header, so TransferFields skips it.
        field(50150; "Supplier Contract Ref."; Code[20])
        {
            Caption = 'Supplier Contract Ref.';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50140 "Copy Supplier Contract Ref."
{
    // Extra write per posted invoice; receipts, credit memos, return shipments and archives stay blank.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchInvHeaderInsert', '', false, false)]
    local procedure CopyToInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    begin
        PurchInvHeader."Supplier Contract Ref." := PurchHeader."Supplier Contract Ref.";
        PurchInvHeader.Modify();
    end;
}
