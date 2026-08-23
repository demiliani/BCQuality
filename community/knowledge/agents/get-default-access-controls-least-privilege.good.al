codeunit 50100 "Sales Review Agent Factory"
{
    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        CurrentModuleInfo: ModuleInfo;
        RoleIdTok: Label 'SALES REVIEW AGENT', Locked = true;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Clear(TempAccessControlBuffer);
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::Tenant;
        TempAccessControlBuffer."App ID" := CurrentModuleInfo.Id;
        TempAccessControlBuffer."Role ID" := RoleIdTok;
        TempAccessControlBuffer.Insert();
    end;
}
