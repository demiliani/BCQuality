// Demonstration only; independently authored, not copied from BaseApp.
// Create runs after the posting commit, so this error cannot stop posting.
// The subscriber assumes an E-Document already exists after every posting.
codeunit 50130 "Contoso E-Doc. Format" implements "E-Document"
{
    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    begin
    end;

    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SourceDocumentHeader.SetTable(SalesInvoiceHeader);
        SalesInvoiceHeader.TestField("Your Reference"); // expected to block posting; it does not
    end;

    procedure CreateBatch(EDocumentService: Record "E-Document Service"; var EDocuments: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure RequireEDocument(SalesInvHdrNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EDocument: Record "E-Document";
    begin
        if not SalesInvoiceHeader.Get(SalesInvHdrNo) then
            exit;
        EDocument.SetRange("Document Record ID", SalesInvoiceHeader.RecordId());
        if EDocument.IsEmpty() then
            Error('No e-document was created for invoice %1.', SalesInvHdrNo);
    end;
}
