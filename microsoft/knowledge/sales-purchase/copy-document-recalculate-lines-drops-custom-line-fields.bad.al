// Demonstration only; independently authored, not copied from BaseApp.
// Patches every copied line after insert, on both copy paths.
codeunit 50120 "Packing Note Copy Document"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterInsertToSalesLine', '', false, false)]
    local procedure PatchSalesPackingNote(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
        // Extra write per line, and no purchase subscriber at all.
        ToSalesLine."Packing Note" := FromSalesLine."Packing Note";
        ToSalesLine.Modify();
    end;
}
