// Demonstration only; independently authored, not copied from BaseApp.
// "Price Import Line" (50130) has key ("Batch Name" Code[10], "Line No." Integer) and fields
// "Data Exch. Entry No." Integer, "Item No." Code[20], "Unit Price" Decimal, "Starting Date" Date.
// The data exchange definition PRICE-CSV (type Generic Import, XMLport 1220) maps the file columns to it,
// with this codeunit as the Mapping Codeunit of its Data Exch. Mapping.
codeunit 50130 "Map Price Import"
{
    TableNo = "Price Import Line";

    trigger OnRun()
    var
        DataExch: Record "Data Exch.";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        // Rec is the temporary template: key fields set, "Line No." filled per file line.
        DataExch.Get(Rec."Data Exch. Entry No.");
        RecRef.GetTable(Rec);
        ProcessDataExch.ProcessAllLinesColumnMapping(DataExch, RecRef);
    end;
}

codeunit 50131 "Import Price File"
{
    procedure ImportFile(BatchName: Code[10])
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExch: Record "Data Exch.";
        TempPriceImportLine: Record "Price Import Line" temporary;
    begin
        DataExchDef.Get('PRICE-CSV');
        if not DataExch.ImportToDataExch(DataExchDef) then
            exit;

        TempPriceImportLine."Batch Name" := BatchName;
        TempPriceImportLine."Data Exch. Entry No." := DataExch."Entry No.";
        TempPriceImportLine.Insert();

        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchMapping.SetRange("Table ID", Database::"Price Import Line");
        DataExchMapping.FindFirst();
        DataExchMapping.TestField("Mapping Codeunit");
        Codeunit.Run(DataExchMapping."Mapping Codeunit", TempPriceImportLine);

        InsertRealLines(TempPriceImportLine);
    end;

    local procedure InsertRealLines(var TempPriceImportLine: Record "Price Import Line" temporary)
    var
        PriceImportLine: Record "Price Import Line";
    begin
        TempPriceImportLine.SetFilter("Item No.", '<>%1', '');
        if TempPriceImportLine.FindSet() then
            repeat
                PriceImportLine := TempPriceImportLine;
                PriceImportLine.Insert(true); // OnInsert runs here, not inside Process Data Exch.
            until TempPriceImportLine.Next() = 0;
    end;
}
