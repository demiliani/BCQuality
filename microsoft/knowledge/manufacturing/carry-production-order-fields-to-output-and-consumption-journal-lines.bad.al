// Demonstration only; independently authored, not copied from BaseApp.
// Covers only the Production Journal page; typed lines, exploded routings and Calc. Consumption stay empty.
codeunit 50175 "Prod. Batch Ref. Journal"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Production Journal Mgt", 'OnBeforeInsertOutputJnlLine', '', false, false)]
    local procedure FromProductionJournalOutput(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        ItemJournalLine."Customer Batch Ref." := ProdOrderLine."Customer Batch Ref.";
    end;
}
