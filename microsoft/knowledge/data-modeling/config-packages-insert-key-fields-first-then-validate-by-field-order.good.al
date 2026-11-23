// Demonstration only; independently authored, not copied from BaseApp.
// OnInsert needs only the key. The customer field (2) defaults the fields after it (3, 4),
// so values for 3 and 4 in a configuration package are applied after the default.
table 50140 "Site Contract"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Customer No."; Code[20])
        {
            TableRelation = Customer;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                if Customer.Get("Customer No.") then begin
                    "Site Name" := Customer.Name;
                    "Contact Name" := Customer.Contact;
                end;
            end;
        }
        field(3; "Site Name"; Text[100]) { }
        field(4; "Contact Name"; Text[100])
        {
            trigger OnValidate()
            begin
                // Interactive check, not wanted during a package import.
                if ("Contact Name" <> xRec."Contact Name") and (xRec."Contact Name" <> '') then
                    if not Confirm('Replace contact %1?', false, xRec."Contact Name") then
                        Error('');
            end;
        }
        field(5; "Created At"; DateTime) { Editable = false; }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        "Created At" := CurrentDateTime();
    end;
}

codeunit 50140 "Site Contract Config. Package"
{
    // A field whose OnValidate cannot run during an import is imported without validation by default.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Package Management", 'OnBeforeValidateException', '', false, false)]
    local procedure SkipValidationOnImport(TableID: Integer; FieldID: Integer; var Result: Boolean; var IsHandled: Boolean)
    var
        SiteContract: Record "Site Contract";
    begin
        if (TableID = Database::"Site Contract") and (FieldID = SiteContract.FieldNo("Contact Name")) then begin
            Result := true;
            IsHandled := true;
        end;
    end;
}
