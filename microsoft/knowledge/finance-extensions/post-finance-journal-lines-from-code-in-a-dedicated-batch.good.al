// Demonstration only; independently authored, not copied from BaseApp.
// Uses the feature's own template and batch from setup, numbers from the batch series, validated accounts.
// Assumes a singleton setup table "Fee Setup" with "Journal Template Name", "Journal Batch Name",
// "Fee G/L Account No." and "Balancing G/L Account No.".
codeunit 50170 "Post Service Fee"
{
    procedure PostFee(Amount: Decimal; Description: Text[100])
    var
        FeeSetup: Record "Fee Setup";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
    begin
        FeeSetup.Get();
        FeeSetup.TestField("Journal Template Name");
        FeeSetup.TestField("Journal Batch Name");
        FeeSetup.TestField("Fee G/L Account No.");
        FeeSetup.TestField("Balancing G/L Account No.");

        GenJournalLine.SetRange("Journal Template Name", FeeSetup."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FeeSetup."Journal Batch Name");
        if not GenJournalLine.IsEmpty() then
            Error(BatchNotEmptyErr, FeeSetup."Journal Batch Name");

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := FeeSetup."Journal Template Name";
        GenJournalLine."Journal Batch Name" := FeeSetup."Journal Batch Name";
        GenJournalLine."Line No." := 10000;
        GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, true);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", FeeSetup."Fee G/L Account No.");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", FeeSetup."Balancing G/L Account No.");
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Description := Description;
        GenJournalLine.Insert(true);

        GenJnlPostBatch.SetSuppressCommit(true);
        GenJnlPostBatch.Run(GenJournalLine);
    end;

    var
        BatchNotEmptyErr: Label 'The journal batch %1 reserved for service fees must be empty before posting.', Comment = '%1 = journal batch name';
}
