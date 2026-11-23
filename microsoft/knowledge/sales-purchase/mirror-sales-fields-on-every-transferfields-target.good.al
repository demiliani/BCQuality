// Demonstration only; independently authored, not copied from BaseApp.
// The same field number, name, type and length on the source and on every TransferFields target.
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

tableextension 50101 "Sales Shpt. Hdr. Delivery Win." extends "Sales Shipment Header"
{
    fields
    {
        field(50100; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50102 "Sales Inv. Hdr. Delivery Win." extends "Sales Invoice Header"
{
    fields
    {
        field(50100; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50103 "Sales Cr.M. Hdr. Delivery Win." extends "Sales Cr.Memo Header"
{
    fields
    {
        field(50100; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50104 "Ret. Rcpt. Hdr. Delivery Win." extends "Return Receipt Header"
{
    fields
    {
        field(50100; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50105 "Sales Hdr. Arch. Delivery Win." extends "Sales Header Archive"
{
    fields
    {
        field(50100; "Delivery Window"; Code[20])
        {
            Caption = 'Delivery Window';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
