// Demonstration only; independently authored, not copied from BaseApp.
// Patches every inserted sales line after the fact; purchase credit memos stay uncovered.
codeunit 50140 "Inspection Result Returns"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure PatchCreditMemoLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        if Rec."Return Receipt No." = '' then
            exit;
        if ReturnReceiptLine.Get(Rec."Return Receipt No.", Rec."Return Receipt Line No.") then begin
            Rec."Inspection Result" := ReturnReceiptLine."Inspection Result";
            Rec.Modify();
        end;
    end;
}
