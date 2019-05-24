program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

function SkipCharsFromTo(self: sequence of char; f,t: string): sequence of char; extensionmethod;
begin
  var enm := self.GetEnumerator;
  enm.MoveNext;
  var q := new Queue<char>;
  
  while true do
  begin
    while q.Count<f.Length do
    begin
      q += enm.Current;
      if not enm.MoveNext then
      begin
        yield sequence q;
        exit;
      end;
    end;
    
    if q.SequenceEqual(f) then
    begin
      q.Clear;
      
      while true do
      begin
        while q.Count<t.Length do
        begin
          q += enm.Current;
          if not enm.MoveNext then exit;
        end;
        
        if q.SequenceEqual(t) then
          break else
          q.Dequeue;
        
      end;
      
      q.Clear;
    end else
      yield q.Dequeue;
    
  end;
  
  yield sequence q;
end;

function TakeCharsFromTo(self: sequence of char; f,t: string): sequence of array of char; extensionmethod;
begin
  var enm := self.GetEnumerator;
  enm.MoveNext;
  var q := new Queue<char>;
  var res := new List<char>;
  
  while true do
  begin
    while q.Count<f.Length do
    begin
      q += enm.Current;
      if not enm.MoveNext then exit;
    end;
    
    if q.SequenceEqual(f) then
    begin
      q.Clear;
      
      while true do
      begin
        while q.Count<t.Length do
        begin
          q += enm.Current;
          if not enm.MoveNext then
          begin
            res.AddRange(q);
            yield res.ToArray;
            exit;
          end;
        end;
        
        if q.SequenceEqual(t) then
          break else
          res += q.Dequeue;
        
      end;
      
      yield res.ToArray;
      res.Clear;
      q.Clear;
    end else
      q.Dequeue;
    
  end;
  
end;

function GetTypeDefString(s: string): string;
begin
  var rc := s.Count(ch->ch='*');
  s := s.Remove('const ', ' ', '*', #13, #10);
  
  case s of
    
    'cl_char':    s := 'SByte';
    'cl_uchar':   s := 'Byte';
    
    'cl_short':   s := 'Int16';
    'cl_ushort':  s := 'UInt16';
    
    'cl_int':     s := 'ErrorCode';
    'cl_uint':    s := 'UInt32';
    
    'cl_long':    s := 'Int64';
    'cl_ulong':   s := 'UInt64';
    
    'cl_float':   s := 'single';
    'cl_double':  s := 'real';
    
    'cl_half':    s := 'UInt16';
    
    'intptr_t':   s := 'IntPtr';
    'size_t':     s := 'UIntPtr';
    
    'void':
    if rc<>0 then
    begin
      s := 'pointer';
      rc -= 1;
    end;
  end;
  
  Result := '^'*rc + s;
end;

type
  FuncDef = class
    
    name: string;
    res: string;
    
    par := new List<(string,string)>;
    
    constructor(a: array of char);
    begin
      
      var s := new string(a);
      s := s.Remove('CL_API_ENTRY','CL_API_CALL').Replace(#10,' ');
      
      var ind1 := s.IndexOf('(');
      var ind2 := s.LastIndexOf(')');
      
      begin
        var nts := s.Remove(ind1).Trim;
        var ind := nts.LastIndexOf(' ');
        
        name := nts.Substring(ind+3);
        res := GetTypeDefString(nts.Remove(ind));
        
      end;
      
      foreach var p in s.Substring(ind1+1,ind2-ind1-1).Split(',') do
      begin
        var ind := p.LastIndexOf(' ');
        
        par += (
          p.Substring(ind+1),
          GetTypeDefString(p.Remove(ind))
        );
        
      end;
      
    end;
    
    public function ToString: string; override;
    begin
      var f := res<>'void';
      var sb := new StringBuilder;
      sb += '    static ';
      
      sb += f?'function':'procedure';
      sb += ' ';
      sb += name;
      
      sb += '(';
      sb += par.Select(t->$'{t[0]}: {t[1]}').JoinIntoString('; ');
      sb += ')';
      
      if f then
      begin
        sb += ': ';
        sb += res;
      end;
      
      sb += ';';
      
      sb.AppendLine;
      sb += '    external ''opencl.dll'' name ''cl';
      sb += name;
      sb += ''';';
      
      sb.AppendLine;
      Result := sb.ToString;
    end;
    
  end;

begin
  try
    var text := System.Windows.Forms.Clipboard.GetText;
    
    text := text
      .SkipCharsFromTo('/*', '*/')
      .TakeCharsFromTo('extern', ';')
      .Select(a->FuncDef.Create(a).ToString)
      .JoinIntoString(#10);
    
    text += '    ';
    
    System.Windows.Forms.Clipboard.SetText(#10+text);
    System.Console.Beep;
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.