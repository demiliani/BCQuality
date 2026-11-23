// Demonstration only; independently authored, not copied from BaseApp.
// Document value through the journal line; period value in the deferral insert events; schedule through Deferral Utilities.
// Assumes field 50150 "Contract No." Code[20] on Gen. Journal Line and G/L Entry (filled on the journal line
// through the Invoice Posting Buffer path), and field 50151 "Recognition Month" Code[7] on G/L Entry.
codeunit 50150 "Deferral Contract Fields"
{
    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', false, false)]
    local procedure CopyContractNo(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        // Runs for the main entry and for every deferral entry built from this journal line.
        // Account, amount and period posting date are not final here: copy only.
        GLEntry."Contract No." := GenJournalLine."Contract No.";
    end;

    // Sales and purchase documents: the period posting date is set before these events.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostDeferralPostBufferOnBeforeInsertGLEntryForGLAccount', '', false, false)]
    local procedure DocDeferralGLAccountSide(var GenJournalLine: Record "Gen. Journal Line"; DeferralPostingBuffer: Record "Deferral Posting Buffer"; var GLEntry: Record "G/L Entry")
    begin
        SetRecognitionMonth(GLEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostDeferralPostBufferOnBeforeInsertGLEntryForDeferralAccount', '', false, false)]
    local procedure DocDeferralDeferralAccountSide(var GenJournalLine: Record "Gen. Journal Line"; DeferralPostingBuffer: Record "Deferral Posting Buffer"; var GLEntry: Record "G/L Entry")
    begin
        SetRecognitionMonth(GLEntry);
    end;

    // General journal deferrals, one pair of entries per Deferral Line.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostDeferralOnBeforeInsertGLEntryDeferralLineForGLAccount', '', false, false)]
    local procedure JnlDeferralGLAccountSide(var GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry")
    begin
        SetRecognitionMonth(GLEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostDeferralOnBeforeInsertGLEntryDeferralLineForDeferralAccount', '', false, false)]
    local procedure JnlDeferralDeferralAccountSide(var GenJournalLine: Record "Gen. Journal Line"; DeferralLine: Record "Deferral Line"; var GLEntry: Record "G/L Entry")
    begin
        SetRecognitionMonth(GLEntry);
    end;

    local procedure SetRecognitionMonth(var GLEntry: Record "G/L Entry")
    begin
        GLEntry."Recognition Month" := Format(GLEntry."Posting Date", 0, '<Year4>-<Month,2>');
    end;

    // Creates a schedule with a contract-specific number of periods.
    procedure SetContractSchedule(var SalesLine: Record "Sales Line"; DeferralCode: Code[10]; StartDate: Date; NoOfPeriods: Integer)
    var
        SalesHeader: Record "Sales Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        SalesLine.Validate("Deferral Code", DeferralCode); // creates the template schedule
        SalesLine.Modify(true);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DeferralUtilities.CreateDeferralSchedule(
            DeferralCode, Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
            SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
            SalesLine.GetDeferralAmount(), Enum::"Deferral Calculation Method"::"Straight-Line",
            StartDate, NoOfPeriods, true, SalesLine.Description, false, SalesHeader."Currency Code");
        // Later amount changes go through Validate; UpdateDeferralAmounts keeps this method, period count and start date.
    end;
}
