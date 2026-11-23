// Demonstration only; independently authored, not copied from BaseApp.
// Replaces the standard comparison on every call: item, quantity and date changes no longer reach the assembly order.
codeunit 50185 "ATO Engraving Sync"
{
    [EventSubscriber(ObjectType::Table, Database::"Assemble-to-Order Link", 'OnBeforeNeedsSynchronization', '', false, false)]
    local procedure SyncWhenEngravingChanged(AssemblyHeader: Record "Assembly Header"; SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        Result := SalesLine."Engraving Text" <> AssemblyHeader."Engraving Text";
        IsHandled := true;
    end;
}
