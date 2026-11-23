// Demonstration only; independently authored, not copied from BaseApp.
// Expects matching field numbers to carry the value, then patches the ledger from the item journal line.
codeunit 50110 "Service Item Asset Class"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure ItemJnlLineToItemLedger(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
    begin
        if ItemJournalLine."Order Type" <> ItemJournalLine."Order Type"::Service then
            exit;
        // Guesses the first serviced item of the order; wrong when the order services several items.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ItemJournalLine."Order No.");
        if ServiceItemLine.FindFirst() then
            if ServiceItem.Get(ServiceItemLine."Service Item No.") then
                NewItemLedgEntry."Asset Class" := ServiceItem."Asset Class";
    end;
}
