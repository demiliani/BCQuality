codeunit 50100 "Validate Partial Rec Good"
{
    procedure UppercaseUsCustomerNames()
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("Country/Region Code", 'US');
        if Customer.FindSet(true) then
            repeat
                Customer.Name := UpperCase(Customer.Name);
                Customer.Modify(false);
            until Customer.Next() = 0;
    end;
}
