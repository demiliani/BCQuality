// Demonstration only; independently authored, not copied from BaseApp.
// Vendor Ledger Entry -> Vendor Payment Buffer -> Gen. Journal Line during Suggest Vendor Payments.
// Assumes a Vendor Ledger Entry table extension with field 50200 "Payment Priority Code" Code[10],
// a value that is constant per vendor, so summarized payment lines stay meaningful.
tableextension 50200 "Vend. Pmt. Buffer Priority" extends "Vendor Payment Buffer"
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

tableextension 50201 "Gen. Jnl. Line Pmt. Priority" extends "Gen. Journal Line"
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

codeunit 50200 "Payment Priority Suggest"
{
    [EventSubscriber(ObjectType::Table, Database::"Vendor Payment Buffer", 'OnAfterCopyFieldsFromVendorLedgerEntry', '', false, false)]
    local procedure CopyToBuffer(VendorLedgerEntrySource: Record "Vendor Ledger Entry"; var VendorPaymentBufferTarget: Record "Vendor Payment Buffer")
    begin
        VendorPaymentBufferTarget."Payment Priority Code" := VendorLedgerEntrySource."Payment Priority Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Payment Buffer", 'OnAfterCopyFieldsToGenJournalLine', '', false, false)]
    local procedure CopyToJournalLine(VendorPaymentBufferSource: Record "Vendor Payment Buffer"; var GenJournalLineTarget: Record "Gen. Journal Line")
    begin
        GenJournalLineTarget."Payment Priority Code" := VendorPaymentBufferSource."Payment Priority Code";
    end;
}
