// Demonstration only; independently authored, not copied from BaseApp.
// "Export Status" (field 50160, Enum "Doc. Export Status") is per-document state, mirrored on the posted headers.
codeunit 50160 "Export Status Copy Rules"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesHeaderDone', '', false, false)]
    local procedure ResetSalesExportStatus(var ToSalesHeader: Record "Sales Header")
    begin
        // Runs for Cancel, Correct and manual Copy Document, before the header is modified.
        ToSalesHeader."Export Status" := ToSalesHeader."Export Status"::"Not Exported";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyPurchHeaderDone', '', false, false)]
    local procedure ResetPurchExportStatus(var ToPurchaseHeader: Record "Purchase Header")
    begin
        ToPurchaseHeader."Export Status" := ToPurchaseHeader."Export Status"::"Not Exported";
    end;
}
