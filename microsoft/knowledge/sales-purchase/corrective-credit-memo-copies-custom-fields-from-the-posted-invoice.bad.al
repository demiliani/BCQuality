// Demonstration only; independently authored, not copied from BaseApp.
// Resets the status only in the correction codeunit, after the header is written.
codeunit 50160 "Export Status Copy Rules"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnAfterCreateCopyDocument', '', false, false)]
    local procedure ResetExportStatus(var SalesHeader: Record "Sales Header")
    begin
        // Extra write; manual Copy Document and purchase corrections still copy "Exported".
        SalesHeader."Export Status" := SalesHeader."Export Status"::"Not Exported";
        SalesHeader.Modify();
    end;
}
