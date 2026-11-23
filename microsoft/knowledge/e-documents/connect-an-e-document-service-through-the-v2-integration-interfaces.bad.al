// Demonstration only; independently authored, not copied from BaseApp.
// Swallows the failure, so the framework reports Sent, and re-implements log, status and retry.
codeunit 50110 "Contoso E-Doc. Connector" implements IDocumentSender, IDocumentReceiver
{
    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        ContosoSendLog: Record "Contoso Send Log";
        ContosoRetryQueue: Record "Contoso Retry Queue";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
    begin
        Request.Method := 'POST';
        Request.SetRequestUri('https://contoso.example/api/documents');
        Request.Content := SendContext.GetTempBlob().AsHttpContent('application/xml');
        Client.Send(Request, Response);

        ContosoSendLog.Init();
        ContosoSendLog."E-Document Entry No." := EDocument."Entry No";
        ContosoSendLog."Status Code" := Response.HttpStatusCode();
        ContosoSendLog.Insert();

        if not Response.IsSuccessStatusCode() then begin
            ContosoRetryQueue."E-Document Entry No." := EDocument."Entry No";
            ContosoRetryQueue.Insert();
        end;
        Commit();
    end;

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    begin
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    begin
    end;
}
