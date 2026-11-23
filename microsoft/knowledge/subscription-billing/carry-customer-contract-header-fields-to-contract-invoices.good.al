// Demonstration only; independently authored, not copied from BaseApp.
// Same number and type on the contract and the sales header: TransferFields covers
// per-contract invoices. Mirror 50100 on "Sales Invoice Header" and "Sales Cr.Memo Header" too.
tableextension 50112 "PO Ref Contract" extends "Customer Subscription Contract"
{
    fields
    {
        field(50100; "Customer PO Reference"; Code[35])
        {
            Caption = 'Customer PO Reference';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50113 "PO Ref Sales Header" extends "Sales Header"
{
    fields
    {
        field(50100; "Customer PO Reference"; Code[35])
        {
            Caption = 'Customer PO Reference';
            DataClassification = CustomerContent;
        }
    }
}

codeunit 50111 "PO Ref Contract Invoices"
{
    // Collective invoices: no TransferFields runs. Chosen rule: take the opening contract's value.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Billing Documents", OnAfterCreateSalesHeaderForCustomerNo, '', false, false)]
    local procedure SetOnCollectiveInvoice(var SalesHeader: Record "Sales Header"; ContractNo: Code[20])
    var
        CustomerContract: Record "Customer Subscription Contract";
    begin
        CustomerContract.SetLoadFields("Customer PO Reference");
        if CustomerContract.Get(ContractNo) then
            SalesHeader."Customer PO Reference" := CustomerContract."Customer PO Reference";
        // no Modify: the app calls SalesHeader.Modify(false) right after this event
    end;
}
