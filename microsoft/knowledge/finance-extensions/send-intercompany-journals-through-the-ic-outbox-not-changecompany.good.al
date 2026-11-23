// Demonstration only; independently authored, not copied from BaseApp.
// Posts through an Intercompany journal batch so the IC outbox is used; the partner creates its own lines.
// Assumes field 50155 "Settlement Ref." Code[20] on Gen. Journal Line, IC Outbox Jnl. Line,
// IC Inbox Jnl. Line and Handled IC Inbox Jnl. Line (same number: Handled is filled by TransferFields).
codeunit 50155 "IC Settlement Journal"
{
    procedure PostSettlement(TemplateName: Code[10]; BatchName: Code[10]; ICPartnerCode: Code[20]; ICGLAccountNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; SettlementRef: Code[20])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlTemplate.Get(TemplateName);
        GenJnlTemplate.TestField(Type, GenJnlTemplate.Type::Intercompany); // only this type creates the outbox transaction

        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := TemplateName;
        GenJnlLine."Journal Batch Name" := BatchName;
        GenJnlLine."Line No." := 10000;
        GenJnlLine.Insert(true);
        GenJnlLine.Validate("Posting Date", WorkDate());
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", GLAccountNo);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"IC Partner");
        GenJnlLine.Validate("Bal. Account No.", ICPartnerCode);
        GenJnlLine.Validate("IC Account Type", GenJnlLine."IC Account Type"::"G/L Account");
        GenJnlLine.Validate("IC Account No.", ICGLAccountNo);
        GenJnlLine.Validate(Amount, Amount);
        GenJnlLine."Settlement Ref." := SettlementRef;
        GenJnlLine.Modify(true);

        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJnlLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ICInboxOutboxMgt, 'OnInsertOutboxJnlLineOnBeforeICOutboxJnlLineInsert', '', false, false)]
    local procedure JournalToOutbox(var ICOutboxJnlLine: Record "IC Outbox Jnl. Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
        ICOutboxJnlLine."Settlement Ref." := TempGenJournalLine."Settlement Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ICInboxOutboxMgt, 'OnOutboxJnlLineToInboxOnBeforeICInboxJnlLineInsert', '', false, false)]
    local procedure OutboxToInbox(var ICInboxJnlLine: Record "IC Inbox Jnl. Line"; var ICOutboxJnlLine: Record "IC Outbox Jnl. Line")
    begin
        // May run in the sending company: copy only.
        ICInboxJnlLine."Settlement Ref." := ICOutboxJnlLine."Settlement Ref.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ICInboxOutboxMgt, 'OnCreateJournalLinesOnBeforeModify', '', false, false)]
    local procedure InboxToJournal(var GenJournalLine: Record "Gen. Journal Line"; ICInboxJnlLine: Record "IC Inbox Jnl. Line")
    begin
        // Runs in the partner company while it accepts the inbox transaction.
        GenJournalLine."Settlement Ref." := ICInboxJnlLine."Settlement Ref.";
    end;
}
