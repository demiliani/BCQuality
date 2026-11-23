// Demonstration only; independently authored, not copied from BaseApp.
// The same field number, name, type and length on the source and on every TransferFields target.
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

tableextension 50141 "Purch. Rcpt. Hdr. Supplier Ref" extends "Purch. Rcpt. Header"
{
    fields
    {
        field(50140; "Supplier Contract Ref."; Code[20])
        {
            Caption = 'Supplier Contract Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50142 "Purch. Inv. Hdr. Supplier Ref." extends "Purch. Inv. Header"
{
    fields
    {
        field(50140; "Supplier Contract Ref."; Code[20])
        {
            Caption = 'Supplier Contract Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50143 "Purch. Cr.M. Hdr. Supplier Ref" extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(50140; "Supplier Contract Ref."; Code[20])
        {
            Caption = 'Supplier Contract Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50144 "Ret. Shpt. Hdr. Supplier Ref." extends "Return Shipment Header"
{
    fields
    {
        field(50140; "Supplier Contract Ref."; Code[20])
        {
            Caption = 'Supplier Contract Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50145 "Purch. Hdr. Arch. Supplier Ref" extends "Purchase Header Archive"
{
    fields
    {
        field(50140; "Supplier Contract Ref."; Code[20])
        {
            Caption = 'Supplier Contract Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
