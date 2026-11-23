// Demonstration only; independently authored, not copied from BaseApp.
// Requires a dependency on "E-Document Core" (Microsoft, id e1d97edc-c239-46b4-8d84-6368bdf67c8b).
// The framework calls the format; the format only validates and writes the blob.
enumextension 50100 "Contoso E-Doc. Format" extends "E-Document Format"
{
    value(50100; "Contoso XML")
    {
        Caption = 'Contoso XML';
        Implementation = "E-Document" = "Contoso E-Doc. Format";
    }
}

codeunit 50100 "Contoso E-Doc. Format" implements "E-Document"
{
    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        SalesHeader: Record "Sales Header";
    begin
        // Runs on release and inside posting: an error here stops posting.
        if SourceDocumentHeader.Number() <> Database::"Sales Header" then
            exit;
        SourceDocumentHeader.SetTable(SalesHeader);
        SalesHeader.TestField("External Document No.");
    end;

    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        OutStr: OutStream;
    begin
        if EDocument."Document Type" <> EDocument."Document Type"::"Sales Invoice" then begin
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, 'Contoso XML supports sales invoices only.');
            exit;
        end;
        // The record ref is a mapped temporary copy; read it, do not Get the posted invoice again.
        SourceDocumentHeader.SetTable(SalesInvoiceHeader);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('<Invoice><No>' + SalesInvoiceHeader."No." + '</No></Invoice>');
    end;

    procedure CreateBatch(EDocumentService: Record "E-Document Service"; var EDocuments: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin
        EDocumentErrorHelper.LogSimpleErrorMessage(EDocuments, 'Contoso XML does not support batch export.');
    end;

    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
    end;
}
