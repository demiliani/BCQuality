// Demonstration only; independently authored, not copied from BaseApp.
// Only the invoice header is extended, with a different field number, and a subscriber patches the value.
tableextension 50100 "Sales Header Delivery Window" extends "Sales Header"
{
    fields
    {
        field(50100; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50102 "Sales Inv. Hdr. Delivery Win." extends "Sales Invoice Header"
{
    fields
    {
        // Field number differs from Sales Header, so TransferFields skips it.
        field(50110; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50100 "Copy Delivery Window"
{
    // Extra write per posted invoice; shipments, credit memos, return receipts and archives stay blank.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvHeaderInsert', '', false, false)]
    local procedure CopyToInvoice(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header")
    begin
        SalesInvHeader."Delivery Window" := SalesHeader."Delivery Window";
        SalesInvHeader.Modify();
    end;
}
