// Demonstration only; independently authored, not copied from BaseApp.
// The field lives on Production Order only; the status change copies it with the whole record.
tableextension 50170 "Prod. Order Customer Batch" extends "Production Order"
{
    fields
    {
        field(50170; "Customer Batch Ref."; Code[30])
        {
            Caption = 'Customer Batch Ref.';
            DataClassification = CustomerContent;
        }
        field(50171; "Released By"; Code[50])
        {
            Caption = 'Released By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }
}

codeunit 50170 "Prod. Order Status Handling"
{
    // Only a value that must change with the status needs the copy event.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnCopyFromProdOrder', '', false, false)]
    local procedure SetReleasedBy(var ToProdOrder: Record "Production Order"; FromProdOrder: Record "Production Order")
    begin
        if ToProdOrder.Status = ToProdOrder.Status::Released then
            ToProdOrder."Released By" := CopyStr(UserId(), 1, MaxStrLen(ToProdOrder."Released By"));
    end;
}
