// Demonstration only; independently authored, not copied from BaseApp.
// Purchase Line -> Job Journal Line -> Job Ledger Entry for item and G/L account lines with a project,
// and Purchase Line -> Res. Journal Line -> Res. Ledger Entry for resource lines.
// Assumes field 50120 "Cost Reason" Code[20] on Purchase Line, Job Journal Line, Job Ledger Entry,
// Res. Journal Line and Res. Ledger Entry.
codeunit 50120 "Purchase Cost Reason"
{
    // Item and G/L account lines with a project. G/L account lines are posted later from a
    // temporary copy of this journal line, so the value travels with it.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromPurchaseLineToJnlLine', '', false, false)]
    local procedure PurchaseLineToJobJnlLine(var JobJnlLine: Record "Job Journal Line"; PurchLine: Record "Purchase Line")
    begin
        JobJnlLine."Cost Reason" := PurchLine."Cost Reason";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromJnlLineToLedgEntry', '', false, false)]
    local procedure JobJnlLineToJobLedger(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."Cost Reason" := JobJournalLine."Cost Reason";
    end;

    // Resource purchase lines post only a resource ledger entry.
    [EventSubscriber(ObjectType::Table, Database::"Res. Journal Line", 'OnAfterCopyResJnlLineFromPurchaseLine', '', false, false)]
    local procedure PurchaseLineToResJnlLine(PurchaseLine: Record "Purchase Line"; var ResJournalLine: Record "Res. Journal Line")
    begin
        ResJournalLine."Cost Reason" := PurchaseLine."Cost Reason";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Res. Ledger Entry", 'OnAfterCopyFromResJnlLine', '', false, false)]
    local procedure ResJnlLineToResLedger(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
        ResLedgerEntry."Cost Reason" := ResJournalLine."Cost Reason";
    end;
}
