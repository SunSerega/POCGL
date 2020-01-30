unit FuncData;

interface

uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

type
  Group = sealed class
    public name: string;
    public bitmask: boolean;
    public enums: Dictionary<string, int64>;
    
    public ext_name: string;
    
    public constructor := exit;
    
    public procedure FinishInit;
    begin
      
      var i := name.Length;
      while name[i].IsUpper do i -= 1;
      ext_name := i=name.Length ? '' : name.Substring(i);
      
    end;
    
    public constructor(br: System.IO.BinaryReader);
    begin
      name := br.ReadString;
      bitmask := br.ReadBoolean;
      
      var enums_count := br.ReadInt32;
      enums := new Dictionary<string, int64>(enums_count);
      loop enums_count do
      begin
        var key := br.ReadString.Substring(3);
        var val := br.ReadInt64;
        enums.Add(key, val);
      end;
      
      FinishInit;
    end;
    
    private function EnumrKeys := enums.Keys.OrderBy(ename->enums[ename]).ThenBy(ename->ename);
    private property ValueStr[ename: string]: string read '$'+enums[ename].ToString('X4');
    
    public procedure Write(sb: StringBuilder);
    begin
      var max_w := enums.Keys.Max(ename->ename.Length);
      sb +=       $'  {name} = record' + #10;
      
      sb +=       $'    public val: UInt32;' + #10;
      sb +=       $'    public constructor(val: UInt32) := self.val := val;' + #10;
      sb +=       $'    ' + #10;
      
      foreach var ename in EnumrKeys do
        sb +=     $'    private static _{ename.PadRight(max_w)} := new {name}({ValueStr[ename]});' + #10;
      sb +=       $'    ' + #10;
      
      foreach var ename in EnumrKeys do
        sb +=     $'    public static property {ename}:{'' ''*(max_w-ename.Length)} {name} read _{ename};' + #10;
      sb +=       $'    ' + #10;
      
      if bitmask then
      begin
        
        sb +=     $'    public static function operator or(f1,f2: {name}) := new {name}(f1.val or f2.val);' + #10;
        sb +=     $'    ' + #10;
        
        foreach var ename in EnumrKeys do
          if enums[ename]<>0 then
            sb += $'    public property HAS_FLAG_{ename}:{'' ''*(max_w-ename.Length)} boolean read self.val and {ValueStr[ename]} <> 0;' + #10 else
            sb += $'    public property ANY_FLAGS: boolean read self.val<>0;' + #10;
        sb +=     $'    ' + #10;
        
      end;
      
      sb +=       $'    public function ToString: string; override;' + #10;
      sb +=       $'    begin' + #10;
      if bitmask then
      begin
        sb +=     $'      var res := typeof({name}).GetProperties.Where(prop->prop.Name.StartsWith(''HAS_FLAG_'') and boolean(prop.GetValue(self))).Select(prop->prop.Name).ToList;' + #10;
        sb +=     $'      Result := res.Count=0?' + #10;
        sb +=     $'        $''{name}[{{ self.val=0 ? ''''NONE'''' : self.val.ToString(''''X'''') }}]'':' + #10;
        sb +=     $'        res.JoinIntoString(''+'');' + #10;
      end else
      begin
        sb +=     $'      var res := typeof({name}).GetProperties(System.Reflection.BindingFlags.Static or System.Reflection.BindingFlags.Public).FirstOrDefault(prop->UInt32(prop.GetValue(self))=self.val);' + #10;
        sb +=     $'      Result := res=nil?' + #10;
        sb +=     $'        $''{name}[{{ self.val=0 ? ''''NONE'''' : self.val.ToString(''''X'''') }}]'':' + #10;
        sb +=     $'        res.Name;' + #10;
      end;
      sb +=       $'    end;' + #10;
      sb +=       $'    ' + #10;
      
      sb +=       $'  end;'+#10;
      sb +=       $'  ' + #10;
    end;
    
  end;
  
  GroupFixer = abstract class(Fixer<GroupFixer>)
    
    public static constructor;
    
    protected procedure Apply(gr: Group); abstract;
    
    public static procedure ApplyAll(grs: List<Group>);
    begin
      grs.Capacity := grs.Count + adders.Count;
      
      foreach var a in adders do
      begin
        var gr := new Group;
        a.Apply(gr);
        grs += gr;
      end;
      
      for var i := grs.Count-1 downto 0 do
      begin
        var gr := grs[i];
        GroupFixer[gr.name].Apply(gr);
        if gr.name=nil then grs.RemoveAt(i);
      end;
      
      grs.Capacity := grs.Count;
    end;
    
    protected procedure WarnUnused; override :=
    Otp($'WARNING: Fixer of group [{self.name}] wasn''t used');
    
  end;
  
implementation

type
  GroupFixerContainer = sealed class(GroupFixer)
    private fixers: array of GroupFixer;
    public constructor(name: string; fixers: sequence of GroupFixer);
    begin
      inherited Create(name);
      self.fixers := fixers.ToArray;
    end;
    
    protected procedure Apply(gr: Group); override :=
    foreach var f in fixers do f.Apply(gr);
    
  end;
  InternalGroupFixer = abstract class(GroupFixer)
    
    public constructor :=
    inherited Create(nil);
    
  end;
  
  GroupAdder = sealed class(InternalGroupFixer)
    private name: string;
    private bitmask: boolean;
    private enums := new Dictionary<string, int64>;
    
    public constructor(name: string; data: sequence of string);
    begin
      self.name := name;
      var enmr := data.Where(l->not string.IsNullOrWhiteSpace(l)).GetEnumerator;
      
      if not enmr.MoveNext then raise new System.FormatException;
      bitmask := boolean.Parse(enmr.Current);
      
      while enmr.MoveNext do
      begin
        var t := enmr.Current.Split('=');
        enums.Add(t[0], t[1].StartsWith('0x') ?
          System.Convert.ToInt64(t[1], 16) :
          System.Convert.ToInt64(t[1])
        );
      end;
      
      GroupFixer.adders.Add( self );
    end;
    
    protected procedure Apply(gr: Group); override;
    begin
      gr.name     := self.name;
      gr.bitmask  := self.bitmask;
      gr.enums    := self.enums;
      gr.FinishInit;
    end;
    
  end;
  
  GroupNameFixer = sealed class(InternalGroupFixer)
    public new_name: string;
    
    public constructor(data: sequence of string) :=
    self.new_name := data.Single(l->not string.IsNullOrWhiteSpace(l));
    
    protected procedure Apply(gr: Group); override :=
    gr.name := new_name;
    
  end;
  
static constructor GroupFixer.Create;
begin
  empty := new GroupFixerContainer(nil, new GroupFixer[0]);
  
  foreach var gr in ReadBlocks(GetFullPath('..\Fixers\Enums.dat', GetEXEFileName)) do
  begin
    var ToDo2196 := 0; //ToDo #2196
    
    new GroupFixerContainer(gr[0],
      ReadBlocks(gr[1],'!')
      .Select(bl->
      begin
        var res: GroupFixer;
        
        case bl[0] of
          
          'add': new GroupAdder(gr[0], bl[1]);
          
          'rename': res := new GroupNameFixer(bl[1]);
          
          else raise new MessageException($'Invalid group fixer type [!{bl[0]}] for group [{gr[0]}]');
        end;
        
        Result := res;
      end)
      .Where(f->f<>nil)
    );
    
  end;
  
end;

end.