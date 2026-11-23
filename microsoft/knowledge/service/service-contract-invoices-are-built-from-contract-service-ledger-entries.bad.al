// Demonstration only; independently authored, not copied from BaseApp.
// Treats a contract invoice like an order invoice.
codeunit 50100 "Contract Billing Category"
{
    // Never raised for contract lines: posting closes the existing contract entries and exits.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ServLedgEntries-Post", 'OnBeforeServLedgerEntrySaleInsert', '', false, false)]
    local procedure OnSaleEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceLine: Record "Service Line")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        if ServiceLine."Contract No." = '' then
            exit;
        ServiceContractLine.SetRange("Contract No.", ServiceLine."Contract No.");
        ServiceContractLine.SetRange("Service Item No.", ServiceLine."Service Item No.");
        if ServiceContractLine.FindFirst() then
            ServiceLedgerEntry."Billing Category" := ServiceContractLine."Billing Category";
    end;

    // Reads the global entry passed as ServiceLedgerEntry: every line gets the last entry's value.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnServLedgEntryToServiceLineOnBeforeServLineInsert', '', false, false)]
    local procedure OnContractServiceLine(var ServiceLine: Record "Service Line"; ServiceLedgerEntry: Record "Service Ledger Entry")
    begin
        ServiceLine."Billing Category" := ServiceLedgerEntry."Billing Category";
    end;
}
