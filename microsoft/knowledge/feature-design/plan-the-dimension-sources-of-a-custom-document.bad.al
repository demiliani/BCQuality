// Demonstration only; independently authored, not copied from BaseApp.
// Anti-pattern: each field computes the set from its own source only, so the last field validated wins
// and the other sources' dimensions disappear. Inheriting the old set instead keeps stale values.
table 50164 "Maintenance Order Header Bad"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Customer No."; Code[20])
        {
            TableRelation = Customer;
            trigger OnValidate()
            var
                DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
            begin
                DimMgt.AddDimSource(DefaultDimSource, Database::Customer, "Customer No.");
                "Dimension Set ID" := DimMgt.GetDefaultDimID(
                    DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
            end;
        }
        field(3; "Item No."; Code[20])
        {
            TableRelation = Item;
            trigger OnValidate()
            var
                DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
            begin
                DimMgt.AddDimSource(DefaultDimSource, Database::Item, "Item No.");
                // Inherits the current set: a dimension from a previous item survives a change of item.
                "Dimension Set ID" := DimMgt.GetDefaultDimID(
                    DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Dimension Set ID", Database::Customer);
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

    var
        DimMgt: Codeunit DimensionManagement;
}
