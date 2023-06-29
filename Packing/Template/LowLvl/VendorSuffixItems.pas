unit VendorSuffixItems;

uses '../../../POCGL_Utils';

uses LLPackingUtils;
uses ItemNames;

uses NamedItemBase;
uses NamedItemFixerBase;

type
  
  {$region VendorSuffix}
  
  VendorSuffix = sealed class(NamedLoadedItem<VendorSuffix, string>)
    
    static constructor;
    begin
      DefineNameComparer(System.StringComparer.OrdinalIgnoreCase);
      RegisterLoader(br-> new VendorSuffix(br.ReadString, false) );
      ApiVendorLName.RegisterSuffixUseProc(suf->
      begin
        var item := ByName(suf);
        if item<>nil then
          item.MarkReferenced else
          Otp($'WARNING: [{suf}] is not a defined suffix');
      end);
    end;
    
    public procedure MarkBodyReferenced; override := exit;
    
  end;
  
  VendorSuffixFixer = abstract class(NamedItemFixer<VendorSuffixFixer, VendorSuffix, string>)
    
  end;
  
  {$endregion VendorSuffix}
  
end.