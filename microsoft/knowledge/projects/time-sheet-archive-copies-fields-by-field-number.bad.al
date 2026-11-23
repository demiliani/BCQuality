// Demonstration only; independently authored, not copied from BaseApp.
// Wrong: the archive field has a different number than the live field 50185 "Site Code".
// TransferFields skips it, and the live Time Sheet Line is deleted right after archiving,
// so the value is lost for good.
tableextension 50187 "TS Line Arch. Site (Bad)" extends "Time Sheet Line Archive"
{
    fields
    {
        field(50187; "Archived Site Code"; Code[20])
        {
            Caption = 'Archived Site Code';
            DataClassification = CustomerContent;
        }
    }
}
