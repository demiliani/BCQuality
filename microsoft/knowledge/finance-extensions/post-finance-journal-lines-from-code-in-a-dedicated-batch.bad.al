// Demonstration only; independently authored, not copied from BaseApp.
// Writes into a shared batch with a hard-coded document number and lets batch posting commit.
codeunit 50170 "Post Service Fee"
{
    procedure PostFee(Amount: Decimal; Description: Text[100])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := 'GENERAL';
        GenJournalLine."Journal Batch Name" := 'DEFAULT';
        GenJournalLine."Line No." := 99999;
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Document No." := 'FEE-001';
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := '6100';
        GenJournalLine."Bal. Account No." := '2910';
        GenJournalLine.Amount := Amount;
        GenJournalLine.Description := Description;
        GenJournalLine.Insert();

        // Posts every line in GENERAL/DEFAULT, including lines users entered, and commits.
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJournalLine);
    end;
}
