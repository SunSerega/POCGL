﻿unit NamedRecordsData;

uses POCGL_Utils  in '..\..\POCGL_Utils';
uses AOtp         in '..\..\Utils\AOtp';

begin
  try
    var sw := new System.IO.StreamWriter(GetFullPathRTA('NameRecords.template'), false, enc);
    
    foreach var l in ReadLines(GetFullPathRTA('MiscInput\NameRecords.dat')) do
      if not l.Contains('=') then
        sw.WriteLine('  '+l) else
      begin
        var s := l.Split('=');
        var tname := s[0].Trim;
        var tt := s[1].Trim;
        sw.WriteLine($'  {tname} = record');
        sw.WriteLine($'    public val: {tt};');
        sw.WriteLine($'    public constructor(val: {tt}) := self.val := val;');
        sw.WriteLine($'    public static property Zero: {tname} read default({tname});');
        sw.WriteLine($'    public static property Size: integer read Marshal.SizeOf&<{tt}>;');
        sw.WriteLine($'    public function ToString: string; override := $''{tname}[{{val}}]'';');
        sw.WriteLine($'  end;');
      end;
    
    sw.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.