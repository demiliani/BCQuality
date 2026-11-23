// Demonstration only; independently authored, not copied from BaseApp.
// A custom document builds one Dimension Set ID from all its sources, the way Sales Header does.
// Assumes custom master tables 50161 "Equipment" and 50162 "Maintenance Contract" that own
// their Default Dimension rows, and a source code "MAINT" set up for priorities.
table 50160 "Maintenance Order Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Customer No."; Code[20])
        {
            TableRelation = Customer;
            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Customer No."));
            end;
        }
        field(3; "Item No."; Code[20])
        {
            TableRelation = Item;
            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Item No."));
            end;
        }
        field(4; "Equipment No."; Code[20])
        {
            TableRelation = Equipment;
            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Equipment No."));
            end;
        }
        field(5; "Contract No."; Code[20])
        {
            TableRelation = "Maintenance Contract";
            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Contract No."));
            end;
        }
        field(10; "Shortcut Dimension 1 Code"; Code[20]) { CaptionClass = '1,2,1'; }
        field(11; "Shortcut Dimension 2 Code"; Code[20]) { CaptionClass = '1,2,2'; }
        field(480; "Dimension Set ID"; Integer) { TableRelation = "Dimension Set Entry"; Editable = false; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        // Rebuild from all sources; InheritFromDimSetID 0 drops values of a cleared or replaced source.
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, 'MAINT', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        // The field just validated goes first; Default Dimension Priority rows for 'MAINT' still override the order.
        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, "Customer No.", FieldNo = FieldNo("Customer No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Item, "Item No.", FieldNo = FieldNo("Item No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Equipment, "Equipment No.", FieldNo = FieldNo("Equipment No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Maintenance Contract", "Contract No.", FieldNo = FieldNo("Contract No."));
        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var MaintenanceOrderHeader: Record "Maintenance Order Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    var
        DimMgt: Codeunit DimensionManagement;
}

// Adding the same custom master as a source of a standard service contract.
tableextension 50163 "Serv. Contract Equipment" extends "Service Contract Header"
{
    fields
    {
        field(50160; "Equipment No."; Code[20])
        {
            Caption = 'Equipment No.';
            DataClassification = CustomerContent;
            TableRelation = Equipment;
            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Equipment No."));
            end;
        }
    }
}

codeunit 50160 "Serv. Contract Equipment Dims"
{
    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnAfterInitDefaultDimensionSources', '', false, false)]
    local procedure AddEquipmentSource(var ServiceContractHeader: Record "Service Contract Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Equipment, ServiceContractHeader."Equipment No.",
            FieldNo = ServiceContractHeader.FieldNo("Equipment No."));
    end;
}
