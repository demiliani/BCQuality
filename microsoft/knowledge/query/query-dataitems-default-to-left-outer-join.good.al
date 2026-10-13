// Demonstration only. Shows the recommended pattern: the join type is explicit and matches the query's purpose.

query 50229 "Customers With Open Orders Good"
{
    QueryType = Normal;

    elements
    {
        dataitem(Customer; Customer)
        {
            column(CustomerNo; "No.") { }
            column(CustomerName; Name) { }
            dataitem(SalesHeader; "Sales Header")
            {
                DataItemLink = "Sell-to Customer No." = Customer."No.";
                DataItemTableFilter = "Document Type" = const(Order), Status = const(Open);
                SqlJoinType = InnerJoin;
                column(OrderNo; "No.") { }
            }
        }
    }
}

codeunit 50230 "Open Order Reminder Good"
{
    procedure CountOpenOrdersToRemind(): Integer
    var
        CustomersWithOpenOrders: Query "Customers With Open Orders Good";
        Total: Integer;
    begin
        CustomersWithOpenOrders.Open();
        while CustomersWithOpenOrders.Read() do
            Total += 1;
        CustomersWithOpenOrders.Close();
        exit(Total);
    end;
}
