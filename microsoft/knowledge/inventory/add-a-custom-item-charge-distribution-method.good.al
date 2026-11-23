// Demonstration only; independently authored, not copied from BaseApp.
// Adds "By Freight Factor" to the purchase item charge suggestion menu and handles only that caption.
// Assumes an Item table extension with a Decimal field "Freight Factor".
codeunit 50175 "Freight Factor Item Charge"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Charge Assgnt. (Purch.)", 'OnBeforeShowSuggestItemChargeAssignStrMenu', '', false, false)]
    local procedure AddMenuOption(var SuggestItemChargeMenuTxt: Text)
    begin
        if SuggestItemChargeMenuTxt <> '' then
            SuggestItemChargeMenuTxt += ',' + ByFreightFactorTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Charge Assgnt. (Purch.)", 'OnAssignItemCharges', '', false, false)]
    local procedure AssignByFreightFactor(SelectionTxt: Text; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var ItemChargesAssigned: Boolean)
    var
        Item: Record Item;
        TotalFactor: Decimal;
    begin
        if SelectionTxt <> ByFreightFactorTxt then
            exit;

        if ItemChargeAssignmentPurch.FindSet() then
            repeat
                if Item.Get(ItemChargeAssignmentPurch."Item No.") then
                    TotalFactor += Item."Freight Factor";
            until ItemChargeAssignmentPurch.Next() = 0;
        if TotalFactor = 0 then
            exit;

        if ItemChargeAssignmentPurch.FindSet() then
            repeat
                if Item.Get(ItemChargeAssignmentPurch."Item No.") then begin
                    ItemChargeAssignmentPurch."Qty. to Assign" := Round(TotalQtyToAssign * Item."Freight Factor" / TotalFactor, 0.00001);
                    ItemChargeAssignmentPurch."Amount to Assign" :=
                      Round(TotalAmtToAssign * Item."Freight Factor" / TotalFactor, Currency."Amount Rounding Precision");
                    ItemChargeAssignmentPurch.Modify();
                end;
            until ItemChargeAssignmentPurch.Next() = 0;
        ItemChargesAssigned := true;
    end;

    var
        ByFreightFactorTxt: Label 'By Freight Factor';
}
