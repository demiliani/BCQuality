// Demonstration only; independently authored, not copied from BaseApp.
// Assumes Sales Line and Purchase Line extensions with field 50200 "Product Line Code" Code[10].
tableextension 50200 "Inv. Post. Buffer Product Line" extends "Invoice Posting Buffer"
{
    fields
    {
        field(50200; "Product Line Code"; Code[10])
        {
            Caption = 'Product Line Code';
            DataClassification = SystemMetadata;
        }
    }
}

tableextension 50201 "Gen. Jnl. Line Product Line" extends "Gen. Journal Line"
{
    fields
    {
        field(50200; "Product Line Code"; Code[10])
        {
            Caption = 'Product Line Code';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50202 "G/L Entry Product Line" extends "G/L Entry"
{
    fields
    {
        field(50200; "Product Line Code"; Code[10])
        {
            Caption = 'Product Line Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}

codeunit 50200 "Product Line G/L Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnPrepareLineOnAfterFillInvoicePostingBuffer', '', false, false)]
    local procedure FillFromSalesLine(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
        InvoicePostingBuffer."Product Line Code" := SalesLine."Product Line Code";
    end;

    // IsHandled is not declared, so the standard buffer update still runs.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnPrepareLineOnAfterFillInvoicePostingBuffer', '', false, false)]
    local procedure FillFromPurchLine(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchLine: Record "Purchase Line")
    begin
        InvoicePostingBuffer."Product Line Code" := PurchLine."Product Line Code";
    end;

    // Lines with different product lines must not merge into one G/L entry.
    [EventSubscriber(ObjectType::Table, Database::"Invoice Posting Buffer", 'OnAfterBuildPrimaryKey', '', false, false)]
    local procedure AddToGroupId(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        InvoicePostingBuffer."Group ID" :=
            CopyStr(
                InvoicePostingBuffer."Group ID" +
                InvoicePostingBuffer.PadField(InvoicePostingBuffer."Product Line Code", MaxStrLen(InvoicePostingBuffer."Product Line Code")),
                1, MaxStrLen(InvoicePostingBuffer."Group ID"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Invoice Posting Buffer", 'OnAfterCopyToGenJnlLine', '', false, false)]
    local procedure CopyToJournalLine(var GenJnlLine: Record "Gen. Journal Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        GenJnlLine."Product Line Code" := InvoicePostingBuffer."Product Line Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', false, false)]
    local procedure CopyToGLEntry(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."Product Line Code" := GenJournalLine."Product Line Code";
    end;
}
