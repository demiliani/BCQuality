codeunit 50100 "Skip LoadFields Write Good"
{
    procedure UppercaseUsCustomerNames()
    var
        Customer: Record Customer;
    begin
        // Write path: load the full row. SetLoadFields would JIT on Modify.
        Customer.SetRange("Country/Region Code", 'US');
        if Customer.FindSet(true) then
            repeat
                Customer.Name := UpperCase(Customer.Name);
                Customer.Modify(false);
            until Customer.Next() = 0;
    end;
}
