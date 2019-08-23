unit CoreFuncData;

type
  CoreFuncDef = class
    name: string := nil;
    chapter := new List<(integer,string)>;
    
    constructor(name: string) :=
    self.name := name;
    
    procedure Save(bw: System.IO.BinaryWriter);
    begin
      
      bw.Write(name);
      
      bw.Write(chapter.Count);
      foreach var t in chapter do
      begin
        bw.Write(t[0]);
        bw.Write(t[1]);
      end;
      
    end;
    
    static function Load(br: System.IO.BinaryReader): CoreFuncDef;
    begin
      Result := new CoreFuncDef;
      
      Result.name := br.ReadString;
      
      Result.chapter := new List<(integer,string)>(br.ReadInt32);
      loop Result.chapter.Capacity do
        Result.chapter += (br.ReadInt32, br.ReadString);
      
    end;
    
    public function ToString: string; override :=
    $'{name} : [{chapter.JoinIntoString}]';
    
  end;

end.