// Demonstration only; independently authored, not copied from BaseApp.
// Same field number on the live and archive tables: TransferFields archives the value.
// Assumes the Time Sheet Line extension with field 50185 "Site Code" Code[20].
tableextension 50185 "TS Line Arch. Site Code" extends "Time Sheet Line Archive"
{
    fields
    {
        field(50185; "Site Code"; Code[20])
        {
            Caption = 'Site Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50186; "Archived On"; Date)
        {
            Caption = 'Archived On';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50185 "Time Sheet Archive Stamp"
{
    // Only for a value that has no source field; the record is not inserted yet.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Time Sheet Management", 'OnBeforeTimeSheetLineArchiveInsert', '', false, false)]
    local procedure StampArchiveDate(var TimeSheetLineArchive: Record "Time Sheet Line Archive")
    begin
        TimeSheetLineArchive."Archived On" := Today();
    end;
}
