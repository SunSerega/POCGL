unit EnumItems;

uses LLPackingUtils;
uses ItemNames;

uses NamedItemBase;
uses NamedItemFixerBase;

type
  
  {$region Enum}
  
  Enum = sealed class(NamedLoadedItem<Enum, ApiVendorLName>)
    private val: int64;
    private explicitly_ungrouped: boolean;
    
    public constructor(name: ApiVendorLName; val: int64; explicitly_ungrouped, from_fixer: boolean);
    begin
      inherited Create(name, from_fixer);
      self.val := val;
      self.explicitly_ungrouped := explicitly_ungrouped;
      
      if explicitly_ungrouped then
        UseFromGroup else
      if name.l_name.Matches('(?<![A-Z])RESERVED\d*').Any then
        MarkReferenced;
      
    end;
    
    static constructor :=
      RegisterLoader(br->new Enum(new ApiVendorLName(br), br.ReadInt64, br.ReadBoolean, false));
    
    public property Value: int64 read val;
    
    public procedure MarkBodyReferenced; override := exit;
    
    private used_from_group: boolean;
    private used_from_req_list: boolean;
    
    public procedure UseFromGroup;
    begin
      used_from_group := true;
      if used_from_req_list then
        inherited Use(false);
    end;
    public procedure UseFromReqList;
    begin
      used_from_req_list := true;
      if used_from_group then
        inherited Use(false);
    end;
    protected function MakeWasUnusedString: string; override;
    begin
      if used_from_group and used_from_req_list then
        raise new System.InvalidOperationException(self.ToString);
      Result :=
        if used_from_group then
          'not required in any feature/extension' else
        if used_from_req_list then
          'not grouped' else
          'not referenced';
    end;
    
  end;
  
  EnumFixer = abstract class(NamedItemCommonFixer<EnumFixer, Enum>)
    
  end;
  
  {$endregion Enum}
  
end.