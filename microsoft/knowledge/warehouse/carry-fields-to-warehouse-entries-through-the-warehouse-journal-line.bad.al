// Demonstration only; independently authored, not copied from BaseApp.
// Patches warehouse entries after posting instead of carrying the value through the journal line.
codeunit 50190 "Batch Ref. Whse. Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure PatchWhseEntries(var SalesHeader: Record "Sales Header"; SalesShptHdrNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                WarehouseEntry.SetRange("Source Type", Database::"Sales Line");
                WarehouseEntry.SetRange("Source No.", SalesLine."Document No.");
                WarehouseEntry.SetRange("Source Line No.", SalesLine."Line No.");
                WarehouseEntry.ModifyAll("Customer Batch Ref.", SalesLine."Customer Batch Ref.");
            until SalesLine.Next() = 0;
    end;
}
