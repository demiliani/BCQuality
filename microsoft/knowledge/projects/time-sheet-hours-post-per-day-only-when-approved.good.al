// Demonstration only; independently authored, not copied from BaseApp.
// One project journal line per approved, unposted time sheet day.
codeunit 50195 "Time Sheet Day To Job Jnl."
{
    procedure CreateJournalLines(TimeSheetLine: Record "Time Sheet Line"; ResourceNo: Code[20]; TemplateName: Code[10]; BatchName: Code[10]; var LineNo: Integer)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        JobJournalLine: Record "Job Journal Line";
    begin
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);
        TimeSheetLine.TestField(Posted, false);

        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        TimeSheetDetail.SetRange(Posted, false);
        TimeSheetDetail.SetFilter(Quantity, '<>0');
        if TimeSheetDetail.FindSet() then
            repeat
                if TimeSheetDetail.GetMaxQtyToPost() <> 0 then begin
                    LineNo += 10000;
                    JobJournalLine.Init();
                    JobJournalLine."Journal Template Name" := TemplateName;
                    JobJournalLine."Journal Batch Name" := BatchName;
                    JobJournalLine."Line No." := LineNo;
                    // Link to the day first: validating the resource checks Use Time Sheet.
                    JobJournalLine."Time Sheet No." := TimeSheetDetail."Time Sheet No.";
                    JobJournalLine."Time Sheet Line No." := TimeSheetDetail."Time Sheet Line No.";
                    JobJournalLine."Time Sheet Date" := TimeSheetDetail.Date;
                    JobJournalLine.Validate("Job No.", TimeSheetDetail."Job No.");
                    if TimeSheetDetail."Job Task No." <> '' then
                        JobJournalLine.Validate("Job Task No.", TimeSheetDetail."Job Task No.");
                    JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
                    JobJournalLine.Validate("No.", ResourceNo);
                    JobJournalLine.Validate("Posting Date", TimeSheetDetail.Date);
                    JobJournalLine.Validate(Quantity, TimeSheetDetail.GetMaxQtyToPost());
                    JobJournalLine.Insert(true);
                end;
            until TimeSheetDetail.Next() = 0;
    end;
}
