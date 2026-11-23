// Demonstration only; independently authored, not copied from BaseApp.
// Adds a value to Payment Export Data so a data exchange definition can map it to a file column.
// Assumes a Gen. Journal Line table extension with field 50200 "Payment Priority Code" Code[10].
tableextension 50210 "Pmt. Export Data Priority" extends "Payment Export Data"
{
    fields
    {
        field(50200; "Payment Priority Code"; Code[10])
        {
            Caption = 'Payment Priority Code';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50210 "Payment Priority Export"
{
    // The publisher declares the event with this exact (misspelled) name.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exp. Pre-Mapping Gen. Jnl.", 'OnBeforeInsertPaymentExoprtData', '', false, false)]
    local procedure SetPriority(var PaymentExportData: Record "Payment Export Data"; GenJournalLine: Record "Gen. Journal Line")
    begin
        PaymentExportData."Payment Priority Code" := GenJournalLine."Payment Priority Code";
    end;
}
