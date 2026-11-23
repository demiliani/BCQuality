// Demonstration only; independently authored, not copied from BaseApp.
// Copies the field on every synchronization and forces one when only the custom field changed.
// Assumes an Assembly Header extension with field 50185 "Engraving Text" Text[50].
tableextension 50185 "Sales Line Engraving" extends "Sales Line"
{
    fields
    {
        field(50185; "Engraving Text"; Text[50])
        {
            Caption = 'Engraving Text';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                AutoAsmToOrder();
            end;
        }
    }
}

codeunit 50185 "ATO Engraving Sync"
{
    [EventSubscriber(ObjectType::Table, Database::"Assemble-to-Order Link", 'OnBeforeAsmHeaderModify', '', false, false)]
    local procedure CopyToAssemblyHeader(var AssemblyHeader: Record "Assembly Header"; var SalesLine: Record "Sales Line")
    begin
        AssemblyHeader."Engraving Text" := SalesLine."Engraving Text";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assemble-to-Order Link", 'OnBeforeNeedsSynchronization', '', false, false)]
    local procedure SyncWhenEngravingChanged(AssemblyHeader: Record "Assembly Header"; SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        if SalesLine."Engraving Text" <> AssemblyHeader."Engraving Text" then begin
            Result := true;
            IsHandled := true;
        end;
    end;
}
