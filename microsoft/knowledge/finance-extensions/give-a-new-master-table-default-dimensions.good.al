// Demonstration only; independently authored, not copied from BaseApp.
// A master table that owns its default dimensions, kept in sync with the Default Dimensions page.
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
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1), Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(4; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2), Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        DimMgt.UpdateDefaultDim(Database::"Service Contract Type", "No.", "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(Database::"Service Contract Type", xRec."No.", "No.");
    end;

    trigger OnDelete()
    begin
        DimMgt.DeleteDefaultDim(Database::"Service Contract Type", "No.");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary() then begin
            DimMgt.SaveDefaultDim(Database::"Service Contract Type", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;

    var
        DimMgt: Codeunit DimensionManagement;
}

codeunit 50190 "Contract Type Global Dims"
{
    [EventSubscriber(ObjectType::Table, Database::"Default Dimension", 'OnAfterUpdateGlobalDimCode', '', false, false)]
    local procedure UpdateContractTypeGlobalDim(GlobalDimCodeNo: Integer; TableID: Integer; AccNo: Code[20]; NewDimValue: Code[20])
    var
        ServiceContractType: Record "Service Contract Type";
    begin
        if TableID <> Database::"Service Contract Type" then
            exit;
        if not ServiceContractType.Get(AccNo) then
            exit;
        case GlobalDimCodeNo of
            1:
                ServiceContractType."Global Dimension 1 Code" := NewDimValue;
            2:
                ServiceContractType."Global Dimension 2 Code" := NewDimValue;
        end;
        ServiceContractType.Modify(true);
    end;
}
