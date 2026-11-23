// Demonstration only; independently authored, not copied from BaseApp.
// Copies a Transfer Header field to posted shipment and receipt headers in their copy events.
tableextension 50170 "Transfer Header Carrier Ref." extends "Transfer Header"
{
    fields
    {
        field(50170; "Carrier Booking Ref."; Code[20])
        {
            Caption = 'Carrier Booking Ref.';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50171 "Trans. Shpt. Hdr. Carrier Ref." extends "Transfer Shipment Header"
{
    fields
    {
        field(50170; "Carrier Booking Ref."; Code[20])
        {
            Caption = 'Carrier Booking Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50172 "Trans. Rcpt. Hdr. Carrier Ref." extends "Transfer Receipt Header"
{
    fields
    {
        field(50170; "Carrier Booking Ref."; Code[20])
        {
            Caption = 'Carrier Booking Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50170 "Carrier Ref. Transfer Posting"
{
    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", 'OnAfterCopyFromTransferHeader', '', false, false)]
    local procedure CopyToShipmentHeader(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferHeader: Record "Transfer Header")
    begin
        TransferShipmentHeader."Carrier Booking Ref." := TransferHeader."Carrier Booking Ref.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Receipt Header", 'OnAfterCopyFromTransferHeader', '', false, false)]
    local procedure CopyToReceiptHeader(var TransferReceiptHeader: Record "Transfer Receipt Header"; TransferHeader: Record "Transfer Header")
    begin
        TransferReceiptHeader."Carrier Booking Ref." := TransferHeader."Carrier Booking Ref.";
    end;
}
