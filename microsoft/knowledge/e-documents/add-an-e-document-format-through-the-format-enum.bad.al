// Demonstration only; independently authored, not copied from BaseApp.
// Builds the file beside the framework: no E-Document, no log, no mapping, no status, no send.
codeunit 50100 "Contoso Invoice XML Export"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure ExportAfterPosting(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ContosoExportFile: Record "Contoso Export File";
        OutStr: OutStream;
    begin
        if not SalesInvoiceHeader.Get(SalesInvHdrNo) then
            exit;
        ContosoExportFile.Init();
        ContosoExportFile."Document No." := SalesInvoiceHeader."No.";
        ContosoExportFile.Content.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('<Invoice><No>' + SalesInvoiceHeader."No." + '</No></Invoice>');
        ContosoExportFile.Insert();
        Commit();
    end;
}
