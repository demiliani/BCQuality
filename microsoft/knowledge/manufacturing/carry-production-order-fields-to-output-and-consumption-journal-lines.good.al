// Demonstration only; independently authored, not copied from BaseApp.
// One copy procedure, called from every path that builds output or consumption lines.
// Assumes Prod. Order Line and Item Journal Line extensions with field 50175 "Customer Batch Ref." Code[30].
codeunit 50175 "Prod. Batch Ref. Journal"
{
    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyFromProdOrderLine', '', false, false)]
    local procedure FromTypedOutputLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        CopyBatchRef(ItemJournalLine, ProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Production Journal Mgt", 'OnBeforeInsertOutputJnlLine', '', false, false)]
    local procedure FromProductionJournalOutput(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        CopyBatchRef(ItemJournalLine, ProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Production Journal Mgt", 'OnBeforeInsertConsumptionJnlLine', '', false, false)]
    local procedure FromProductionJournalConsumption(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        CopyBatchRef(ItemJournalLine, ProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Output Jnl.-Expl. Route", 'OnBeforeOutputItemJnlLineInsert', '', false, false)]
    local procedure FromExplodedRouting(var ItemJournalLine: Record "Item Journal Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.") then
            CopyBatchRef(ItemJournalLine, ProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Calc. Consumption", 'OnBeforeInsertItemJnlLine', '', false, false)]
    local procedure FromCalcConsumption(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.") then
            CopyBatchRef(ItemJournalLine, ProdOrderLine);
    end;

    local procedure CopyBatchRef(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        ItemJournalLine."Customer Batch Ref." := ProdOrderLine."Customer Batch Ref.";
    end;
}
