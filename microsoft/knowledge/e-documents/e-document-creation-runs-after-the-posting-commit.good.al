// Demonstration only; independently authored, not copied from BaseApp.
// Blocking rules live in Check, which Core runs on release and inside posting.
// Create only builds the file and logs problems on the E-Document.
codeunit 50130 "Contoso E-Doc. Format" implements "E-Document"
{
    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        SalesHeader: Record "Sales Header";
    begin
        if SourceDocumentHeader.Number() <> Database::"Sales Header" then
            exit;
        SourceDocumentHeader.SetTable(SalesHeader);
        case EDocumentProcessingPhase of
            EDocumentProcessingPhase::Release,
            EDocumentProcessingPhase::Post:
                SalesHeader.TestField("Your Reference");
        end;
    end;

    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        OutStr: OutStream;
    begin
        SourceDocumentHeader.SetTable(SalesInvoiceHeader);
        if SalesInvoiceHeader."Your Reference" = '' then begin
            // Posting is already committed; record the problem on the E-Document instead.
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Your Reference is missing.');
            exit;
        end;
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('<Invoice><Ref>' + SalesInvoiceHeader."Your Reference" + '</Ref></Invoice>');
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
}
