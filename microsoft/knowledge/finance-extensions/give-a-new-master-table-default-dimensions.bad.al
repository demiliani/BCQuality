// Demonstration only; independently authored, not copied from BaseApp.
// Global dimension fields with no default-dimension handling: no sync, orphaned rows on rename and delete.
table 50190 "Service Contract Type"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[100]) { }
        field(3; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(4; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
