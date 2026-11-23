// Demonstration only; independently authored, not copied from BaseApp.
// The connector inserts the Sales Header before it sets "Shpfy Order Id",
// so this lookup never finds the attribute and the field stays blank.
codeunit 50100 "Shopify Order Extra Values"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterInsertEvent, '', false, false)]
    local procedure CopyGiftMessage(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        OrderAttribute: Record "Shpfy Order Attribute";
    begin
        if Rec."Shpfy Order Id" = 0 then
            exit; // always true here: the id is assigned after the insert
        if OrderAttribute.Get(Rec."Shpfy Order Id", 'gift-message') then begin
            Rec."Gift Message" := CopyStr(OrderAttribute."Attribute Value", 1, MaxStrLen(Rec."Gift Message"));
            Rec.Modify();
        end;
    end;
}
