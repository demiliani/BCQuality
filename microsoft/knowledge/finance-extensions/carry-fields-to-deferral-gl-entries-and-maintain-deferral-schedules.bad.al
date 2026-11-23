// Demonstration only; independently authored, not copied from BaseApp.
// Reads final values too early and writes the deferral schedule by hand.
// Assumes field 50151 "Recognition Month" Code[7] on G/L Entry.
codeunit 50151 "Deferral Contract Fields Bad"
{
    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', false, false)]
    local procedure SetRecognitionMonth(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        // G/L Account No. is assigned by InitGLEntry after this event: the check reads a blank value.
        if GLEntry."G/L Account No." = '' then
            exit;
        // Posting Date is still the document date: every deferral period gets the same month.
        GLEntry."Recognition Month" := Format(GLEntry."Posting Date", 0, '<Year4>-<Month,2>');
    end;

    procedure SetContractSchedule(SalesLine: Record "Sales Line"; StartDate: Date; NoOfPeriods: Integer)
    var
        DeferralLine: Record "Deferral Line";
        i: Integer;
    begin
        // Rows written directly: the next Validate of Quantity or Unit Price, or a header Posting Date change,
        // rebuilds the schedule, and a total that differs from "Amount to Defer" stops posting.
        for i := 1 to NoOfPeriods do begin
            DeferralLine.Init();
            DeferralLine."Deferral Doc. Type" := Enum::"Deferral Document Type"::Sales;
            DeferralLine."Document Type" := SalesLine."Document Type".AsInteger();
            DeferralLine."Document No." := SalesLine."Document No.";
            DeferralLine."Line No." := SalesLine."Line No.";
            DeferralLine."Posting Date" := CalcDate(StrSubstNo('<%1M>', i - 1), StartDate);
            DeferralLine.Amount := Round(SalesLine.Amount / NoOfPeriods);
            DeferralLine.Insert();
        end;
    end;
}
