// Demonstration only. Shows the wrong pattern: a "customers with open orders" query relies on the default join.

query 50227 "Customers With Open Orders Bad"
{
    QueryType = Normal;

    elements
    {
        dataitem(Customer; Customer)
        {
            column(CustomerNo; "No.") { }
            column(CustomerName; Name) { }
            // BAD: no SqlJoinType, so this is a LeftOuterJoin. Customers without open orders are
            // returned too, with blank order columns.
            dataitem(SalesHeader; "Sales Header")
            {
                DataItemLink = "Sell-to Customer No." = Customer."No.";
                DataItemTableFilter = "Document Type" = const(Order), Status = const(Open);
                column(OrderNo; "No.") { }
            }
        }
    }
}

codeunit 50228 "Open Order Reminder Bad"
{
    procedure CountCustomersToRemind(): Integer
    var
        CustomersWithOpenOrders: Query "Customers With Open Orders Bad";
        Total: Integer;
    begin
        CustomersWithOpenOrders.Open();
        while CustomersWithOpenOrders.Read() do
            Total += 1;
        CustomersWithOpenOrders.Close();
        exit(Total);
    end;
}
