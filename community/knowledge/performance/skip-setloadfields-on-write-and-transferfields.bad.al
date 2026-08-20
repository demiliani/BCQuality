codeunit 50100 "Skip LoadFields Write Bad"
{
    procedure UppercaseUsCustomerNames()
    var
        Customer: Record Customer;
    begin
        // Partial load plus Modify forces a JIT full-row load per iteration.
        Customer.SetLoadFields(Name);
        Customer.SetRange("Country/Region Code", 'US');
        if Customer.FindSet(true) then
            repeat
                Customer.Name := UpperCase(Customer.Name);
                Customer.Modify(false);
            until Customer.Next() = 0;
    end;
}
