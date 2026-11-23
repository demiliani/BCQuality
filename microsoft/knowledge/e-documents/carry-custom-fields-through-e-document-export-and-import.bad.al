// Demonstration only; independently authored, not copied from BaseApp.
// V1 purchase-creation event: never raised when the service uses the default V2 import process.
// The PEPPOL subscriber re-reads the posted invoice and ignores the mapped record ref.
codeunit 50120 "Contoso E-Doc. Project Code"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Document Create Purch. Doc.", 'OnCreateNewPurchHdrOnBeforeRecRefInsert', '', false, false)]
    local procedure SetProjectCode(var EDocument: Record "E-Document"; var TempDocumentHeader: RecordRef; var DocumentHeader: RecordRef)
    begin
        DocumentHeader.Field(50120).Value := TempDocumentHeader.Field(50120).Value;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EDoc PEPPOL BIS 3.0", 'OnAfterCreatePEPPOLXMLDocument', '', false, false)]
    local procedure AddProjectCodeToPeppol(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(EDocument."Document No.");
        // ...writes SalesInvoiceHeader."Contoso Project Code" into the XML.
    end;
}
