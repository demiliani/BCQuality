// Demonstration only; independently authored, not copied from BaseApp.
// Different field numbers, and only the per-contract event is handled.
// Collective invoices (Documents per customer) never get the value.
tableextension 50113 "PO Ref Sales Header" extends "Sales Header"
{
    fields
    {
        field(50150; "Customer PO Reference"; Code[35])
        {
            Caption = 'Customer PO Reference';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50111 "PO Ref Contract Invoices"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Billing Documents", OnAfterCreateSalesHeaderFromContract, '', false, false)]
    local procedure SetFromContract(CustomerContract: Record "Customer Subscription Contract"; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Customer PO Reference" := CustomerContract."Customer PO Reference";
    end;
}
