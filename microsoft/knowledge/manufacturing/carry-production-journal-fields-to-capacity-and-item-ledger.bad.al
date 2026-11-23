// Demonstration only; independently authored, not copied from BaseApp.
// Patches posted capacity entries after posting instead of filling them before insert.
codeunit 50176 "Prod. Batch Ref. Posting"
{
    procedure StampCapacityEntries(ProdOrderNo: Code[20]; BatchRef: Code[30])
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderNo);
        CapacityLedgerEntry.ModifyAll("Customer Batch Ref.", BatchRef);
    end;
}
