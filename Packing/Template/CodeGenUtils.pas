unit CodeGenUtils;

uses System.IO;

uses POCGL_Utils  in '..\..\POCGL_Utils';
uses AOtp         in '..\..\Utils\AOtp';

{$region Writer's}

type
  Writer = abstract class
    
    procedure Write(l: string); abstract;
    static procedure operator+=(wr: Writer; l: string) := wr.Write(l);
    
    procedure Close; abstract;
    
  end;
  FileWriter = sealed class(Writer)
    sw: StreamWriter;
    
    constructor(fname: string) :=
    sw := new StreamWriter(fname, false, enc);
    
    procedure Write(l: string); override := sw.Write(l);
    
    procedure Close; override := sw.Close;
    
  end;
  WriterWrapper = sealed class(Writer)
    base: Writer;
    f: string->string;
    
    constructor(base: Writer; f: string->string);
    begin
      self.base := base;
      self.f := f;
    end;
    
    procedure Write(l: string); override := base.Write(f(l));
    
    procedure Close; override := base.Close;
    
  end;
  WriterArr = sealed class(Writer)
    base: array of Writer;
    
    constructor(params base: array of Writer) :=
    self.base := base;
    
    procedure Write(l: string); override :=
    foreach var wr in base do wr.Write(l);
    
    procedure Close; override :=
    foreach var wr in base do wr.Close;
    
  end;
  WriterEmpty = sealed class(Writer)
    constructor := exit;
    procedure Write(l: string); override := exit;
    procedure Close; override := exit;
  end;
  
{$endregion Writer's}

end.