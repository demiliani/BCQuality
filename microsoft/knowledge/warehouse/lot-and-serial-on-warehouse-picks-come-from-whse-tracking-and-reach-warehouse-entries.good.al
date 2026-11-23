// Demonstration only; independently authored, not copied from BaseApp.
// Sets a scanned lot on a pick and reads lot stock per bin from warehouse data.
codeunit 50151 "Pick Lot Scanning"
{
    procedure AssignLotToPickLine(var TakeLine: Record "Warehouse Activity Line"; LotNo: Code[50])
    var
        PlaceLine: Record "Warehouse Activity Line";
    begin
        TakeLine.TestField("Activity Type", TakeLine."Activity Type"::Pick);
        TakeLine.TestField("Action Type", TakeLine."Action Type"::Take);
        if QtyInBinForLot(TakeLine, LotNo) < TakeLine."Qty. to Handle (Base)" then
            Error(LotNotInBinErr, LotNo, TakeLine."Bin Code");

        // Validation checks warehouse tracking and lots reserved for other demand.
        TakeLine.Validate("Lot No.", LotNo);
        TakeLine.Modify(true);

        // The place line produces its own warehouse entry, so it needs the same lot.
        PlaceLine.SetRange("Activity Type", TakeLine."Activity Type");
        PlaceLine.SetRange("No.", TakeLine."No.");
        PlaceLine.SetRange("Action Type", PlaceLine."Action Type"::Place);
        PlaceLine.SetRange("Whse. Document Type", TakeLine."Whse. Document Type");
        PlaceLine.SetRange("Whse. Document No.", TakeLine."Whse. Document No.");
        PlaceLine.SetRange("Whse. Document Line No.", TakeLine."Whse. Document Line No.");
        PlaceLine.SetRange("Breakbulk No.", TakeLine."Breakbulk No.");
        PlaceLine.SetRange("Qty. (Base)", TakeLine."Qty. (Base)");
        PlaceLine.SetRange("Lot No.", '');
        if PlaceLine.FindFirst() then begin
            PlaceLine.Validate("Lot No.", LotNo);
            PlaceLine.Modify(true);
        end;
        // Registering the pick writes the lot to the warehouse entries and back to the source line.
    end;

    local procedure QtyInBinForLot(TakeLine: Record "Warehouse Activity Line"; LotNo: Code[50]): Decimal
    var
        BinContent: Record "Bin Content";
    begin
        if not BinContent.Get(
            TakeLine."Location Code", TakeLine."Bin Code", TakeLine."Item No.", TakeLine."Variant Code", TakeLine."Unit of Measure Code")
        then
            exit(0);
        BinContent.SetRange("Lot No. Filter", LotNo);
        BinContent.CalcFields("Quantity (Base)");
        exit(BinContent."Quantity (Base)");
    end;

    var
        LotNotInBinErr: Label 'Lot %1 does not have enough quantity in bin %2.', Comment = '%1 = lot number, %2 = bin code';
}
