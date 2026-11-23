// Demonstration only; independently authored, not copied from BaseApp.
// The framework commits, runs Send in its own error scope, logs HTTP and sets the status.
enumextension 50110 "Contoso E-Doc. Integration" extends "Service Integration"
{
    value(50110; "Contoso Network")
    {
        Caption = 'Contoso Network';
        Implementation = IDocumentSender = "Contoso E-Doc. Connector",
                         IDocumentReceiver = "Contoso E-Doc. Connector";
    }
}

codeunit 50110 "Contoso E-Doc. Connector" implements IDocumentSender, IDocumentReceiver
{
    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        TempBlob: Codeunit "Temp Blob";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
    begin
        TempBlob := SendContext.GetTempBlob();
        Request.Method := 'POST';
        Request.SetRequestUri('https://contoso.example/api/documents');
        Request.Content := TempBlob.AsHttpContent('application/xml');
        if not Client.Send(Request, Response) then
            Error('The Contoso network could not be reached.');

        // Stored on the context so the framework writes the integration log.
        SendContext.Http().SetHttpRequestMessage(Request);
        SendContext.Http().SetHttpResponseMessage(Response);

        // Without an error the framework reports Sent.
        if not Response.IsSuccessStatusCode() then
            Error('The Contoso network rejected the document: %1 %2', Response.HttpStatusCode(), Response.ReasonPhrase());
    end;

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    begin
        // Add one Temp Blob of metadata (for example a document id) per available document.
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    begin
        // Write the document into ReceiveContext.GetTempBlob(), then call
        // ReceiveContext.SetName and ReceiveContext.SetFileFormat.
    end;
}
