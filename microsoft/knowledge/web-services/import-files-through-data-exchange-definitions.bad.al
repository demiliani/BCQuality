// Demonstration only; independently authored, not copied from BaseApp.
// Hand-written CSV parser: separator, column order, date format and encoding are fixed in code.
codeunit 50131 "Import Price File"
{
    procedure ImportFile(BatchName: Code[10]; FileInStream: InStream)
    var
        PriceImportLine: Record "Price Import Line";
        Columns: List of [Text];
        LineText: Text;
        LineNo: Integer;
    begin
        FileInStream.ReadText(LineText); // assumes exactly one header line
        while not FileInStream.EOS() do begin
            FileInStream.ReadText(LineText);
            Columns := LineText.Split(';');
            LineNo += 10000;
            PriceImportLine.Init();
            PriceImportLine."Batch Name" := BatchName;
            PriceImportLine."Line No." := LineNo;
            PriceImportLine."Item No." := CopyStr(Columns.Get(1), 1, MaxStrLen(PriceImportLine."Item No."));
            Evaluate(PriceImportLine."Unit Price", Columns.Get(2));
            Evaluate(PriceImportLine."Starting Date", Columns.Get(3));
            PriceImportLine.Insert(true);
        end;
    end;
}
