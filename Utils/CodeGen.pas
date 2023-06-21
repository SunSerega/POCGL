unit CodeGen;

uses System.IO;

{$region Writer's} type
  
  {$region Base}
  
  Writer = abstract class
    
    public procedure Write(s: string); abstract;
    public static procedure operator+=(wr: Writer; s: string) := wr.Write(s);
    public static procedure operator+=(wr: Writer; c: integer) := wr += c.ToString;
    
    public static function operator*(wr: Writer; f: string->string): Writer;
    public static function operator*(wr1, wr2: Writer): Writer;
    
    public procedure WriteNumbered(c: integer; write_body, write_tail: (Writer, integer)->(); from_ind: integer := 1);
    begin
      if c<1 then raise new System.InvalidOperationException;
      for var i := 0 to c-2 do
      begin
        write_body(self, i+from_ind);
        write_tail(self, i+from_ind);
      end;
      write_body(self, c-1+from_ind);
    end;
    
    /// 3 * 'a%b!c%d'
    /// 'a1bc1d'
    /// 'a2bc2d'
    /// 'a3b'
    /// (all in one line by default, text after ! is separator)
    public procedure WriteNumbered(c: integer; a: string; from_ind: integer := 1);
    begin
      var ind := a.IndexOf('!');
      var a_body := if ind=-1 then a else a.Remove(ind);
      var a_tail := if ind=-1 then '' else a.Remove(0,ind+1);
      
      WriteNumbered(c,
        (wr,i)->(wr += a_body.Replace('%', i.ToString)),
        (wr,i)->(wr += a_tail.Replace('%', i.ToString)),
        from_ind
      );
      
    end;
    
    public procedure WriteSeparated<T>(seq: sequence of T; write_body: (Writer, T)->(); write_tail: Writer->());
    begin
      var enmr := seq.GetEnumerator;
      if not enmr.MoveNext then exit;
      write_body(self, enmr.Current);
      while enmr.MoveNext do
      begin
        write_tail(self);
        write_body(self, enmr.Current);
      end;
    end;
    public procedure WriteSeparated<T>(seq: sequence of T; write_body: (Writer, T)->(); tail: string) :=
      WriteSeparated(seq, write_body, wr->(wr += tail));
    
    public procedure Flush; abstract;
    public procedure Close; abstract;
    
  end;
  
  {$endregion Base}
  
  {$region File}
  
  FileWriter = sealed class(Writer)
    private sw: StreamWriter;
    
    private static enc := new System.Text.UTF8Encoding(true);
    public constructor(fname: string) :=
      sw := new StreamWriter(fname, false, enc);
    private constructor :=
      raise new System.InvalidOperationException;
    
    public procedure Write(s: string); override := sw.Write(s);
    
    public procedure Flush; override := sw.Flush;
    public procedure Close; override := sw.Close;
    
  end;
  
  {$endregion File}
  
  {$region StringBuilder}
  
  WriterSB = sealed class(Writer)
    private sb: StringBuilder;
    
    public constructor(sb: StringBuilder) := self.sb := sb;
    public constructor := Create(new StringBuilder);
    
    public procedure Write(s: string); override := sb += s;
    
    public procedure Flush; override := exit;
    public procedure Close; override := exit;
    
    public function ToString: string; override :=
      sb.ToString;
    
  end;
  
  {$endregion StringBuilder}
  
  {$region Empty}
  
  WriterEmpty = sealed class(Writer)
    private constructor := exit;
    
    private static inst := new WriterEmpty;
    public static property Instance: WriterEmpty read inst;
    
    public procedure Write(s: string); override := exit;
    public procedure Flush; override := exit;
    public procedure Close; override := exit;
    
  end;
  
  {$endregion Empty}
  
  {$region Converter}
  
  WriterConverter = sealed class(Writer)
    private base: Writer;
    private f: string->string;
    
    public constructor(base: Writer; f: string->string);
    begin
      self.base := base;
      self.f := f;
    end;
    private constructor :=
      raise new System.InvalidOperationException;
    
    public procedure Write(s: string); override := base.Write(f(s));
    
    public procedure Flush; override := base.Flush;
    public procedure Close; override := base.Close;
    
  end;
  
  {$endregion Converter}
  
  {$region Arr}
  
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
    private constructor :=
      raise new System.InvalidOperationException;
    
    public procedure Write(s: string); override :=
      foreach var wr in base do wr.Write(s);
    
    public procedure Flush; override :=
      foreach var wr in base do wr.Flush;
    public procedure Close; override :=
      foreach var wr in base do wr.Close;
    
  end;
  
  {$endregion Arr}
  
static function Writer.operator*(wr: Writer; f: string->string) := new WriterConverter(wr, f);

static function Writer.operator*(wr1, wr2: Writer) := new WriterArr(wr1, wr2);

{$endregion Writer's}

end.