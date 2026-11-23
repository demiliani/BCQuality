// Demonstration only; independently authored, not copied from BaseApp.
// Relies on a matching field number, as on sales documents: CopyFromTransferHeader never copies it.
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
        // Same number as on Transfer Header, but no subscriber copies it: the posted field stays blank.
        field(50170; "Carrier Booking Ref."; Code[20])
        {
            Caption = 'Carrier Booking Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
