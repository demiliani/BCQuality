// Demonstration only; independently authored, not copied from BaseApp.
// Fixes the lines after the restore has finished, one extra Modify per line.
codeunit 50130 "Delivery Zone Restore"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ArchiveManagement, 'OnAfterRestoreSalesDocument', '', false, false)]
    local procedure FixZonesAfterRestore(var SalesHeader: Record "Sales Header"; var SalesHeaderArchive: Record "Sales Header Archive")
    var
        SalesLine: Record "Sales Line";
        SalesLineArchive: Record "Sales Line Archive";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet(true) then
            repeat
                if SalesLineArchive.Get(SalesHeaderArchive."Document Type", SalesHeaderArchive."No.",
                    SalesHeaderArchive."Doc. No. Occurrence", SalesHeaderArchive."Version No.", SalesLine."Line No.") then begin
                    SalesLine."Delivery Zone" := SalesLineArchive."Delivery Zone";
                    SalesLine.Modify();
                end;
            until SalesLine.Next() = 0;
        // The header value is not restored at all.
    end;
}
