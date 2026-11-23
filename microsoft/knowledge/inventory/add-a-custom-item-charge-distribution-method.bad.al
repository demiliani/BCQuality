// Demonstration only; independently authored, not copied from BaseApp.
// Takes over every suggestion: the standard methods disappear and the user is never asked.
codeunit 50175 "Freight Factor Item Charge"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Charge Assgnt. (Purch.)", 'OnBeforeSuggestAssgnt', '', false, false)]
    local procedure ReplaceSuggestion(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseLine."Line No.");
        ItemChargeAssignmentPurch.ModifyAll("Qty. to Assign", 1);
        IsHandled := true;
    end;
}
