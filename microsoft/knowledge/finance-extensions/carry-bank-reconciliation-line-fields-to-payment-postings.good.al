// Demonstration only; independently authored, not copied from BaseApp.
// Bank Acc. Reconciliation Line -> Gen. Journal Line during payment application, plus the posted history line.
// Assumes Bank Acc. Reconciliation Line and Gen. Journal Line extensions with field 50220 "Bank Batch Ref." Code[35].
tableextension 50220 "Posted Pmt. Recon. Batch Ref." extends "Posted Payment Recon. Line"
{
    fields
    {
        // Same number and type as on Bank Acc. Reconciliation Line, so TransferFields carries it.
        field(50220; "Bank Batch Ref."; Code[35])
        {
            Caption = 'Bank Batch Ref.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50220 "Bank Batch Ref. Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank Acc. Reconciliation Post", 'OnPostPaymentApplicationsOnAfterInitGenJnlLine', '', false, false)]
    local procedure CopyToJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        // IsHandled stays false: the standard code still applies and posts the line.
        GenJournalLine."Bank Batch Ref." := BankAccReconciliationLine."Bank Batch Ref.";
    end;
}
