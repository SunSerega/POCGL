unit CodeGen;

uses System.IO;

{$region Writer's}

type
  Writer = abstract class
    
    public procedure Write(l: string); abstract;
    public static procedure operator+=(wr: Writer; l: string) := wr.Write(l);
    public static function operator*(wr1, wr2: Writer): Writer;
    
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
  WriterArr = sealed class(Writer)
    private base: array of Writer;
    
    public constructor(params base: array of Writer) :=
    self.base := base;
    
    public procedure Write(l: string); override :=
    foreach var wr in base do wr.Write(l);
    
    public procedure Close; override :=
    foreach var wr in base do wr.Close;
    
  end;
  WriterEmpty = sealed class(Writer)
    public constructor := exit;
    public procedure Write(l: string); override := exit;
    public procedure Close; override := exit;
  end;
  
static function Writer.operator*(wr1, wr2: Writer) := new WriterArr(wr1, wr2);

{$endregion Writer's}

end.