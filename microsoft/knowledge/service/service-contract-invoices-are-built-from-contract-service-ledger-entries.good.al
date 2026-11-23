// Demonstration only; independently authored, not copied from BaseApp.
// Contract line -> contract Service Ledger Entry (at invoice creation) -> Service Line -> posted invoice line.
// Assumes field 50100 "Billing Category" Code[20] on Service Contract Line and on
// Service Invoice Line (same number and type, for TransferFields at posting).
tableextension 50100 "Serv. Ledg. Billing Category" extends "Service Ledger Entry"
{
    fields
    {
        field(50100; "Billing Category"; Code[20])
        {
            Caption = 'Billing Category';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

tableextension 50101 "Serv. Line Billing Category" extends "Service Line"
{
    fields
    {
        field(50100; "Billing Category"; Code[20])
        {
            Caption = 'Billing Category';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50100 "Contract Billing Category"
{
    // Not prepaid: one entry per contract line.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnCreateServiceLedgerEntryOnBeforeServLedgEntryInsert', '', false, false)]
    local procedure OnNonPrepaidEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceContractLine: Record "Service Contract Line")
    begin
        ServiceLedgerEntry."Billing Category" := ServiceContractLine."Billing Category";
    end;

    // Prepaid: one entry per month. Read the contract line, not the header.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnInsertMultipleServLedgEntriesOnBeforeServLedgEntryInsert', '', false, false)]
    local procedure OnPrepaidEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceContractLine: Record "Service Contract Line")
    begin
        ServiceLedgerEntry."Billing Category" := ServiceContractLine."Billing Category";
    end;

    // Prepaid partial period.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnPostPartialServLedgEntryOnBeforeServLedgEntryInsert', '', false, false)]
    local procedure OnPartialEntry(var ServLedgEntry: Record "Service Ledger Entry"; ServContractLine: Record "Service Contract Line")
    begin
        ServLedgEntry."Billing Category" := ServContractLine."Billing Category";
    end;

    // The entry being converted is ServiceLedgerEntryParm, not ServiceLedgerEntry.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnServLedgEntryToServiceLineOnBeforeServLineInsert', '', false, false)]
    local procedure OnContractServiceLine(var ServiceLine: Record "Service Line"; ServiceLedgerEntryParm: Record "Service Ledger Entry")
    begin
        ServiceLine."Billing Category" := ServiceLedgerEntryParm."Billing Category";
    end;
}
