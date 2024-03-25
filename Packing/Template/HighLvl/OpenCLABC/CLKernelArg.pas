﻿uses '../../../../POCGL_Utils';
uses '../../../../Utils/Fixers';
uses '../../../../Utils/CodeGen';

uses '../../Common/PackingUtils';

type
  FromMethodSettings = record
    public inp_nick, par_name, inp_tname: string;
    public gen, need_ccq: boolean;
    
    public constructor(inp_nick, par_name, inp_tname: string; gen, need_ccq: boolean);
    begin
      self.inp_nick   := inp_nick;
      self.par_name   := par_name;
      self.inp_tname  := inp_tname;
      self.gen        := gen;
      self.need_ccq   := need_ccq;
    end;
    
    // private
    public setter_set_pars := default(string);
    
    // generic
    public redirect_to := default(string);
    
    public function DefineGlobal: FromMethodSettings;
    begin
      Result := self;
    end;
    public function DefinePrivate(setter_set_pars: string): FromMethodSettings;
    begin
      Result := self;
      Result.setter_set_pars := setter_set_pars;
    end;
    public function DefineGeneric(redirect_to: string): FromMethodSettings;
    begin
      Result := self;
      Result.redirect_to := redirect_to;
    end;
    
    public property IsGlobalOrConst: boolean read not IsPrivate and not IsGeneric;
    public property IsPrivate: boolean read setter_set_pars<>nil;
    public property IsGeneric: boolean read redirect_to<>nil;
    
    public property NeedContextPar: boolean read IsGeneric and not need_ccq and ('Private' not in redirect_to);
    
  end;
  
  KATypeWriter = record
    public n,m, all, t: Writer;
    public class_name := default(string);
    
    {$region Init/Close}
    
    private static dir := GetFullPathRTA('CLKernelArg');
    private static container := default(KATypeWriter);
    static constructor;
    begin
      container.n := WriterEmpty.Instance;
      container.m := WriterEmpty.Instance;
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
      self.t := new FileWriter(GetFullPath(tname??'All', 'Tests/Exec/CLABC/03#ToString/12#CLKernelArg'));
      
      loop 3 do
      begin
        n += '  ';
        if tname<>nil then
          n += '  ';
        all += #10;
        t += #10;
      end;
      
      if tname=nil then exit;
      named.Add(self);
      
      var class_name := if tname<>'Generic' then
        $'CLKernelArg{tname}' else $'CLKernelArg';
      self.class_name := class_name;
      
      container.WriteReg(1, tname, ()->
      begin
        
        container.n += '  ';
        container.n += class_name;
        container.n += ' = abstract partial class';
        if tname<>'Generic' then
          container.n += '(CLKernelArg)';
        container.n += #10;
        container.n += '    '#10;
        
        container.n += '    ';
        container.all += '{%';
        container.all += tname;
        container.all += '/';
        container.n += 'interface';
        container.m += 'implementation';
        container.all += '%}';
        container.all += #10;
        container.n += '    ';
        container.all += #10;
        
        container.n += '  end;'#10;
        container.n += '  '#10;
        
        container.t += '{$include ';
        container.t += tname;
        container.t += '}'#10;
        
      end);
      
    end;
    
    private constructor(w1, w2: KATypeWriter);
    begin
      self.n := w1.n*w2.n;
      self.m := w1.m*w2.m;
      self.all := n*m;
      self.t := w1.t*w2.t;
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
      wr_and_cont .t +=       #10;
      
      wr_and_cont.all.Close;
      wr_and_cont.t.Close;
    end;
    
    {$endregion Init/Close}
    
    public procedure WriteReg(tab: integer; rname: string; act: ()->());
    begin
      loop tab do n += '  ';
      all += '{$region ';
      all += rname;
      all += '}'#10;
      loop tab do n += '  ';
      all += #10;
      
      t += 'TestRange(''';
      t += rname;
      t += ''', ()->'#10;
      t += 'begin'#10;
      
      act();
      
      t += 'end);'#10;
      
      loop tab do n += '  ';
      all += '{$endregion ';
      all += rname;
      all += '}'#10;
      loop tab do n += '  ';
      all += #10;
    end;
    
    public procedure WriteFrom(s: FromMethodSettings) :=
    WriteReg(2, s.inp_nick, ()->
    begin
      
      {$region Misc write's}
      
      var write_inp_t := procedure(wr: Writer; wrap: string)->
      begin
        if wrap<>nil then
        begin
          wr += wrap;
          wr += '<';
        end;
        if s.inp_tname=nil then
        begin
          if s.gen then wr += 'T' else
            raise new System.InvalidOperationException;
        end else
        begin
          wr += s.inp_tname;
          if s.gen then wr += if s.inp_tname.StartsWith('array') then
            ' of T' else '<T>';
        end;
        if wrap<>nil then wr += '>';
      end;
      
      var write_pars_def := procedure(wr, def_val_wr: Writer; wrap: string)->
      begin
        wr += '(';
        wr += s.par_name;
        wr += ': ';
        write_inp_t(wr, wrap);
        wr += ')';
      end;
      var write_pars_call := procedure(wr: Writer)->
      begin
        wr += '(';
        wr += s.par_name;
        wr += ')';
      end;
      
      {$endregion Misc write's}
      
      // global/constant/private
      if not s.IsGeneric then
      begin
        m += 'type'#10;
        
        {$region Setter}
        
        var write_setter_name := procedure->
        begin
          m += class_name;
          m += 'Setter';
          m += s.inp_nick;
          if s.gen then
            m += '<T>';
        end;
        
        // private
        if s.IsPrivate then
        begin
          m += '  ';
          write_setter_name;
          m += ' = sealed class(';
          write_inp_t(m, 'CLKernelArgSetterTyped');
          m += ')'#10;
          if s.gen then
            m += '  where T: record;'#10;
          m += '    '#10;
          
          m += '    public procedure ApplyImpl(k: cl_kernel; ind: UInt32); override :='#10;
          m += '    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, ';
          m += s.setter_set_pars.Replace('%', 'self.o');
          m += ') );'#10;
          m += '    '#10;
          
          m += '  end;'#10;
        end;
        
        {$endregion Setter}
        
        {$region Arg}
        
        var write_data_tname := procedure->
        begin
          m += class_name;
          write_inp_t(m, 'Common');
        end;
        
        m += '  ';
        m += class_name;
        m += s.inp_nick;
        if s.gen then
          m += '<T>';
        m += ' = sealed class(';
        m += class_name;
        m += ')'#10;
        if s.gen then
          m += '  where T: record;'#10;
        
        m += '    private data: ';
        write_data_tname;
        m += ';'#10;
        m += '    '#10;
        
        if s.gen and s.IsPrivate then
        begin
          m += '    static constructor := BlittableHelper.RaiseIfBad(typeof(T), $''%Err:Blittable:Source:';
          m += class_name;
          m += ':';
          m += s.inp_nick;
          m += '%'');'#10;
          m += '    '#10;
        end;
        
        m += '    public constructor';
        write_pars_def(m, WriterEmpty.Instance, 'CommandQueue');
        m += ' :='#10;
        m += '    data := new ';
        write_data_tname;
        write_pars_call(m);
        m += ';'#10;
        m += '    '#10;
        
        if s.IsGlobalOrConst then
        begin
          m += '    private static function WrapToNative(o: ';
          write_inp_t(m, nil);
          m += ') := o.Native;'#10;
          m += '    '#10;
        end;
        
        m += '    protected function TryGetConstSetter: CLKernelArgSetter; override :='#10;
        m += '    ';
        if s.IsGlobalOrConst then
          m += 'data.TryGetConstSetter(WrapToNative);'#10 else
        if s.IsPrivate then
        begin
          m += 'if data.q is ';
          write_inp_t(m, 'ConstQueue');
          m += '(var c_q) then'#10;
          m += '      new ';
          write_setter_name;
          m += '(c_q.Value) else nil;'#10;
        end else
          raise new System.NotImplementedException;
        m += '    '#10;
        
        m += '    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueue>); override :='#10;
        m += '    data.q.InitBeforeInvoke(g, inited_hubs);'#10;
        m += '    '#10;
        
        m += '    protected function Invoke(inv: CLTaskBranchInvoker; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<CLKernelArgSetter, EventList>; override :='#10;
        m += '    data.Invoke(';
        if s.IsGlobalOrConst then
          m += 'inv, WrapToNative' else
        if s.IsPrivate then
        begin
          m += 'inv, o->new ';
          write_setter_name;
          m += '(o), ()->new ';
          write_setter_name;
        end else
          raise new System.NotImplementedException;
        m += ', par_err_handlers);'#10;
        m += '    '#10;
        
        m += '    protected procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :='#10;
        m += '    data.ToString(sb, tabs, index, delayed);'#10;
        m += '    '#10;
        
        m += '  end;'#10;
        
        {$endregion Arg}
        
        m += '  '#10;
      end;
      
      n += '    public ';
      all += 'static function ';
      m += class_name;
      m += '.';
      all += 'From';
      all += s.inp_nick;
      if s.gen then all += '<T>';
      write_pars_def(all,n, s.NeedContextPar?nil:'CommandQueue');
      all += ': ';
      all += class_name;
      all += ';';
      if s.gen then all += ' where T: record;';
      all += #10;
      
      t += 'Test(';
      t += class_name;
      t += '.From';
      t += s.inp_nick;
      t += '(';
      if not s.NeedContextPar then t += 'CQ(';
      t += s.par_name;
      if not s.NeedContextPar then t += ')';
      t += '));'#10;
      
      m += 'begin Result := ';
      if s.redirect_to=nil then
      begin
        m += 'new ';
        m += class_name;
        m += s.inp_nick;
        if s.gen then m += '<T>';
      end else
      begin
        m += s.redirect_to;
        m += '.From';
        m += s.inp_nick;
      end;
      write_pars_call(m);
      m += ' end;'#10;
      
      if not s.NeedContextPar then
      begin
        
        foreach var wrap in |nil, 'CommandQueue', 'ConstQueue', 'ParameterQueue'| do
        begin
          
          n += '    public static function operator implicit';
          if s.gen then n += '<T>';
          n += '(';
          n += s.par_name;
          n += ': ';
          write_inp_t(n, wrap);
          n += '): ';
          n += class_name;
          n += ';';
          if s.gen then n += ' where T: record;';
          n += #10;
          n += '    begin Result := From';
          n += s.inp_nick;
          if s.gen then n += '&<T>';
          n += '(';
          n += s.par_name;
          n += ') end;'#10;
          
          t += 'TestT&<';
          t += class_name;
          t += '>(';
          if wrap<>nil then
          begin
            if wrap='CommandQueue' then
              t += 'CQ' else
            begin
              t += 'new ';
              write_inp_t(t, wrap);
            end;
            t += '(';
          end;
          if wrap='ParameterQueue' then
          begin
            t += '''';
            t += s.par_name;
            t += ''', ';
          end;
          t += s.par_name;
          if wrap<>nil then t += ')';
          t += ');'#10;
          
        end;
      
        if s.need_ccq then
        begin
          
          n += '    public ';
          all += 'static function ';
          m += class_name;
          m += '.';
          all += 'operator implicit';
          if s.gen then all += '<T>';
          all += '(';
          all += s.par_name;
          all += ': ';
          all += s.inp_tname;
          all += 'CCQ';
          if s.gen then all += '<T>';
          all += '): ';
          all += class_name;
          all += ';';
          if s.gen then all += ' where T: record;';
          all += #10;
          m += 'begin Result := From';
          m += s.inp_nick;
          m += '(';
          m += s.par_name;
          m += ') end;'#10;
          
          t += 'TestT&<';
          t += class_name;
          t += '>(';
          t += s.par_name;
          t += '.MakeCCQ);'#10;
          
        end;
        
      end;
      
      n += '    ';
      all += #10;
    end);
    
  end;
  
begin
  try
    var wr_global   := new KATypeWriter('Global');
    var wr_constant := new KATypeWriter('Constant');
    var wr_local    := new KATypeWriter('Local');
    var wr_private  := new KATypeWriter('Private');
    var wr_generic  := new KATypeWriter('Generic');
    
    var WriteGlobalConstantFrom := procedure(s: FromMethodSettings)->
    begin
      wr_global   .WriteFrom(s.DefineGlobal);
      wr_constant .WriteFrom(s.DefineGlobal);
    end;
    
    
    
    (wr_private*wr_generic).WriteReg(2, 'Managed', ()->
    begin
      
      for var dim := 1 to 3 do
      begin
        var s := new FromMethodSettings('Array', 'a', 'array', true, false);
        if dim<>1 then s.inp_nick += dim.ToString;
        if dim<>1 then s.par_name += dim.ToString;
        if dim<>1 then s.inp_tname += '[' + ','*(dim-1) + ']';
        
        var cl_pars := 'new UIntPtr(UInt32(%.Length)*uint64(Marshal.SizeOf(default(T)))), %['+SeqFill(dim,'0').JoinToString(',') + ']';
        
        wr_private.WriteFrom(s.DefinePrivate(cl_pars));
        wr_generic.WriteFrom(s.DefineGeneric(wr_private.class_name));
        
      end;
      
      begin
        var s := FromMethodSettings.Create('ArraySegment', 'seg', 'ArraySegment', true, false);
        
        var cl_pars := 'new UIntPtr(UInt32(%.Count)*uint64(Marshal.SizeOf(default(T)))), %.Array[%.Offset]';
        
        wr_private.WriteFrom(s.DefinePrivate(cl_pars));
        wr_generic.WriteFrom(s.DefineGeneric(wr_private.class_name));
        
      end;
      
    end);
    
    
    
    foreach var area in |'Area',nil| do (wr_private*wr_generic).WriteReg(2, 'Native'+area, ()->
    begin
      
      foreach var t in |'Memory','Value','Array'| do
      begin
        var full_t := 'Native'+t+area;
        var par_name := 'ntv_'+t.Remove(3).ToLower; if area<>nil then par_name += '_area';
        var s := new FromMethodSettings(full_t, par_name, full_t, t<>'Memory', false);
        
        var area_ref := $'%';
        if area=nil then area_ref += '.Area';
        
        var ptr_ref := if t='Array' then 'first_ptr' else 'ptr';
        var sz_ref := if t='Memory' then 'sz' else 'ByteSize';
        
        var cl_pars := $'{area_ref}.{sz_ref}, {area_ref}.{ptr_ref}';
        
        wr_private.WriteFrom(s.DefinePrivate(cl_pars));
        wr_generic.WriteFrom(s.DefineGeneric(wr_private.class_name));
        
      end;
      
    end);
    
    
    
    (wr_global*wr_constant*wr_generic).WriteReg(2, 'CL', ()->
    begin
      
      foreach var t in |'Memory','Value','Array'| do
      begin
        var full_t := 'CL'+t;
        var par_name := 'cl_'+t.Remove(3).ToLower;
        var s := new FromMethodSettings(full_t, par_name, full_t, t<>'Memory', true);
        
        WriteGlobalConstantFrom(s);
        wr_generic  .WriteFrom(s.DefineGeneric(wr_global.class_name));
        
      end;
      
    end);
    
    //TODO #3054: Как исправят - перенести в начало [Managed]
    begin
      var s := FromMethodSettings.Create('Value', 'val', nil, true, false);
      
      wr_private.WriteFrom(s.DefinePrivate('new UIntPtr(Marshal.SizeOf(default(T))), %'));
      wr_generic.WriteFrom(s.DefineGeneric(wr_private.class_name));
      
    end;
    
    
    
    {$region Local}
    
    wr_local.WriteReg(2, 'FromBytes', ()->
    begin
      
      foreach var dt in |nil, 'UInt32', 'Int32', 'UInt64', 'Int64'| do
      begin
        var n := wr_local.n;
        var m := if dt=nil then wr_local.m else WriterEmpty.Instance;
        var all := n*m;
        var t := wr_local.t;
        
        n += '    public ';
        all += 'static function ';
        m += wr_local.class_name;
        m += '.';
        all += 'FromBytes(bytes: CommandQueue<';
        all += dt ?? 'UIntPtr';
        all += '>)';
        
        t += 'Test(';
        t += wr_local.class_name;
        t += '.FromBytes(';
        t += dt ?? 'new UIntPtr';
        t += '(123)));'#10;
        t += 'Test(';
        t += wr_local.class_name;
        t += '.FromBytes(HFQ(()->';
        t += dt ?? 'new UIntPtr';
        t += '(123), false)));'#10;
        
        if dt=nil then
        begin
          n += ': ';
          n += wr_local.class_name;
          n += ';'#10;
          
          m += ' := new ';
          m += wr_local.class_name;
          m += 'Bytes(bytes);'#10;
        end else
          n += ' := FromBytes(bytes.ThenConvert(bytes->new UIntPtr(bytes), false,true));'#10;
        
      end;
      
      wr_local.n += '    ';
      wr_local.all += #10;
    end);
    
    wr_local.WriteReg(2, 'FromItemCount', ()->
    begin
      var n := wr_local.n;
      var m := wr_local.m;
      var all := n*m;
      var t := wr_local.t;
      
      foreach var dt in |'UInt32','Int32'| do
      begin
        n += '    public ';
        all += 'static function ';
        m += wr_local.class_name;
        m += '.';
        all += 'FromItemCount<T>(item_count: CommandQueue<';
        all += dt;
        all += '>): ';
        all += wr_local.class_name;
        all += '; where T: record;'#10;
        
        t += 'Test(';
        t += wr_local.class_name;
        t += '.FromItemCount&<integer>(';
        t += dt;
        t += '(64)));'#10;
        t += 'Test(';
        t += wr_local.class_name;
        t += '.FromItemCount&<integer>(HFQ&<';
        t += dt;
        t += '>(()->64, false)));'#10;
        
        m += 'begin'#10;
        m += '  BlittableHelper.RaiseIfBad(typeof(T), ''%Err:Blittable:Source:';
        m += wr_local.class_name;
        m += ':ItemCount%'');'#10;
        m += '  Result := FromBytes(item_count.ThenConvert(item_count->new UIntPtr('#10;
        m += '    uint64(Marshal.Sizeof(default(T)))*UInt32(item_count)'#10;
        m += '  ), false,true));'#10;
        m += 'end;'#10;
      end;
      n += '    ';
      all += #10;
      
    end);
    
    wr_local.WriteReg(2, 'LikeArray', ()->
    begin
      var n := wr_local.n;
      var t := wr_local.t;
      
      var WriteLike := procedure(tnick, par_name, tname: string)->
      begin
        
        n += '    public static function Like';
        n += tnick;
        n += '<T>(a: CommandQueue<';
        n += tname;
        n += '>): ';
        n += wr_local.class_name;
        n += '; where T: record;'#10;
        n += '    begin Result := FromItemCount&<T>(a.ThenConvert(a->a.Length, false,true)) end;'#10;
        
        n += '    public static function Like';
        n += tnick;
        n += '<T>(a: ';
        n += tname;
        n += '): ';
        n += wr_local.class_name;
        n += '; where T: record;'#10;
        n += '    begin Result := FromItemCount&<T>(a.Length) end;'#10;
        
        t += 'Test(';
        t += wr_local.class_name;
        t += '.Like';
        t += tnick;
        t += '(';
        t += par_name;
        t += '));'#10;
        
        t += 'Test(';
        t += wr_local.class_name;
        t += '.Like';
        t += tnick;
        t += '(HFQ(()->';
        t += par_name;
        t += ', false)));'#10;
        
        n += '    '#10;
      end;
      var WriteLikeS := procedure(name, par_name: string)->WriteLike(name, par_name, name+'<T>');
      
      WriteLike('Array',  'a',  'array of T');
      WriteLike('Array2', 'a2', 'array[,] of T');
      WriteLike('Array3', 'a3', 'array[,,] of T');
      
      WriteLikeS('NativeArrayArea', 'ntv_arr_area');
      WriteLikeS('NativeArray',     'ntv_arr');
      WriteLikeS('CLArray',         'cl_arr');
      
    end);
    
    {$endregion Local}
    
    
    
    KATypeWriter.CloseAll;
  except
    on e: Exception do ErrOtp(e);
  end;
end.