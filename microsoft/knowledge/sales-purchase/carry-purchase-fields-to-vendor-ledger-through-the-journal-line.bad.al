// Demonstration only; independently authored, not copied from BaseApp.
// Patches the posted vendor entry after the posting commit.
codeunit 50150 "Supplier Ref. Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure PatchVendorEntry(var PurchaseHeader: Record "Purchase Header"; PurchInvHdrNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", PurchInvHdrNo);
        if VendorLedgerEntry.FindFirst() then begin
            VendorLedgerEntry."Supplier Contract Ref." := PurchaseHeader."Supplier Contract Ref.";
            VendorLedgerEntry.Modify();
        end;
    end;
}
