// Demonstration only; independently authored, not copied from BaseApp.
// Only the usage path is covered; sale and credit memo service ledger entries stay blank.
codeunit 50330 "Service Region Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServLedgEntries-Post", 'OnBeforeServLedgerEntryInsert', '', false, false)]
    local procedure OnUsage(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header")
    begin
        ServiceLedgerEntry."Region Code" := ServiceHeader."Region Code";
    end;
}
