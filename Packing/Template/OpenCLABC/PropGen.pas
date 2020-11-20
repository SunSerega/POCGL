uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses PackingUtils in '..\PackingUtils';

uses AOtp         in '..\..\..\Utils\AOtp';
uses ATask        in '..\..\..\Utils\ATask';
uses Fixers       in '..\..\..\Utils\Fixers';

function FixWord(w: string): string;
begin
    w := w.ToLower;
    w[1] := w[1].ToUpper;
    Result := w;
end;

type
  Prop = sealed class
    base_name, t: string;
    name, get_prop_name: string;
    
    special_args := new List<string>;
    
    constructor(header: string; data: sequence of string);
    begin
      var wds := header.ToWords(':');
      base_name := wds[0].Trim;
      t := wds[1].Trim;
      
      name := base_name.ToWords('_').Select(FixWord).JoinToString('');
      if name.ToLower in pas_keywords then name := '&'+name;
      
      get_prop_name := t.Remove('array of ');
      get_prop_name := Concat(
        'Get',
        get_prop_name,
        'Arr'*((t.Length-get_prop_name.Length) div 'array of '.Length)
      );
      
      foreach var bl in FixerUtils.ReadBlocks(data, '!', false) do
      case bl[0] of
        
        'add_param': special_args.AddRange(bl[1].Where(l->not string.IsNullOrWhiteSpace(l)));
        
        else raise new System.NotSupportedException(bl[0]);
      end;
      
    end;
    
  end;
  
begin
  try
    
    System.IO.Directory.EnumerateFiles(GetFullPathRTA('PropDef'), '*.dat')
    .Select(fname->ProcTask(()->
    begin
      var t := System.IO.Path.GetFileNameWithoutExtension(fname);
      
      var ps := new List<Prop>;
      
      foreach var bl in FixerUtils.ReadBlocks(fname, false) do
        ps += new Prop(bl[0], bl[1]);
      
      var max_name_len := ps.Max(p->p.name.Length);
      var max_type_len := ps.Max(p->p.t.Length);
      var max_get_prop_len := ps.Max(p->p.get_prop_name.Length);
      
      var res := new System.IO.StreamWriter(GetFullPathRTA($'{t}.Properties.template'), false, enc);
      loop 3 do res.WriteLine('    ');
      foreach var p in ps do
      begin
        res.Write('    public property ');
        res.Write(p.name);
        res.Write(':');
        res.Write(' '*(max_name_len-p.name.Length+1));
        res.Write(p.t.PadRight(max_type_len+1));
        res.Write('read ');
        res.Write(p.get_prop_name.PadRight(max_get_prop_len));
        res.Write('(');
        res.Write(t);
        res.Write('Info.');
        res.Write(t.ToUpper);
        res.Write('_');
        res.Write(p.base_name);
        foreach var arg in p.special_args do
        begin
          res.Write(', ');
          res.Write(arg);
        end;
        res.Write(');');
        res.WriteLine;
      end;
      loop 2 do res.WriteLine('    ');
      res.Write('    ');
      
      res.Close;
      Otp($'Packed props for [{t}]');
    end))
    .CombineAsyncTask
    .SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.