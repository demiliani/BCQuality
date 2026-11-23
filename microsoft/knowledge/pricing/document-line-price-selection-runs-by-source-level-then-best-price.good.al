// Demonstration only; independently authored, not copied from BaseApp.
// Prices agreed with a parent customer apply to its subsidiaries and compete on price
// with the customer's own prices, so the source is added explicitly at level 0.
tableextension 50100 "Customer Price Parent" extends Customer
{
    fields
    {
        field(50100; "Price Parent Customer No."; Code[20])
        {
            Caption = 'Price Parent Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer;
        }
    }
}

codeunit 50100 "Parent Customer Price Source"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Line - Price", 'OnAfterAddSources', '', false, false)]
    local procedure AddParentCustomer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    var
        Customer: Record Customer;
    begin
        // Sales Line - Price also runs with the Purchase price type for resource unit costs.
        if PriceType <> PriceType::Sale then
            exit;
        Customer.SetLoadFields("Price Parent Customer No.");
        if not Customer.Get(SalesHeader."Bill-to Customer No.") then
            exit;
        if Customer."Price Parent Customer No." = '' then
            exit;
        // Level 0 is where BaseApp adds the customer sources; project sources sit on higher levels.
        PriceSourceList.SetLevel(0);
        PriceSourceList.Add("Price Source Type"::Customer, Customer."Price Parent Customer No.");
    end;
}
