// Demonstration only; independently authored, not copied from BaseApp.
// "Delivery Zone" (field 50130, Code[10]) exists on Sales Header, Sales Line and both archive tables,
// and is defaulted from the customer and the item when those are validated.
codeunit 50130 "Delivery Zone Restore"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ArchiveManagement, 'OnAfterTransferFromArchToSalesHeader', '', false, false)]
    local procedure KeepArchivedHeaderZone(var SalesHeader: Record "Sales Header"; var SalesHeaderArchive: Record "Sales Header Archive")
    begin
        // Revalidation of the customer has replaced the value; put the archived one back.
        SalesHeader."Delivery Zone" := SalesHeaderArchive."Delivery Zone";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ArchiveManagement, 'OnAfterTransferFromArchToSalesLine', '', false, false)]
    local procedure KeepArchivedLineZone(var SalesLine: Record "Sales Line"; var SalesLineArchive: Record "Sales Line Archive")
    begin
        SalesLine."Delivery Zone" := SalesLineArchive."Delivery Zone";
    end;
}
