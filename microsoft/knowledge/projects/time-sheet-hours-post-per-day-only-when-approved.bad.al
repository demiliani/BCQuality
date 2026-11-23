// Demonstration only; independently authored, not copied from BaseApp.
// Wrong: one journal line for the whole week, submitted lines included, resource validated first.
codeunit 50196 "Time Sheet Week To Job Jnl."
{
    procedure CreateJournalLine(TimeSheetLine: Record "Time Sheet Line"; ResourceNo: Code[20]; TemplateName: Code[10]; BatchName: Code[10]; LineNo: Integer)
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        if not (TimeSheetLine.Status in [TimeSheetLine.Status::Submitted, TimeSheetLine.Status::Approved]) then
            exit;
        TimeSheetLine.CalcFields("Total Quantity");

        JobJournalLine.Init();
        JobJournalLine."Journal Template Name" := TemplateName;
        JobJournalLine."Journal Batch Name" := BatchName;
        JobJournalLine."Line No." := LineNo;
        JobJournalLine.Validate("Job No.", TimeSheetLine."Job No.");
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo); // fails: resource uses time sheets, no Time Sheet No. yet
        JobJournalLine."Time Sheet No." := TimeSheetLine."Time Sheet No.";
        JobJournalLine."Time Sheet Line No." := TimeSheetLine."Line No.";
        // No Time Sheet Date: there is no single day for a week total.
        JobJournalLine.Validate(Quantity, TimeSheetLine."Total Quantity");
        JobJournalLine.Insert(true);
    end;
}
