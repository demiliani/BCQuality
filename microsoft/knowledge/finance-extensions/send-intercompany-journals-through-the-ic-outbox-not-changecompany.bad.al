// Demonstration only; independently authored, not copied from BaseApp.
// Writes and posts the partner's journal line from the sending company with ChangeCompany.
codeunit 50156 "IC Settlement Direct Write"
{
    procedure PostSettlementInPartner(PartnerCompany: Text[30]; TemplateName: Code[10]; BatchName: Code[10]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        PartnerGenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        PartnerGenJnlLine.ChangeCompany(PartnerCompany);
        PartnerGenJnlLine.Init();
        PartnerGenJnlLine."Journal Template Name" := TemplateName;
        PartnerGenJnlLine."Journal Batch Name" := BatchName;
        PartnerGenJnlLine."Line No." := 10000;
        // Triggers run in the sending company: account, posting groups, dimensions and
        // number series are read from the wrong company's setup.
        PartnerGenJnlLine.Validate("Account No.", GLAccountNo);
        PartnerGenJnlLine.Validate(Amount, Amount);
        PartnerGenJnlLine.Insert(true);

        // Posts into the sending company's ledgers; no IC inbox or outbox transaction exists.
        GenJnlPostLine.RunWithCheck(PartnerGenJnlLine);
    end;
}
