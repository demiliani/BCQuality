profile "SALES REVIEW AGENT"
{
    Caption = 'Sales Review Agent';
    Description = 'Restricted UI for the Sales Review Agent.';
    RoleCenter = "Order Processor Role Center";
    Customizations = "Sales Review Agent Sales Ord.";
}

pagecustomization "Sales Review Agent Sales Ord." customizes "Sales Order"
{
    actions
    {
        modify(Post)
        {
            Visible = false;
        }
    }
}
