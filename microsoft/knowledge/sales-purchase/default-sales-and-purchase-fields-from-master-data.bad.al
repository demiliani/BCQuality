// Demonstration only; independently authored, not copied from BaseApp.
// Defaults copied on the page, and a payment default taken from the sell-to customer.
pageextension 50170 "Sales Order Defaults" extends "Sales Order"
{
    layout
    {
        modify("Sell-to Customer No.")
        {
            trigger OnAfterValidate()
            var
                Customer: Record Customer;
            begin
                // Documents created from code, APIs or Copy Document never run this.
                if Customer.Get(Rec."Sell-to Customer No.") then begin
                    Rec."Delivery Window" := Customer."Delivery Window";
                    // Wrong party: collection data belongs to the bill-to customer.
                    Rec."Collection Group" := Customer."Collection Group";
                end;
            end;
        }
    }
}
