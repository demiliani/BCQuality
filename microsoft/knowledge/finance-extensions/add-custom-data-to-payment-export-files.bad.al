// Demonstration only; independently authored, not copied from BaseApp.
// The event name is "corrected" to the spelling the developer expected, so it names an event that does not exist,
// and the OnPrem-scoped older event is used as if it were available online.
codeunit 50210 "Payment Priority Export"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exp. Pre-Mapping Gen. Jnl.", 'OnBeforeInsertPaymentExportData', '', false, false)]
    local procedure SetPriority(var PaymentExportData: Record "Payment Export Data"; GenJournalLine: Record "Gen. Journal Line")
    begin
        PaymentExportData."Payment Priority Code" := GenJournalLine."Payment Priority Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Pmt Export Mgt Gen. Jnl Line", 'OnBeforeInsertPmtExportDataJnlFromGenJnlLine', '', false, false)]
    local procedure SetPriorityOldPath(var PaymentExportData: Record "Payment Export Data"; GenJournalLine: Record "Gen. Journal Line")
    begin
        PaymentExportData."Payment Priority Code" := GenJournalLine."Payment Priority Code";
    end;
}
