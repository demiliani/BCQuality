using Microsoft.Manufacturing.Document;

codeunit 50200 "Shop Floor Consumption Lines"
{
    procedure FilterComponentsToStage(var ProdOrderComponent: Record "Prod. Order Component")
    begin
        ProdOrderComponent.SetFilter("Remaining Quantity", '>0');
    end;
}
