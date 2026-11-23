// Demonstration only; independently authored, not copied from BaseApp.
// Mirrors the field by number only; Whse.-Post Shipment does not use TransferFields
// for the posted shipment header, so the value is never copied.
tableextension 50180 "Posted Whse. Shpt. Hdr. Slot" extends "Posted Whse. Shipment Header"
{
    fields
    {
        field(50180; "Carrier Slot"; Code[20])
        {
            Caption = 'Carrier Slot';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
