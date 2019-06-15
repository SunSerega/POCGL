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
  
  case s.ToLower of
    
    'glbyte':       s := 'SByte';
    'glubyte':      s := 'Byte';
    'glchar':       s := 'Byte';
    'glboolean':    s := 'Byte';
    
    'glshort':      s := 'Int16';
    'glushort':     s := 'UInt16';
    
    'glint':        s := 'Int32';
    'glsizei':      s := 'Int32';
    'gluint':       s := 'UInt32';
    'glbitfield':   s := 'UInt32';
    
    'glint64':      s := 'Int64';
    'gluint64':     s := 'UInt64';
    'gluint64ext':  s := 'UInt64';
    
    'glfloat':      s := 'single';
    'glclampf':      s := 'single';
    'gldouble':     s := 'real';
    
    'glintptr':     s := 'IntPtr';
    'glsizeiptr':   s := 'UIntPtr';
    
    'glenum':       s := 'UInt32';
    
    'glvoid',
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
      s := s.Remove('APIENTRY').Replace(#10,' ');
      
      var ind1 := s.IndexOf('(');
      var ind2 := s.LastIndexOf(')');
      
      begin
        var nts := s.Remove(ind1).Trim;
        var ind := nts.LastIndexOf(' ');
        
        name := nts.Substring(ind+3);
        res := GetTypeDefString(nts.Remove(ind));
        
      end;
      
      foreach var p in s.Substring(ind1+1,ind2-ind1-1).Replace('*','* ').Split(',') do
      begin
        if p = 'void' then break;
        var ind := p.LastIndexOf(' ');
        
        var cpar := (
          p.Substring(ind+1),
          GetTypeDefString(p.Remove(ind))
        );
        
        if cpar[0].ToLower in
          ['params', 'type', 'end', 'program', 'array', 'unit', 'label', 'event']
        then cpar := ('&'+cpar[0], cpar[1]);
        if cpar[0].ToLower = 'pointer' then cpar := ('_'+cpar[0], cpar[1]);
        
        par += cpar;
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
      
      if par.Count<>0 then
      begin
        sb += '(';
        sb += par.Select(t->$'{t[0]}: {t[1]}').JoinIntoString('; ');
        sb += ')';
      end;
      
      if f then
      begin
        sb += ': ';
        sb += res;
      end;
      
      sb += ';';
      
      sb.AppendLine;
      sb += '    external ''opengl32.dll'' name ''gl';
      sb += name;
      sb += ''';';
      
      sb.AppendLine;
      Result := sb.ToString;
      
      if Result.Contains('event_wait_list: ^cl_event; &event: ^cl_event') then
        Result :=
          Result.Replace(
          'event_wait_list: ^cl_event; &event: ^cl_event',
          '[MarshalAs(UnmanagedType.LPArray)] event_wait_list: array of cl_event; var &event: cl_event'
          ) + Result;
      
      if Result.Contains('errcode_ret: ^ErrorCode') then
        Result :=
          Result.Replace(
            'errcode_ret: ^ErrorCode',
            'var errcode_ret: ErrorCode'
          ) + Result;
      
    end;
    
  end;

begin
  try
    var text := System.Windows.Forms.Clipboard.GetText;
    
    text := text
      .SkipCharsFromTo('/*', '*/')
      .TakeCharsFromTo('GLAPI', ';')
      .Select(a->FuncDef.Create(a).ToString)
      .JoinIntoString('    '#10);
    
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