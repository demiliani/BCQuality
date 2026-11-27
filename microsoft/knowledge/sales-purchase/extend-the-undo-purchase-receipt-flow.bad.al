// Demonstration only; both fields are extensions of Purch. Rcpt. Line.
using Microsoft.Purchases.History;

codeunit 50197 "Receipt Correction Export"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnBeforeNewPurchRcptLineInsert', '', false, false)]
    local procedure SetCorrectionExportFields(var NewPurchRcptLine: Record "Purch. Rcpt. Line"; OldPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        NewPurchRcptLine."Partner Receipt Reference" := OldPurchRcptLine."Partner Receipt Reference";
        NewPurchRcptLine."Export Message ID" := OldPurchRcptLine."Export Message ID";
    end;
}
