// Demonstration only; independently authored, not copied from BaseApp.
// The worksheet twin has a different field number. TransferFields matches by number,
// so the review date is blanked on every line that goes through the price worksheet.
tableextension 50108 "Price List Line Review" extends "Price List Line"
{
    fields
    {
        field(50108; "Price Review Date"; Date)
        {
            Caption = 'Price Review Date';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 50109 "Price Wksh. Line Review" extends "Price Worksheet Line"
{
    fields
    {
        field(50109; "Price Review Date"; Date)
        {
            Caption = 'Price Review Date';
            DataClassification = CustomerContent;
        }
    }
}
