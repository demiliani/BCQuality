// Demonstration only; independently authored, not copied from BaseApp.
// Every service ledger insert path carries the value; contract invoices take it from the contract.
// Assumes field 50330 "Region Code" Code[10] on "Service Header", "Service Contract Header"
// and "Service Ledger Entry".
codeunit 50330 "Service Region Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServLedgEntries-Post", 'OnBeforeServLedgerEntryInsert', '', false, false)]
    local procedure OnUsage(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header")
    begin
        ServiceLedgerEntry."Region Code" := ServiceHeader."Region Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServLedgEntries-Post", 'OnBeforeServLedgerEntrySaleInsert', '', false, false)]
    local procedure OnSale(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header")
    begin
        ServiceLedgerEntry."Region Code" := ServiceHeader."Region Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServLedgEntries-Post", 'OnInsertServLedgEntryCrMemoOnBeforeServLedgEntryInsert', '', false, false)]
    local procedure OnCreditMemo(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header")
    begin
        ServiceLedgerEntry."Region Code" := ServiceHeader."Region Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServLedgEntries-Post", 'OnInsertServLedgerEntryCrMUsageOnBeforeServLedgEntryInsert', '', false, false)]
    local procedure OnCreditMemoUsage(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header")
    begin
        ServiceLedgerEntry."Region Code" := ServiceHeader."Region Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnBeforeServHeaderModify', '', false, false)]
    local procedure OnContractInvoice(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceHeader."Region Code" := ServiceContractHeader."Region Code";
    end;
}
