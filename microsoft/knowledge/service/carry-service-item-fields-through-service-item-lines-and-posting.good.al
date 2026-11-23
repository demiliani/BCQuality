// Demonstration only; independently authored, not copied from BaseApp.
// Service Item -> Service Item Line -> Service Line -> Item Journal Line -> Item Ledger Entry.
// Assumes field 50110 "Asset Class" Code[20] on Service Item, Service Item Line, Service Line,
// Item Journal Line and Item Ledger Entry.
codeunit 50110 "Service Item Asset Class"
{
    [EventSubscriber(ObjectType::Table, Database::"Service Item Line", 'OnAfterSetServItemInfo', '', false, false)]
    local procedure ServiceItemToItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceItem: Record "Service Item")
    begin
        ServiceItemLine."Asset Class" := ServiceItem."Asset Class";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnValidateServiceItemLineNoOnBeforeValidateContractNo', '', false, false)]
    local procedure ItemLineToServiceLine(var ServiceLine: Record "Service Line"; ServItemLine: Record "Service Item Line")
    begin
        ServiceLine."Asset Class" := ServItemLine."Asset Class";
    end;

    // Invoices and credit memos have no service item line step.
    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'Service Item No.', false, false)]
    local procedure ServiceItemToInvoiceLine(var Rec: Record "Service Line")
    var
        ServiceItem: Record "Service Item";
    begin
        if not (Rec."Document Type" in [Rec."Document Type"::Invoice, Rec."Document Type"::"Credit Memo"]) then
            exit;
        if Rec."Service Item No." = '' then
            Rec."Asset Class" := ''
        else
            if ServiceItem.Get(Rec."Service Item No.") then
                Rec."Asset Class" := ServiceItem."Asset Class";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterCopyToItemJnlLine', '', false, false)]
    local procedure ServiceLineToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ServiceLine: Record "Service Line")
    begin
        ItemJournalLine."Asset Class" := ServiceLine."Asset Class";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure ItemJnlLineToItemLedger(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        NewItemLedgEntry."Asset Class" := ItemJournalLine."Asset Class";
    end;
}
