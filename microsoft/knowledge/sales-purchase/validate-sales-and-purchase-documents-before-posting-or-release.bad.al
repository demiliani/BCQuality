// Demonstration only; independently authored, not copied from BaseApp.
// The rule lives on one page action and, as a fallback, after posting.
pageextension 50190 "Sales Order Rules" extends "Sales Order"
{
    actions
    {
        modify(Post)
        {
            trigger OnBeforeAction()
            begin
                // Batch posting, job queue posting and APIs never run this.
                Rec.TestField("Delivery Window");
            end;
        }
    }
}

codeunit 50190 "Document Rules"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure CheckAfterPosting(var SalesHeader: Record "Sales Header")
    begin
        // Runs after the commit: the document is already posted when this fails.
        SalesHeader.TestField("Delivery Window");
    end;
}
