// Demonstration only; independently authored, not copied from BaseApp.
// Sets IsHandled to add one field, which skips the standard application and posting of the line.
codeunit 50220 "Bank Batch Ref. Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank Acc. Reconciliation Post", 'OnPostPaymentApplicationsOnAfterInitGenJnlLine', '', false, false)]
    local procedure CopyToJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var IsHandled: Boolean)
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        GenJournalLine."Bank Batch Ref." := BankAccReconciliationLine."Bank Batch Ref.";
        GenJnlPostLine.RunWithCheck(GenJournalLine);
        IsHandled := true;
    end;
}
