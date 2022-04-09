uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses Fixers       in '..\..\..\Utils\Fixers';
uses CodeGen      in '..\..\..\Utils\CodeGen';

uses PackingUtils in '..\PackingUtils';

type
  KATypeWriter = record
    public n,m, all: Writer;
    public class_name := default(string);
    
    private static dir := GetFullPathRTA('KernelArg');
    private static container := default(KATypeWriter);
    static constructor;
    begin
      container.n := new WriterEmpty;
      container.m := new WriterEmpty;
      System.IO.Directory.CreateDirectory(dir);
      container := new KATypeWriter(nil);
    end;
    
    private static named := new List<KATypeWriter>;
    public constructor(tname: string);
    begin
      var dir := if tname=nil then
        KATypeWriter.dir else
        GetFullPath(tname, KATypeWriter.dir);
      System.IO.Directory.CreateDirectory(dir);
      
      self.n := new FileWriter(GetFullPath('interface.template', dir));
      self.m := new FileWriter(GetFullPath('implementation.template', dir));
      self.all := n*m;
      
      loop 3 do
      begin
        n += '  ';
        if tname<>nil then
          n += '  ';
        all += #10;
      end;
      
      if tname=nil then exit;
      named.Add(self);
      
      var class_name := if tname<>'Generic' then
        $'KernelArg{tname}' else $'KernelArg';
      self.class_name := class_name;
      
      container.WriteReg(1, tname, ()->
      begin
        
        container.n += '  ';
        container.n += class_name;
        container.n += ' = abstract partial class';
        if tname<>'Generic' then
          container.n += '(KernelArg)';
        container.n += #10;
        container.n += '    '#10;
        
        container.n += '    ';
        container.all += '{%';
        container.all += tname;
        container.all += '\';
        container.n += 'interface';
        container.m += 'implementation';
        container.all += '%}';
        container.all += #10;
        container.n += '    ';
        container.all += #10;
        
        container.n += '  end;'#10;
        container.n += '  '#10;
        
      end);
      
    end;
    
    private constructor(w1, w2: KATypeWriter);
    begin
      self.n := w1.n*w2.n;
      self.m := w1.m*w2.m;
      self.all := n*m;
    end;
    public static function operator*(w1, w2: KATypeWriter) := new KATypeWriter(w1, w2);
    
    public constructor := raise new System.InvalidOperationException;
    
    public static procedure CloseAll;
    begin
      var wr := KATypeWriter.named.Aggregate((w1,w2)->w1*w2);
      var wr_and_cont := wr * container;
      
      wr          .n += '    '#10'    ';
      container   .n +=   '  '#10'  ';
      wr_and_cont .m +=       #10;
      
      wr_and_cont.all.Close;
    end;
    
    public procedure WriteReg(tab: integer; rname: string; act: ()->());
    begin
      loop tab do n += '  ';
      all += '{$region ';
      all += rname;
      all += '}'#10;
      loop tab do n += '  ';
      all += #10;
      
      act();
      
      loop tab do n += '  ';
      all += '{$endregion ';
      all += rname;
      all += '}'#10;
      loop tab do n += '  ';
      all += #10;
    end;
    
    public procedure WriteFrom(inp_nick, par_name, inp_tname: string; gen: boolean; other_pars: array of (string,string); sellout_to: string) :=
    WriteReg(2, inp_nick, ()->
    begin
      
      var write_pars := procedure(wr: Writer; q: string)->
      begin
        if gen then wr += '<T>';
        wr += '(';
        wr += par_name;
        wr += ': ';
        if q<>nil then
        begin
          wr += q;
          wr += '<';
        end;
        if inp_tname=nil then
        begin
          if gen then wr += 'T' else
            raise new System.InvalidOperationException;
        end else
        begin
          wr += inp_tname;
          if gen then wr += if inp_tname.StartsWith('array') then
            ' of T' else '<T>';
        end;
        if q<>nil then wr += '>';
        foreach var (pn, pd) in other_pars do
        begin
          wr += '; ';
          wr += pd;
        end;
        wr += '): ';
        wr += class_name;
        wr += ';';
        if gen then wr += ' where T: record;'
      end;
      
      n += '    public ';
      all += 'static function ';
      m += class_name;
      m += '.';
      all += 'From';
      all += inp_nick;
      write_pars(all, 'CommandQueue');
      all += #10;
      
      m += 'begin Result := ';
      if sellout_to=nil then
      begin
        m += 'new ';
        m += class_name;
        m += inp_nick;
      end else
      begin
        m += sellout_to;
        m += '.From';
        m += inp_nick;
      end;
      m += '(';
      m += par_name;
      foreach var (pn, pd) in other_pars do
      begin
        m += ', ';
        m += pn;
      end;
      m += ') end;'#10;
      
      foreach var q in |nil, 'CommandQueue', 'ConstQueue', 'ParameterQueue'| do
      begin
        n += '    public static function operator implicit';
        write_pars(n, q);
        n += #10;
        n += '    begin Result := From';
        n += inp_nick;
        n += '(';
        n += par_name;
        foreach var (pn, pd) in other_pars do
        begin
          n += ', ';
          n += pn;
        end;
        n += ') end;'#10;
      end;
      
      n += '    ';
      all += #10;
    end);
    public procedure WriteFrom(inp_nick, par_name, inp_tname: string; gen: boolean; other_pars: array of (string,string)) :=
    WriteFrom(inp_nick, par_name, inp_tname, gen, other_pars, nil);
    public procedure WriteFrom(inp_nick, par_name, inp_tname: string; gen: boolean) :=
    WriteFrom(inp_nick, par_name, inp_tname, gen, System.Array.Empty&<(string,string)>);
    
  end;
  
begin
  try
    var wr_global   := new KATypeWriter('Global');
    var wr_constant := new KATypeWriter('Constant');
    var wr_local    := new KATypeWriter('Local');
    var wr_private  := new KATypeWriter('Private');
    var wr_generic  := new KATypeWriter('Generic');
    
//    (wr_global*wr_constant*wr_private*wr_generic).WriteReg(2, 'Managed', ()->
//    begin
//      
//      wr_private.WriteFrom('Value', 'val', nil, true);
//      
//      for var dim := 1 to 3 do
//      begin
//        
//        var inp_nick := 'Array';
//        if dim<>1 then inp_nick += dim.ToString;
//        
//        var inp_tname := 'array';
//        if dim<>1 then inp_tname += '[' + ','*(dim-1) + ']';
//        
//        var par1 := |($'c', 'c: Context := nil')|;
//        var par2 := par1+|('kernel_use', 'kernel_use: MemoryUsage := MemoryUsage.read_write_bits')|;
//        
//        wr_global   .WriteFrom(inp_nick, 'a', inp_tname, true, par2);
//        wr_constant .WriteFrom(inp_nick, 'a', inp_tname, true, par1);
//        wr_private  .WriteFrom(inp_nick, 'a', inp_tname, true);
//        wr_generic  .WriteFrom(inp_nick, 'a', inp_tname, true, par2, wr_global.class_name);
//        
//      end;
//      
//    end);
    
    {$region Local}
    
    foreach var t in |nil, 'UInt32', 'Int32', 'UInt64', 'Int64'| do
    begin
      var n := wr_local.n;
      var m := if t=nil then wr_local.m else new WriterEmpty;
      var all := n*m;
      
      n += '    public ';
      all += 'static function ';
      m += wr_local.class_name;
      m += '.';
      all += 'FromBytes(bytes: CommandQueue<';
      all += t ?? 'UIntPtr';
      all += '>)';
      
      if t=nil then
      begin
        n += ': ';
        n += wr_local.class_name;
        n += ';'#10;
        
        m += ' := new ';
        m += wr_local.class_name;
        m += 'Bytes(bytes);'#10;
      end else
        n += ' := FromBytes(bytes.ThenConstConvert(bytes->new UIntPtr(bytes)));'#10;
      
    end;
    wr_local.n += '    ';
    wr_local.all += #10;
    
    begin
      var n := wr_local.n;
      var m := wr_local.m;
      var all := n*m;
      
      foreach var t in |'UInt32','Int32'| do
      begin
        n += '    public ';
        all += 'static function ';
        m += wr_local.class_name;
        m += '.';
        all += 'FromItemCount<T>(item_count: CommandQueue<';
        all += t;
        all += '>): ';
        all += wr_local.class_name;
        all += '; where T: record;'#10;
        
        m += 'begin'#10;
        m += '  BlittableHelper.RaiseIfBad(typeof(T), ''%Err:Blittable:Source:';
        m += wr_local.class_name;
        m += ':ItemCount%'');'#10;
        m += '  Result := FromBytes(item_count.ThenConstConvert(item_count->new UIntPtr('#10;
        m += '    uint64(Marshal.Sizeof&<T>)*UInt32(item_count)'#10;
        m += '  )));'#10;
        m += 'end;'#10;
      end;
      n += '    ';
      all += #10;
      
      var WriteLike := procedure(tnick, tname: string)->
      begin
        
        n += '    public static function Like';
        n += tnick;
        n += '<T>(a: CommandQueue<';
        n += tname;
        n += '>): ';
        n += wr_local.class_name;
        n += '; where T: record;'#10;
        n += '    begin Result := FromItemCount&<T>(a.ThenConstConvert(a->a.Length)) end;'#10;
        
        n += '    public static function Like';
        n += tnick;
        n += '<T>(a: ';
        n += tname;
        n += '): ';
        n += wr_local.class_name;
        n += '; where T: record;'#10;
        n += '    begin Result := FromItemCount&<T>(a.Length) end;'#10;
        
        n += '    '#10;
      end;
      var WriteLikeS := procedure(name: string)->WriteLike(name, name+'<T>');
      
      WriteLike('Array', 'array of T');
      WriteLike('Array2', 'array[,] of T');
      WriteLike('Array3', 'array[,,] of T');
      
      WriteLikeS('NativeArrayArea');
      WriteLikeS('NativeArray');
      WriteLikeS('CLArray');
      
    end;
    
    {$endregion Local}
    
    KATypeWriter.CloseAll;
  except
    on e: Exception do ErrOtp(e);
  end;
end.