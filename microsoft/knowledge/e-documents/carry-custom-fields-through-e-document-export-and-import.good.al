// Demonstration only; independently authored, not copied from BaseApp.
// Export: read the custom field from the mapped record ref and edit the PEPPOL blob.
// Import (V2): fill a staging extension field in an own reader, then copy it after the finish step.
// Assumes field 50120 "Contoso Project Code" on Sales Invoice Header, carried there from Sales Header.
codeunit 50120 "Contoso E-Doc. Project Code"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EDoc PEPPOL BIS 3.0", 'OnAfterCreatePEPPOLXMLDocument', '', false, false)]
    local procedure AddProjectCodeToPeppol(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Document: XmlDocument;
        Root: XmlElement;
        InStr: InStream;
        OutStr: OutStream;
    begin
        if SourceDocumentHeader.Number() <> Database::"Sales Invoice Header" then
            exit;
        SourceDocumentHeader.SetTable(SalesInvoiceHeader);
        if SalesInvoiceHeader."Contoso Project Code" = '' then
            exit;

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStr, Document);
        Document.GetRoot(Root);
        // Place the element where the UBL schema expects it; appended here for brevity.
        Root.Add(XmlElement.Create('AccountingCost', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', SalesInvoiceHeader."Contoso Project Code"));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        Document.WriteTo(OutStr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", 'OnAfterProcessIncomingEDocument', '', false, false)]
    local procedure CopyProjectCodeToPurchaseHeader(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"; StartState: Enum "Import E-Doc. Proc. Status"; DesiredEndState: Enum "Import E-Doc. Proc. Status")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        if DesiredEndState <> DesiredEndState::Processed then
            exit;
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        if not PurchaseHeader.FindFirst() then
            exit;
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if EDocumentPurchaseHeader."Contoso Project Code" = '' then
            exit;
        PurchaseHeader.Validate("Contoso Project Code", EDocumentPurchaseHeader."Contoso Project Code");
        PurchaseHeader.Modify(true);
    end;
}

tableextension 50120 "Contoso E-Doc. Purch. Header" extends "E-Document Purchase Header"
{
    fields
    {
        field(50120; "Contoso Project Code"; Code[20])
        {
            Caption = 'Project Code';
            DataClassification = CustomerContent;
        }
    }
}

enumextension 50120 "Contoso Read into Draft" extends "E-Doc. Read into Draft"
{
    value(50120; "Contoso XML")
    {
        Caption = 'Contoso XML';
        Implementation = IStructuredFormatReader = "Contoso E-Doc. Reader";
    }
}

codeunit 50121 "Contoso E-Doc. Reader" implements IStructuredFormatReader
{
    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        EDocumentPurchaseHeader.InsertForEDocument(EDocument);
        // Parse the blob into the standard staging fields and lines here.
        EDocumentPurchaseHeader."Contoso Project Code" := 'PRJ-001'; // value read from the blob
        EDocumentPurchaseHeader.Modify();
        exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    begin
    end;
}
