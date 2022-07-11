unit CodeGen;

uses System.IO;

{$region Writer's}

type
  Writer = abstract class
    
    public procedure Write(l: string); abstract;
    public static procedure operator+=(wr: Writer; l: string) := wr.Write(l);
    public static procedure operator+=(wr: Writer; c: integer) := wr += c.ToString;
    public static function operator*(wr1, wr2: Writer): Writer;
    
    public procedure WriteNumbered(c: integer; a: string);
    begin
      if c<1 then raise new System.InvalidOperationException;
      var ind := a.IndexOf('!');
      var a_long := if ind=-1 then a else a.Remove(ind,1);
      var a_short := if ind=-1 then a else a.Remove(ind);
      
      var wr := self;
      for var i := 1 to c-1 do wr += a_long.Replace('%', i.ToString);
      wr += a_short.Replace('%', c.ToString);
      
    end;
    
    public procedure Close; abstract;
    
  end;
  
  FileWriter = sealed class(Writer)
    private sw: StreamWriter;
    
    private static enc := new System.Text.UTF8Encoding(true);
    public constructor(fname: string) :=
    sw := new StreamWriter(fname, false, enc);
    
    public procedure Write(l: string); override := sw.Write(l);
    
    public procedure Close; override := sw.Close;
    
  end;
  WriterWrapper = sealed class(Writer)
    private base: Writer;
    private f: string->string;
    
    public constructor(base: Writer; f: string->string);
    begin
      self.base := base;
      self.f := f;
    end;
    
    public procedure Write(l: string); override := base.Write(f(l));
    
    public procedure Close; override := base.Close;
    
  end;
  WriterEmpty = sealed class(Writer)
    public constructor := exit;
    public procedure Write(l: string); override := exit;
    public procedure Close; override := exit;
  end;
  WriterArr = sealed class(Writer)
    private base: array of Writer;
    
    public constructor(params base: array of Writer);
    begin
      var base_as_a := base.ConvertAll(wr->wr as WriterArr);
      
      var cap := 0;
      for var i := 0 to base.Length-1 do
        cap += if base_as_a[i]<>nil then
          base_as_a[i].base.Length else
          integer(not(base[i] is WriterEmpty));
      
      var l := new List<Writer>(cap);
      for var i := 0 to base.Length-1 do
        if base_as_a[i]<>nil then
          l.AddRange(base_as_a[i].base) else
        if not(base[i] is WriterEmpty) then
          l.Add(base[i]);
      
      self.base := l.ToArray;
    end;
    
    public procedure Write(l: string); override :=
    foreach var wr in base do wr.Write(l);
    
    public procedure Close; override :=
    foreach var wr in base do wr.Close;
    
  end;
  
static function Writer.operator*(wr1, wr2: Writer) := new WriterArr(wr1, wr2);

{$endregion Writer's}

end.