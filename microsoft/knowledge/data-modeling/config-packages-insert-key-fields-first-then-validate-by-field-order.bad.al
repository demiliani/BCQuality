// Demonstration only; independently authored, not copied from BaseApp.
// OnInsert depends on a non-key field, and a low-numbered field is overwritten by a higher one.
table 50140 "Site Contract"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Site Name"; Text[100]) { }
        field(3; "Customer No."; Code[20])
        {
            TableRelation = Customer;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                // Validated after field 2 in a package: replaces the site name from the file.
                if Customer.Get("Customer No.") then
                    "Site Name" := Customer.Name;
            end;
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        // A configuration package inserts with only "No." set: this always fails there.
        TestField("Customer No.");
    end;
}
