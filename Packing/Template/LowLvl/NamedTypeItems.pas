unit NamedTypeItems;

{$zerobasedstrings}

interface

uses System;

uses '../../../POCGL_Utils';
uses '../../../Utils/AOtp';
uses '../../../Utils/Fixers';
uses '../../../Utils/CodeGen';

uses '../../../DataScraping/BinCommon';

uses '../Common/PackingUtils';

uses LLPackingUtils;
uses ItemNames;
uses TypeRefering;
uses BinUtils;

uses NamedItemHelpers;
uses NamedItemBase;
uses NamedItemFixerBase;

uses EnumItems;
uses ParData;

type
  
  {$region LoadedBasicType}
  
  LoadedBasicType = sealed class(NamedLoadedItem<LoadedBasicType, string>, ILoadedNamedType)
    private d_ptr: integer;
    private additional_readonly_lvls: array of integer;
    private converted_type_name := default(string);
    
    private static UnusedTypeConv: HashSet<string>;
    static constructor;
    begin
      TypeLookup.RegisterIndexDerefFunc(TRK_Basic, inherited ByIndex);
      
      var conv := new Dictionary<string, string>;
      foreach var l in ReadLines(GetFullPathRTA($'MiscInput/TypeTable.dat')) do
      begin
        var s := l.Split('=');
        if s.Length<2 then continue;
        conv.Add(s[0].Trim,s[1].Trim);
      end;
      UnusedTypeConv := conv.Keys.ToHashSet;
      
      RegisterLoader(br->
      begin
        var loaded_tname := br.ReadString;
        
        var conv_s: string;
        if not conv.TryGetValue(loaded_tname, conv_s) then
        begin
          Otp($'ERROR: No converter for {loaded_tname}');
          Result := new LoadedBasicType(loaded_tname, false);
          exit;
        end;
        if not UnusedTypeConv.Remove(loaded_tname) then
          raise new InvalidOperationException;
        
        var add_ptr := conv_s.CountOf('*');
        var rem_ptr := conv_s.CountOf('-');
        if (add_ptr<>0) and (rem_ptr<>0) then
          raise new InvalidOperationException(conv_s);
        
        Result := new LoadedBasicType(loaded_tname, false);
        Result.d_ptr := add_ptr-rem_ptr;
        if add_ptr<>0 then
        begin
          Result.additional_readonly_lvls := System.Array.Empty&<integer>;
          
          if conv_s.StartsWith('const') then
          begin
            conv_s := conv_s.Substring('const'.Length).TrimStart;
            Result.additional_readonly_lvls := |add_ptr|;
          end;
          
        end;
        
        Result.converted_type_name := conv_s.Remove('*','-').Trim;
      end);
      
    end;
    
    public static procedure ReportAllUnusedTypeConverters :=
      foreach var t in UnusedTypeConv do
        Otp($'WARNING: Type converter for [{t}] was not used');
    
    public function IsVoid: boolean;
    begin
      Result := converted_type_name='void';
      if Result then
      begin
        if d_ptr<>0 then raise new InvalidOperationException;
        if additional_readonly_lvls<>nil then raise new InvalidOperationException;
      end;
    end;
    
    public function FeedToTypeTable: System.ValueTuple<integer, array of integer, IDirectNamedType>;
    begin
      if converted_type_name=nil then
        raise new NotImplementedException($'No converter for {self.Name}');
      self.Use(false);
      Result := ValueTuple.Create(d_ptr, additional_readonly_lvls, TypeLookup.FromNameString(converted_type_name));
    end;
    
    public procedure MarkBodyReferenced; override := exit;
    
  end;
  
  LoadedBasicTypeFixer = abstract class(NamedItemFixer<LoadedBasicTypeFixer, LoadedBasicType, string>)
    
  end;
  
  {$endregion LoadedBasicType}
  
  {$region PascalBasicType}
  
  PascalBasicType = sealed class(NamedItem<PascalBasicType, string>, IDirectNamedType)
    
    public constructor(name: string) :=
      inherited Create(name, true);
    
    public static function FindOrMake(name: string): PascalBasicType;
    begin
      Result := inherited ByName(name);
      if Result<>nil then exit;
      Result := new PascalBasicType(name);
      if Result.IsInternalOnly then
        Result.Use(false);
    end;
    
    private static name_to_size := new Dictionary<string, integer>;
    
    static constructor;
    begin
      
      begin
        var type_sizes_fname := GetFullPathRTA('MiscInput/TypeSizes.dat');
        if FileExists(type_sizes_fname) then
          foreach var (sz_str, tnames) in FixerUtils.ReadBlocks(type_sizes_fname, false) do
          begin
            var sz := sz_str.ToInteger;
            foreach var tname in tnames do
              name_to_size.Add(tname, sz);
          end;
      end;
      
      TypeLookup.RegisterNameLookupFunc(FindOrMake);
      TypeComboName.RegisterBTUseProc(name->
      begin
        var t := inherited ByName(name);
        if t=nil then raise new InvalidOperationException;
      end);
      
    end;
    
    public function ToString: string; override := self.Name;
    
    public function ByteSize: integer;
    begin
      if name_to_size.TryGetValue(self.Name, Result) then exit;
      raise new MessageException($'ERROR: No size defined for {self}');
    end;
    
    public procedure MarkBodyReferenced; override := exit;
    
    //TODO mono#11034
    function {IWritableNamedItem.}MakeWriteProc: NamedItemWriteProc;
    begin
      Result := (prev, intr_wr, impl_wr)->exit();
    end;
    
    protected procedure LogContents(l: Logger); override;
    begin
      if self.IsInternalOnly then exit;
      l.Otp($'# {self.Name}');
      l.Otp($'');
    end;
    
    public function IsInternalOnly := self.Name in |'void', 'ntv_char'{, 'DISABLED_TYPE'}|;
    //TODO mono#11034
    function {IDirectNamedType.}GetTypeOrder := FPTO_Basic;
    function {IDirectNamedType.}GetRawName: object := self.Name;
    function {IDirectNamedType.}MakeWriteableName: string;
    begin
      if self.IsInternalOnly then
        raise new InvalidOperationException;
      Result := self.Name;
    end;
    
  end;
  
  PascalBasicTypeFixer = abstract class(NamedItemFixer<PascalBasicTypeFixer, PascalBasicType, string>)
    
  end;
  
  {$endregion PascalBasicType}
  
  {$region TypeCombo}
  
  TypeCombo = sealed class(NamedItem<TypeCombo, TypeComboName>, IDirectNamedType)
    
    private row_type := default(TypeCombo);
    private col_type := default(TypeCombo);
    private tsp_type := default(TypeCombo);
    public constructor(name: TypeComboName);
    begin
      inherited Create(name, true);
      if name.IsMatrix then
      begin
        row_type := FindOrMake(name.MatrixRowTypeName);
        col_type := FindOrMake(name.MatrixColTypeName);
        tsp_type := FindOrMake(name.MatrixTransposedTypeName);
      end;
    end;
    
    public static function FindOrMake(name: TypeComboName): TypeCombo;
    begin
      Result := inherited ByName(name);
      if Result<>nil then exit;
      if name.IsLookupOnly then exit;
      Result := new TypeCombo(name);
    end;
    
    static constructor;
    begin
      TypeLookup.RegisterNameLookupFunc(FindOrMake);
    end;
    
    public function ToString: string; override :=
      $'{TypeName(self)} [{self.Name.ToString(false)}]';
    
    public procedure MarkBodyReferenced; override;
    begin
      if name.IsMatrix then
      begin
        row_type.Use(false);
        col_type.Use(false);
        tsp_type.Use(false);
      end;
    end;
    
    //TODO mono#11034
    function {IDirectNamedType.}IsInternalOnly := false;
    function {IDirectNamedType.}GetTypeOrder := FPTO_Combo;
    function {IDirectNamedType.}GetRawName: object := self.Name.ToString;
    function {IDirectNamedType.}MakeWriteableName := self.Name.ToString(true);
    
    {$region Writes}
    
    {$region Utils}
    
    private procedure NameConditional(on_vec: integer->(); on_mtr: (integer,integer)->()) :=
      if Name.IsVector then
      begin
        var sz := self.Name.VectorSize;
        on_vec(sz);
      end else
      if Name.IsMatrix then
      begin
        var (sz1,sz2) := self.Name.MatrixSizes;
        on_mtr(sz1,sz2);
      end else
        raise new InvalidOperationException;
    
    private procedure WriteCase(wr: Writer; sz: integer; ind_name: string; on_case: integer->());
    begin
      wr += '      case ';
      wr += ind_name;
      wr += ' of'#10;
      
      for var i := 0 to sz-1 do
      begin
        wr += '        ';
        wr += i;
        wr += ': ';
        on_case(i);
        wr += ';'#10;
      end;
      
      //TODO Use %% syntax to insert text
      wr += '        else raise new IndexOutOfRangeException($''Индекс "';
      wr += if Name.IsVector then
        '{ind_name}' else ind_name;
      wr += '" должен иметь значение 0..';
      wr += sz-1;
      wr += ''');'#10;
      
      wr += '      end;'#10;
    end;
    
    {$endregion Utils}
    
    {$region field's}
    
    private procedure WriteFields(wr: Writer);
    begin
      NameConditional(
        sz->
          for var i := 0 to sz-1 do
          begin
            wr += '    public val';
            wr += i;
            wr += ': ';
            wr += Name.OriginalType;
            wr += ';'#10;
          end,
        (sz1,sz2)->
          for var col_i := 0 to sz2-1 do
          begin
            wr += '    public ';
            wr.WriteNumbered(sz1,
              (wr,row_i)->
              begin
                wr += 'val';
                wr += row_i;
                wr += col_i;
              end,
              (wr,row_i)->(wr += ', '),
              0
            );
            wr += ': ';
            wr += Name.OriginalType;
            wr += ';'#10;
          end
      );
      wr += '    '#10;
    end;
    
    {$endregion field's}
    
    {$region constructor}
    
    private procedure WriteConstructor(wr: Writer);
    begin
      wr += '    public constructor(';
      NameConditional(
        sz->wr.WriteNumbered(sz,
          (wr,i)->
          begin
            wr += 'val';
            wr += i;
          end,
          (wr,i)->(wr += ', '),
          0
        ),
        (sz1,sz2)->wr.WriteNumbered(sz1,
          (wr,row_i)->wr.WriteNumbered(sz2,
            (wr,col_i)->
            begin
              wr += 'val';
              wr += row_i;
              wr += col_i;
            end,
            (wr,col_i)->(wr += ', '),
            0
          ),
          (wr,row_i)->(wr += ', '),
          0
        )
      );
      wr += ': ';
      wr += Name.OriginalType;
      wr += ');'#10;
      
      wr += '    begin'#10;
      
      NameConditional(
        sz->
          for var i := 0 to sz-1 do
          begin
            wr += '      self.val';
            wr += i;
            wr += ' := val';
            wr += i;
            wr += ';'#10;
          end,
        (sz1,sz2)->
          for var row_i := 0 to sz1-1 do
          begin
            wr += '      ';
            wr.WriteNumbered(sz2,
              (wr,col_i)->
              begin
                wr += 'self.val';
                wr += row_i;
                wr += col_i;
                wr += ' := val';
                wr += row_i;
                wr += col_i;
              end,
              (wr,col_i)->(wr += '; '),
              0
            );
            wr += ';'#10;
          end
      );
      
      wr += '    end;'#10;
      wr += '    '#10;
    end;
    
    {$endregion constructor}
    
    {$region IO}
    
    private procedure WriteIO(wr: Writer; res_tname: string);
    begin
      
      {$region VT Conv ops}
      NameConditional(
        sz->
        begin
          var write_vt_type := ()->
          begin
            wr += 'ValueTuple<';
            wr.WriteNumbered(sz,
              (wr,i)->(wr += Name.OriginalType),
              (wr,i)->(wr += ', ')
            );
            wr += '>';
          end;
          
          wr += '    public static function operator implicit(vt: ';
          write_vt_type;
          wr += '): ';
          wr += res_tname;
          wr += ' := new ';
          wr += res_tname;
          wr += '(';
          wr.WriteNumbered(sz,
            (wr,i)->
            begin
              wr += 'vt.Item';
              wr += i;
            end,
            (wr,i)->(wr += ', '),
            1
          );
          wr += ');'#10;
          
          wr += '    public static function operator implicit(v: ';
          wr += res_tname;
          wr += '): ';
          write_vt_type;
          wr += ' := ValueTuple.Create(';
          wr.WriteNumbered(sz,
            (wr,i)->
            begin
              wr += 'v.val';
              wr += i;
            end,
            (wr,i)->(wr += ', '),
            0
          );
          wr += ');'#10;
          
          wr += '    '#10;
        end,
        (sz1,sz2)->exit()
      );
      {$endregion VT Conv ops}
      
      {$region Gen}
      foreach var gen_t in if Name.IsVector then |''| else |'Unordered','ByRow','ByCol'| do
      begin
        
        var inds_str := default(string);
        case gen_t of
          '':
            inds_str := 'i';
          'Unordered':
            inds_str := 'row_i, col_i';
          'ByRow':
            inds_str := 'row_i';
          'ByCol':
            inds_str := 'col_i';
          else raise new NotImplementedException(gen_t);
        end;
        
        var gen_tname := default(string);
        case gen_t of
          '', 'Unordered':
            gen_tname := Name.OriginalType;
          'ByRow':
            gen_tname := row_type.Name.ToString(nil);
          'ByCol':
            gen_tname := col_type.Name.ToString(nil);
          else raise new NotImplementedException(gen_t);
        end;
        
        wr += '    public static function Generate';
        wr += gen_t;
        wr += '(gen: function(';
        wr += inds_str;
        wr += ': integer): ';
        wr += gen_tname;
        wr += '): ';
        wr += res_tname;
        wr += ' :='#10;
        wr += '      ';
        NameConditional(
          sz->
          begin
            wr += 'new ';
            wr += res_tname;
          end,
          (sz1,sz2)->
          begin
            wr += res_tname;
            wr += if gen_t='ByRow' then
              '.FromRows' else '.FromCols';
          end
        );
        wr += '(';
        NameConditional(
          sz->wr.WriteNumbered(sz,
            (wr,i)->
            begin
              wr += 'gen(';
              wr += i;
              wr += ')';
            end,
            (wr,i)->(wr += ', '),
            0
          ),
          (sz1,sz2)->
            case gen_t of
              '', 'Unordered':
                wr.WriteNumbered(sz2,
                  (wr,col_i)->
                  begin
                    wr += 'new ';
                    wr += col_type.Name.ToString(nil);
                    wr += '(';
                    wr.WriteNumbered(sz1,
                      (wr,row_i)->
                      begin
                        wr += 'gen(';
                        wr += row_i;
                        wr += ',';
                        wr += col_i;
                        wr += ')';
                      end,
                      (wr,row_i)->(wr += ', '),
                      0
                    );
                    wr += ')';
                  end,
                  (wr,col_i)->(wr += ', '),
                  0
                );
              'ByRow':
              begin
                wr.WriteNumbered(sz1,
                  (wr,row_i)->
                  begin
                    wr += 'gen(';
                    wr += row_i;
                    wr += ')';
                  end,
                  (wr,row_i)->(wr += ', '),
                  0
                );
              end;
              'ByCol':
              begin
                wr.WriteNumbered(sz2,
                  (wr,col_i)->
                  begin
                    wr += 'gen(';
                    wr += col_i;
                    wr += ')';
                  end,
                  (wr,col_i)->(wr += ', '),
                  0
                );
              end;
              else raise new NotImplementedException(gen_t);
            end
        );
        wr += ');'#10;
      end;
      wr += '    '#10;
      {$endregion Gen}
      
      {$region Read}
      for var ln := false to true do
      begin
        NameConditional(
          sz->
          begin
            wr += '    public static function Read';
            if ln then
              wr += 'Ln';
            wr += '(prompt: string := nil): ';
            wr += res_tname;
            wr += ';'#10;
            
            wr += '    begin'#10;
            
            wr += '      if prompt<>nil then'#10;
            wr += '        prompt.Print;'#10;
            wr += '      PABCSystem.Read';
            if ln then
              wr += 'Ln';
            wr += '(';
            wr.WriteNumbered(sz,
              (wr,i)->
              begin
                wr += 'Result.val';
                wr += i;
              end,
              (wr,i)->(wr += ', '),
              0
            );
            wr += ');'#10;
            wr += '    end;'#10;
          end,
          (sz1,sz2)->
            foreach var read_dir in |'Row','Col'| do
            begin
              wr += '    public static function Read';
              if ln then
                wr += 'Ln';
              wr += 'By';
              wr += read_dir;
              wr += '(prompt_by_';
              wr += read_dir.ToLower;
              wr += ': function(';
              wr += read_dir.ToLower;
              wr += '_i: integer): string := nil) :='#10;
              wr += '      GenerateBy';
              wr += read_dir;
              wr += '(';
              wr += read_dir.ToLower;
              wr += '_i->';
              case read_dir of
                'Row': wr += row_type.Name.ToString(nil);
                'Col': wr += col_type.Name.ToString(nil);
                else raise new NotImplementedException(read_dir);
              end;
              wr += '.Read';
              if ln then
                wr += 'Ln';
              wr += '(prompt_by_';
              wr += read_dir.ToLower;
              wr += '?.Invoke(';
              wr += read_dir.ToLower;
              wr += '_i)));'#10;
            end
        );
        wr += '    '#10;
      end;
      {$endregion Read}
      
      {$region Random}
      
      wr += '    public static function Random(a, b: ';
      wr += Name.OriginalType;
      wr += '): ';
      wr += res_tname;
      wr += ';'#10;
      
      wr += '    begin'#10;
      
      wr += '      if a>b then Swap(a,b);'#10;
      
      wr += '      var r := b-a';
      if not Name.IsFloat then
        wr += '+1';
      wr += ';'#10;
      
      wr += '      Result := new ';
      wr += res_tname;
      wr += '(';
      wr.WriteNumbered(Name.TotalSize,
        (wr,i)->(wr += 'a+PABCSystem.Random(r)'),
        (wr,i)->(wr += ', ')
      );
      wr += ');'#10;
      
      wr += '    end;'#10;
      
      wr += '    '#10;
      {$endregion Random}
      
      {$region Deconstruct}
      
      {$region val}
      
      wr += '    public procedure Deconstruct(var ';
      NameConditional(
        sz->wr.WriteNumbered(sz,
          (wr,i)->
          begin
            wr += 'val';
            wr += i;
          end,
          (wr,i)->(wr += ', '),
          0
        ),
        (sz1,sz2)->wr.WriteNumbered(sz1,
          (wr,row_i)->wr.WriteNumbered(sz2,
            (wr,col_i)->
            begin
              wr += 'val';
              wr += row_i;
              wr += col_i;
            end,
            (wr,col_i)->(wr += ', '),
            0
          ),
          (wr,row_i)->(wr += ', '),
          0
        )
      );
      wr += ': ';
      wr += Name.OriginalType;
      wr += ');'#10;
      
      wr += '    begin'#10;
      
      NameConditional(
        sz->
          for var i := 0 to sz-1 do
          begin
            wr += '      val';
            wr += i;
            wr += ' := self.val';
            wr += i;
            wr += ';'#10;
          end,
        (sz1,sz2)->
          for var row_i := 0 to sz1-1 do
          begin
            wr += '      ';
            wr.WriteNumbered(sz2,
              (wr,col_i)->
              begin
                wr += 'val';
                wr += row_i;
                wr += col_i;
                wr += ' := self.val';
                wr += row_i;
                wr += col_i;
              end,
              (wr,col_i)->(wr += '; '),
              0
            );
            wr += ';'#10;
          end
      );
      
      wr += '    end;'#10;
      wr += '    '#10;
      
      {$endregion val}
      
      {$region Row/Col}
      
      NameConditional(sz->exit(),
        (sz1,sz2)->
          foreach var (dir,sz,t) in |('Row', sz1, row_type), ('Col', sz2, col_type)| do
          begin
            wr += '    public procedure Deconstruct';
            wr += dir;
            wr += 's(var ';
            wr.WriteNumbered(sz,
              (wr,i)->
              begin
                wr += dir.ToLower;
                wr += i;
              end,
              (wr,i)->(wr += ', '),
              0
            );
            wr += ': ';
            wr += t.Name.ToString(nil);
            wr += ');'#10;
            
            wr += '    begin'#10;
            
            for var i := 0 to sz-1 do
            begin
              wr += '      ';
              wr += dir.ToLower;
              wr += i;
              wr +=' := self.';
              wr += dir;
              wr += i;
              wr += ';'#10;
            end;
            
            wr += '    end;'#10;
            
            if (row_type<>col_type) or (dir='Row') then
            begin
              wr += '    public procedure Deconstruct(var ';
              wr.WriteNumbered(sz,
                (wr,i)->
                begin
                  wr += dir.ToLower;
                  wr += i;
                end,
                (wr,i)->(wr += ', '),
                0
              );
              wr += ': ';
              wr += t.Name.ToString(nil);
              wr += ') := Deconstruct';
              wr += dir;
              wr += 's(';
              wr.WriteNumbered(sz,
                (wr,i)->
                begin
                  wr += dir.ToLower;
                  wr += i;
                end,
                (wr,i)->(wr += ', '),
                0
              );
              wr += ');'#10;
            end;
            
            wr += '    '#10;
          end
      );
      
      {$endregion Row/Col}
      
      {$endregion Deconstruct}
      
      {$region ToString}
      
      wr += '    private static function ValStr(val: ';
      wr += Name.OriginalType;
      wr += '): string;'#10;
      wr += '    begin'#10;
      
      wr += '      Result := val.ToString';
      if Name.IsFloat then
        wr += '(''f2'')';
      wr += ';'#10;
      
      wr += '      if Result.First<>''-'' then'#10;
      wr += '        Result := ''+''+Result;'#10;
      
      wr += '    end;'#10;
      
      wr += '    public function ToString: string; override;'#10;
      
      wr += '    begin'#10;
      
      NameConditional(
        sz->
        begin
          wr += '      var res := new StringBuilder;'#10;
          wr += '      res += ''[ '';'#10;
          wr.WriteNumbered(sz,
            (wr,i)->
            begin
              wr += '      res += ValStr(val';
              wr += i;
              wr += ');';
            end,
            (wr,i)->(wr += ' res += '', '';'#10),
            0
          );
          wr += #10;
          wr += '      res += '' ]'';'#10;
          wr += '      Result := res.ToString;'#10;
        end,
        (sz1,sz2)->
        begin
          // 1.
          //┌─────┐
          //│     │
          //│     │
          //│     │
          //└─────┘
          // 2.
          //╔═════╗
          //║     ║
          //║     ║
          //║     ║
          //╚═════╝
          // 3.
          //╓─────╖
          //║     ║
          //║     ║
          //║     ║
          //╙─────╜
          // Сейчас используется 3, но без горизонтальных линий:
          
          for var col_i := 0 to sz2-1 do
          begin
            wr += '      ';
            for var row_i := 0 to sz1-1 do
            begin
              wr += 'var s';
              wr += row_i;
              wr += col_i;
              wr += ' := ValStr(val';
              wr += row_i;
              wr += col_i;
              wr += '); ';
              if not Name.IsFloat then
                raise new NotSupportedException;
            end;
            wr += 'var col_sz';
            wr += col_i;
            wr += ' := s0';
            wr += col_i;
            wr += '.Length';
            for var row_i := 1 to sz1-1 do
            begin
              wr += '.ClampBottom(s';
              wr += row_i;
              wr += col_i;
              wr += '.Length)';
            end;
            wr += ';'#10;
          end;
          
          wr += '      var total_w := ';
          wr += 2*sz2;
          wr += '; // 2*(ColCount-1) + 2'#10;
          for var col_i := 0 to sz2-1 do
          begin
            wr += '      total_w += col_sz';
            wr += col_i;
            wr += ';'#10;
          end;
          
          wr += '      var res := new StringBuilder;'#10;
          
          wr += '      res += ''╓'';'#10;
          wr += '      res.Append('' '', total_w);'#10;
          wr += '      res += ''╖''#10;'#10;
          
          for var row_i := 0 to sz1-1 do
          begin
            wr += '      res += ''║ '';'#10;
            wr.WriteNumbered(sz2,
              (wr,col_i)->
              begin
                wr += '      res.Append('' '', col_sz';
                wr += col_i;
                wr += ' - s';
                wr += row_i;
                wr += col_i;
                wr += '.Length); res += s';
                wr += row_i;
                wr += col_i;
                wr += ';';
              end,
              (wr,col_i)->(wr += ' res += '', '';'#10),
              0
            );
            wr += #10;
            wr += '      res += '' ║''#10;'#10;
          end;
          
          wr += '      res += ''╙'';'#10;
          wr += '      res.Append('' '', total_w);'#10;
          wr += '      res += ''╜'';'#10;
          
          wr += '      Result := res.ToString;'#10;
        end
      );
      
      wr += '    end;'#10;
      
      wr += '    '#10;
      {$endregion ToString}
      
      {$region Print}
      for var ln := false to true do
      begin
        if Name.IsMatrix and not ln then continue;
        
        wr += '    public function Print';
        if ln then
          wr += 'Ln';
        wr += ': ';
        wr += res_tname;
        wr += ';'#10;
        
        wr += '    begin'#10;
        
        wr += '      ';
        wr += if ln then
          'Writeln' else 'PABCSystem.Print';
        wr += '(self.ToString);'#10;
        
        wr += '      Result := self;'#10;
        
        wr += '    end;'#10;
        
        wr += '    '#10;
      end;
      {$endregion Print}
      
    end;
    
    {$endregion IO}
    
    {$region Identity}
    
    private procedure WriteIdentity(wr: Writer; res_tname: string; sz1,sz2: integer);
    begin
      
      wr += '    public static property Identity: ';
      wr += res_tname;
      wr += ' read'#10;
      wr += '      new ';
      wr += res_tname;
      wr += '(';
      wr.WriteNumbered(sz1,
        (wr,row_i)->wr.WriteNumbered(sz2,
          (wr,col_i)->(wr+=Ord(row_i=col_i)),
          (wr,col_i)->(wr+=', ')
        ),
        (wr,row_i)->(wr+=', ')
      );
      wr += ');'#10;
      
      if sz1<>sz2 then
      begin
        wr += '    public static property IdentityKeepLast: ';
        wr += res_tname;
        wr += ' read'#10;
        wr += '      new ';
        wr += res_tname;
        wr += '(';
        wr.WriteNumbered(sz1,
          (wr,row_i)->wr.WriteNumbered(sz2,
            (wr,col_i)->
            begin
              var side1 := row_i = sz1;
              var side2 := col_i = sz2;
              wr += Ord( (side1=side2) and (side1 or (row_i=col_i)) );
            end,
            (wr,col_i)->(wr+=', ')
          ),
          (wr,row_i)->(wr+=', ')
        );
        wr += ');'#10;
      end;
      
      wr += '    '#10;
    end;
    
    {$endregion Identity}
    
    {$region Row,Col}
    
    private procedure WriteColRow(wr: Writer; res_tname: string; sz1,sz2: integer) :=
      for var is_row := true downto false do
      begin
        var vec_tname := (if is_row then row_type else col_type).Name.ToString(nil);
        var vec_sz := if is_row then sz2 else sz1;
        var vec_c := if is_row then sz1 else sz2;
        var vec_word := if is_row then 'Row' else 'Col';
        var ind_name := vec_word.ToLower+'_i';
        
        {$region FromVec}
        
        wr += '    public static function From';
        wr += vec_word;
        wr += 's(';
        wr.WriteNumbered(vec_c,
          (wr,i)->
          begin
            wr += vec_word.ToLower;
            wr += i;
          end,
          (wr,i)->(wr += ', '),
          0
        );
        wr += ': ';
        wr += vec_tname;
        wr += '): ';
        wr += res_tname;
        wr += ';'#10;
        
        wr += '    begin'#10;
        
        for var i := 0 to vec_c-1 do
        begin
          wr += '      Result.';
          wr += vec_word;
          wr += i;
          wr += ' := ';
          wr += vec_word.ToLower;
          wr += i;
          wr += ';'#10;
        end;
        
        wr += '    end;'#10;
        
        wr += '    '#10;
        {$endregion FromVec}
        
        {$region *I}
        for var i := 0 to vec_c-1 do
        begin
          
          wr += '    public property ';
          wr += vec_word;
          wr += i;
          wr += ': ';
          wr += vec_tname;
          wr += #10;
          
          wr += '      read ';
          if is_row then
          begin
            wr += 'new ';
            wr += vec_tname;
            wr += '(';
            wr.WriteNumbered(vec_sz,
              (wr,col_i)->
              begin
                wr += 'val';
                wr += i;
                wr += col_i;
              end,
              (wr,i)->(wr += ', '),
              0
            );
            wr += ')';
          end else
          begin
            wr += 'P';
            wr += vec_tname;
            wr += '(pointer(@val0';
            wr += i;
            wr += '))^';
          end;
          wr += #10;
          
          wr += '      write ';
          if is_row then
          begin
            wr += 'value.Deconstruct(';
            wr.WriteNumbered(vec_sz,
              (wr,col_i)->
              begin
                wr += 'val';
                wr += i;
                wr += col_i;
              end,
              (wr,i)->(wr += ', '),
              0
            );
            wr += ')';
          end else
          begin
            wr += 'P';
            wr += vec_tname;
            wr += '(pointer(@val0';
            wr += i;
            wr += '))^';
            wr += ' := value';
          end;
          wr += ';'#10;
          
          wr += '    '#10;
        end;
        {$endregion *I}
        
        {$region At}
        
        wr += '    private function Get';
        wr += vec_word;
        wr += 'At(';
        wr += ind_name;
        wr += ': integer';
        wr += '): ';
        wr += vec_tname;
        wr += ';'#10;
        wr += '    begin'#10;
        WriteCase(wr, vec_c, ind_name, i->
        begin
          wr += 'Result := ';
          wr += vec_word;
          wr += i;
        end);
        wr += '    end;'#10;
        
        wr += '    private procedure Set';
        wr += vec_word;
        wr += 'At(';
        wr += ind_name;
        wr += ': integer; new_val: ';
        wr += vec_tname;
        wr += ') :='#10;
        WriteCase(wr, vec_c, ind_name, i->
        begin
          wr += vec_word;
          wr += i;
          wr += ' := new_val';
        end);
        
        wr += '    public property ';
        wr += vec_word;
        wr += 'At[';
        wr += ind_name;
        wr += ': integer]: ';
        wr += vec_tname;
        wr += ' read Get';
        wr += vec_word;
        wr += 'At write Set';
        wr += vec_word;
        wr += 'At;'#10;
        
        wr += '    '#10;
        {$endregion At}
        
        {$region GetColUnsafePtr}
        if not is_row then
        begin
          
          {$region *I}
          for var i := 0 to vec_c-1 do
          begin
            
            wr += '    public function GetColUnsafePtr';
            wr += i;
            wr += ': P';
            wr += vec_tname;
            wr += ' := pointer(@val0';
            wr += i;
            wr += ');'#10;
            
          end;
          {$endregion *I}
          
          {$region At}
          
          wr += '    public function GetColUnsafePtrAt(';
          wr += ind_name;
          wr += ': integer): P';
          wr += vec_tname;
          wr += ';'#10;
          
          wr += '    begin'#10;
          
          //TODO #2869
          var wr2 := wr;
          WriteCase(wr, vec_c, ind_name, i->
          begin
            wr2 += 'Result := GetColUnsafePtr';
            wr2 += i;
          end);
          
          wr += '    end;'#10;
          
          {$endregion At}
          
          wr += '    '#10;
        end;
        {$endregion GetColUnsafePtr}
        
        // - [Use/Conv][Col][1/2/3/4]SafePtr
        // - [Use/Conv][Col]SafePtrAt
        // - [Use/Conv]Each[Row/Col][/SafePtr]
        {$region Use/Conv Row/Col}
        foreach var use_kind in |'I', 'At', 'Each'| do
        for var with_ptr := false to true do
        for var with_ret := false to true do
        for var i := 0 to (vec_c-1)*Ord(use_kind='I') do
        begin
          if is_row and with_ptr then continue;
          case use_kind of
            'I': if is_row or not with_ptr then continue;
            'At': if is_row or not with_ptr then continue;
            'Each': ;
            else raise new NotImplementedException;
          end;
          
          var use_word := if with_ret then 'Conv' else 'Use';
          var method_word := if with_ret then 'function' else 'procedure';
          
          wr += '    public [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
          wr += method_word;
          wr += ' ';
          wr += use_word;
          if use_kind='Each' then
            wr += use_kind;
          wr += vec_word;
          if use_kind='I' then
            wr += i;
          if with_ptr then
            wr += 'SafePtr';
          if use_kind='At' then
            wr += 'At';
          if with_ret then
            wr += '<T>';
          wr += '(';
          if use_kind='At' then
          begin
            wr += ind_name;
            wr += ': integer; ';
          end;
          wr += use_word.ToLower;
          wr += ': ';
          wr += use_word;
          wr += vec_tname;
          if with_ptr then
            wr += 'SafePtr';
          wr += 'Callback';
          if with_ret then
            wr += '<T>';
          wr += ')';
          
          if use_kind='I' then
          begin
            wr += ' := ';
            wr += use_word.ToLower;
            wr += '(P';
            wr += vec_tname;
            wr += '(pointer(@val0';
            wr += i;
            wr += '))^);'#10;
            wr += '    '#10;
            continue;
          end;
          
          if with_ret then
          begin
            wr += ': ';
            case use_kind of
              'At':
                wr += 'T';
              'Each':
              begin
                wr += 'ValueTuple<';
                wr.WriteNumbered(vec_c, 'T!, ');
                wr += '>';
              end;
              else raise new NotImplementedException;
            end;
          end;
          wr += ';'#10;
          
          wr += '    begin'#10;
          
          case use_kind of
            'At':
            begin
              //TODO #2869
              var wr2 := wr;
              WriteCase(wr, vec_c, ind_name, vec_i->
              begin
                if with_ret then
                  wr2 += 'Result := ';
                wr2 += use_word;
                wr2 += vec_word;
                wr2 += vec_i;
                wr2 += 'SafePtr(';
                wr2 += use_word.ToLower;
                wr2 += ')';
              end);
            end;
            'Each':
            for var vec_i := 0 to vec_c-1 do
            begin
              wr += '      ';
              if with_ret then
              begin
                wr += 'Result.Item';
                wr += vec_i+1;
                wr += ' := ';
              end;
              if with_ptr then
              begin
                wr += use_word;
                wr += vec_word;
                wr += vec_i;
                wr += 'SafePtr(';
                wr += use_word.ToLower;
                wr += ')';
              end else
              begin
                wr += use_word.ToLower;
                wr += '(';
                wr += vec_word;
                wr += vec_i;
                wr += ')';
              end;
              wr += ';'#10;
            end;
            else raise new NotImplementedException;
          end;
          
          wr += '    end;'#10;
          
          wr += '    '#10;
        end;
        {$endregion Use/Conv Row/Col}
        
      end;
    
    {$endregion Row/Col}
    
    {$region ValAt}
    
    private procedure WriteValAt(wr: Writer);
    begin
      var write_inds := procedure->
        NameConditional(
          sz->
            (wr += 'i'),
          (sz1,sz2)->
            (wr += 'row_i, col_i')
        );
      
      wr += '    private function GetValAt(';
      write_inds;
      wr += ': integer';
      if self.Name.IsVector then
        wr += '; ind_name: string';
      wr += '): ';
      wr += Name.OriginalType;
      wr += ';'#10;
      wr += '    begin'#10;
      NameConditional(
        sz->
          WriteCase(wr, sz, 'i', i->
          begin
            wr += 'Result := self.val';
            wr += i;
          end),
        (sz1,sz2)->
          WriteCase(wr, sz2, 'col_i', col_i->
          begin
            wr += 'Result := self.Col';
            wr += col_i;
            wr += '.GetValAt(row_i, ''row_i'')';
          end)
      );
      wr += '    end;'#10;
      
      wr += '    private procedure SetValAt(';
      write_inds;
      wr += ': integer; new_val: ';
      wr += Name.OriginalType;
      if self.Name.IsVector then
        wr += '; ind_name: string';
      wr += ') :='#10;
      NameConditional(
        sz->
          WriteCase(wr, sz, 'i', i->
          begin
            wr += 'self.val';
            wr += i;
            wr += ' := new_val';
          end),
        (sz1,sz2)->
          WriteCase(wr, sz2, 'col_i', col_i->
          begin
            //TODO Use "self.SafeUseCol(col->col.SetValAt)"
            // - Need lambda with var-parameter
            wr += 'begin var col := self.Col';
            wr += col_i;
            wr += '; col.SetValAt(row_i, new_val, ''row_i''); self.Col';
            wr += col_i;
            wr += ' := col; end';
          end)
      );
      
      wr += '    public property ValAt[';
      write_inds;
      wr += ': integer]: ';
      wr += Name.OriginalType;
      wr += ' read GetValAt(';
      write_inds;
      if self.Name.IsVector then
        wr += ', ''i''';
      wr += ') write SetValAt(';
      write_inds;
      wr += ', value';
      if self.Name.IsVector then
        wr += ', ''i''';
      wr += ');'#10;
      
      wr += '    '#10;
    end;
    
    {$endregion ValAt}
    
    {$region VecArithmetics}
    
    private procedure WriteVecArithmetics(wr: Writer; own_tname: string; sz: integer);
    begin
      
      {$region Unary}
      
      if not self.Name.IsUnsigned then
      begin
        wr += '    public static function operator-(v: ';
        wr += own_tname;
        wr += ') := new ';
        wr += own_tname;
        wr += '(';
        wr.WriteNumbered(sz,
          (wr,i)->
          begin
            wr += '-v.val';
            wr += i;
          end,
          (wr,i)->(wr += ', '),
          0
        );
        wr += ');'#10;
      end;
      
      begin
        wr += '    public static function operator+(v: ';
        wr += own_tname;
        wr += ') := v;'#10;
      end;
      
      wr += '    '#10;
      {$endregion Unary}
      
      {$region Scale}
      
      begin
        wr += '    public static function operator*(v: ';
        wr += own_tname;
        wr += '; k: ';
        wr += Name.OriginalType;
        wr += ') := new ';
        wr += own_tname;
        wr += '(';
        wr.WriteNumbered(sz,
          (wr,i)->
          begin
            wr += 'v.val';
            wr += i;
            wr += ' * k';
          end,
          (wr,i)->(wr += ', '),
          0
        );
        wr += ');'#10;
      end;
      
      begin
        var div_op := if Name.IsFloat then
          '/' else 'div';
        wr += '    public static function operator';
        if not Name.IsFloat then
          wr += ' ';
        wr += div_op;
        wr += '(v: ';
        wr += own_tname;
        wr += '; k: ';
        wr += Name.OriginalType;
        wr += ') := new ';
        wr += own_tname;
        wr += '(';
        wr.WriteNumbered(sz,
          (wr,i)->
          begin
            wr += 'v.val';
            wr += i;
            wr += ' ';
            wr += div_op;
            wr += ' k';
          end,
          (wr,i)->(wr += ', '),
          0
        );
        wr += ');'#10;
      end;
      
      wr += '    '#10;
      {$endregion Scale}
      
      {$region Binary}
      
      foreach var binary_op in '+-*' do
      begin
        wr += '    public static function operator';
        wr += binary_op;
        wr += '(v1, v2: ';
        wr += own_tname;
        wr += ') := ';
        if binary_op<>'*' then
        begin
          wr += 'new ';
          wr += own_tname;
          wr += '(';
        end;
        wr.WriteNumbered(sz,
          (wr,i)->
          begin
            wr += 'v1.val';
            wr += i;
            wr += ' ';
            wr += binary_op;
            wr += ' v2.val';
            wr += i;
          end,
          (wr,i)->(wr += if binary_op<>'*' then ', ' else ' + '),
          0
        );
        if binary_op<>'*' then
          wr += ')';
        wr += ';'#10;
      end;
      
      wr += '    '#10;
      {$endregion Binary}
      
    end;
    
    {$endregion VecArithmetics}
    
    {$region Vec method's}
    
    private procedure WriteVecMethods(wr: Writer; own_tname: string; sz: integer);
    begin
      
      {$region Length}
      
      wr += '    public function SqrLength := self*self;'#10;
      //TODO MathF.Sqrt
      wr += '    public function Length := Sqrt(SqrLength);'#10;
      wr += '    '#10;
      
      {$endregion Length}
      
      {$region Normalized}
      if Name.IsFloat then
      begin
        wr += '    public function Normalized := self / ';
        var need_conv := Name.OriginalType <> 'double';
        if need_conv then
        begin
          wr += Name.OriginalType;
          wr += '(';
        end;
        wr += 'Length';
        if need_conv then
          wr += ')';
        wr += ';'#10;
        wr += '    '#10;
      end;
      {$endregion Normalized}
      
      {$region Cross}
      if (sz in 2..3) and not Name.IsUnsigned then
      begin
        
        wr += '    public static function CrossCW(v1, v2: ';
        wr += own_tname;
        wr += ') :='#10;
        
        if sz=2 then
          // Vec2d.CrossCW(v1,v2) = new Vec3d(0,0,1) * Vec3d.CrossCW(Vec3d(v1),Vec3d(v2))
          wr += '      v1.val0*v2.val1 - v2.val0*v1.val1;'#10 else
        begin
          wr += '      new ';
          wr += own_tname;
          wr += '(';
          wr.WriteNumbered(sz,
            (wr,i)->
            begin
              wr += 'v1.val';
              wr += (i+1) mod sz;
              wr += '*v2.val';
              wr += (i+2) mod sz;
              wr += ' - v2.val';
              wr += (i+1) mod sz;
              wr += '*v1.val';
              wr += (i+2) mod sz;
            end,
            (wr,i)->(wr += ', '),
            0
          );
          wr += ');'#10;
        end;
        
        wr += '    public static function CrossCCW(v1, v2: ';
        wr += own_tname;
        wr += ') := CrossCW(v2, v1);'#10;
        
        wr += '    '#10;
      end;
      {$endregion Cross}
      
    end;
    
    {$endregion Vec method's}
    
    {$region Mtr method's}
    
    private procedure WriteMtrMethods(wr: Writer; res_tname: string; sz: integer);
    begin
      
      {$region Scale}
      
      begin
        wr += '    public static function Scale(k: ';
        wr += Name.OriginalType;
        wr += ') :='#10;
        
        wr += '      new ';
        wr += res_tname;
        wr += '(';
        wr.WriteNumbered(sz,
          (wr,row_i)->wr.WriteNumbered(sz,
            (wr,col_i)->(wr += row_i=col_i?'k':'0'),
            (wr,col_i)->(wr += ', ')
          ),
          (wr,row_i)->(wr+=', ')
        );
        wr += ');'#10;
        
        wr += '    '#10;
      end;
      
      {$endregion Scale}
      
      {$region Translate}
      for var is_prefix := true downto false do
      begin
        var p_fix_word := if is_prefix then
          'Prefix' else 'Postfix';
        
        wr += '    public static function Translate';
        wr += p_fix_word;
        wr += '(';
        
        wr.WriteNumbered(sz-1,
          (wr,i)->
          begin
            wr += 'Δ';
            wr += 'XYZ'[i];
          end,
          (wr,i)->(wr += ', '),
          0
        );
        wr += ': ';
        wr += Name.OriginalType;
        wr += ') :='#10;
        
        wr += '      new ';
        wr += res_tname;
        wr += '(';
        wr.WriteNumbered(sz,
          (wr,row_i)->wr.WriteNumbered(sz,
            (wr,col_i)->
              if row_i=col_i then
                wr += '1' else
              if (is_prefix ? col_i : row_i) = sz-1 then
              begin
                wr += 'Δ';
                wr += 'XYZ'[is_prefix ? row_i : col_i];
              end else
                wr += '0',
            (wr,col_i)->(wr += ', '),
            0
          ),
          (wr,row_i)->(wr+=', '),
          0
        );
        wr += ');'#10;
        
        wr += '    '#10;
      end;
      {$endregion Translate}
      
      {$region Rotate}
      
      {$region 2D}
      if sz<2 then raise new NotSupportedException;
      foreach var dir in sz.Times.Permutations(2) do
      begin
        var (d1,d2) := dir;
        
        wr += '    public static function RotatePrefix';
        foreach var d in dir do
          wr += 'XYZW'[d];
        wr += '(radians: real): ';
        wr += res_tname;
        wr += ';'#10;
        
        wr += '    begin'#10;
        
        wr += '      var a_sin: ';
        wr += Name.OriginalType;
        wr += ' := Sin(radians);'#10;
        wr += '      var a_cos: ';
        wr += Name.OriginalType;
        wr += ' := Cos(radians);'#10;
        
        for var col_i := 0 to sz-1 do
        begin
          wr += '      Result.Col';
          wr += col_i;
          wr += ' := new ';
          wr += col_type.Name.ToString(nil);
          wr += '(';
          wr.WriteNumbered(sz,
            (wr,row_i)->
              if (row_i not in dir) or (col_i not in dir) then
                wr += Ord(row_i=col_i) else
              if row_i=d1 then
              begin
                wr +=
                  if col_i=d1 then '+a_cos' else
                  if col_i=d2 then '-a_sin' else
                    nil;
              end else
              if row_i=d2 then
              begin
                wr +=
                  if col_i=d1 then '+a_sin' else
                  if col_i=d2 then '+a_cos' else
                    nil;
              end else,
            (wr,row_i)->(wr += ', '),
            0
          );
          wr += ');'#10;
        end;
        
        wr += '    end;'#10;
        
        wr += '    public static function RotatePostfix';
        foreach var d in dir do
          wr += 'XYZW'[d];
        wr += '(radians: real): ';
        wr += res_tname;
        wr += ' := RotatePrefix';
        foreach var d in dir.Reverse do
          wr += 'XYZW'[d];
        wr += '(radians);'#10;
        
        wr += '    '#10;
      end;
      {$endregion 2D}
      
      {$region 3D}
      if sz>=3 then foreach var c in sz.Times.Combinations(3) do
      begin
        // Пока что выключил
        if 3 in c then continue;
        
        foreach var dir in c.Permutations do
        begin
          
          wr += '    public static function RotatePrefix';
          foreach var d in dir do
            wr += 'XYZW'[d];
          wr += '(radians: real; u: ';
          wr += col_type.Name.ToString(nil);
          wr += '): ';
          wr += res_tname;
          
          if not dir.SequenceEqual(c) and not dir.Reverse.SequenceEqual(c) then
          begin
            wr += ' := RotatePrefix';
            var is_only_rotated := c.Cycle.ElementAt(c.IndexOf(dir[0])+1) = dir[1];
            foreach var d in is_only_rotated?c:c.Reverse do
              wr += 'XYZW'[d];
            wr += '(radians, u);'#10;
            continue;
          end;
          wr += ';'#10;
          
          wr += '    begin'#10;
          //     ┌                  ┐
          //     │    0, +u.z, -u.y │
          // W = │ -u.z,    0, +u.x │
          //     │ +u.y, -u.x,    0 │
          //     └                  ┘
          //
          // Result =  Identity  +  Sin(radians)*W  +  (2*Sqr(Sin(radians/2))) * (W*W)
          
          // В отличии от 2D, тут нет смысла преобразовывать в single
          // CIL оператор mul всё равно преобразовывает в double
          wr += '      var k1 := Sin(radians);'#10;
          wr += '      var k2 := 2*Sqr(Sin(radians/2));'#10;
          
          var sign_at := function(i1,i2: integer):boolean ->
          case (i1+3-i2) mod 3 of
            0: raise new InvalidOperationException;
            1: Result := true;
            2: Result := false;
            else raise nil;
          end;
          var u_ind := function(i1,i2: integer):integer -> 3-i1-i2;
          
          for var col_i := 0 to sz-1 do
            for var row_i := 0 to sz-1 do
            begin
              wr += '      Result.val';
              wr += row_i;
              wr += col_i;
              wr += ' := ';
              
              var i1 := dir.IndexOf(row_i);
              var i2 := dir.IndexOf(col_i);
              if (i1=-1) or (i2=-1) then
              begin
                wr += Ord(row_i=col_i);
                wr += ';'#10;
                continue;
              end;
              
              if i1=i2 then
                wr += '         1' else
              begin
                wr += if sign_at(i1,i2) then '+' else '-';
                wr += 'k1*u.val';
                wr += u_ind(i1,i2);
              end;
              
              wr += ' + k2*(';
              for var mlt_i := 0 to 3-1 do
                if (mlt_i=i1) or (mlt_i=i2) then
                begin
                  wr += '              ';
                end else
                begin
                  wr += if sign_at(i2,mlt_i)=sign_at(mlt_i,i1) then '+' else '-';
                  wr += 'u.val';
                  wr += u_ind(i2,mlt_i);
                  wr += '*u.val';
                  wr += u_ind(mlt_i,i1);
                end;
              wr += ');'#10;
              
            end;
          
          wr += '    end;'#10;
          
        end;
        wr += '    '#10;
        
        foreach var dir in c.Permutations do
        begin
          
          wr += '    public static function RotatePostfix';
          foreach var d in dir do
            wr += 'XYZW'[d];
          wr += '(radians: real; u: ';
          wr += col_type.Name.ToString(nil);
          wr += '): ';
          wr += res_tname;
          wr += ' := RotatePrefix';
          foreach var d in dir.Reverse do
            wr += 'XYZW'[d];
          wr += '(radians, u);'#10;
          
        end;
        wr += '    '#10;
        
      end;
      {$endregion 3D}
      
      {$endregion Rotate}
      
      {$region Determinant}
      
      wr += '    public function Determinant: ';
      wr += Name.OriginalType;
      wr += ';'#10;
      
      wr += '    begin'#10;
      
      for var det_sz := 2 to sz do
        foreach var col_is in (0..sz-1).Combinations(det_sz) do
        begin
          wr += '      ';
          if det_sz=sz then
            wr += 'Result' else
          begin
            wr += 'var det';
            foreach var col_i in col_is do
              wr += col_i;
          end;
          foreach var col_i in col_is index i do
          begin
            wr +=
              if i=0 then
                ' := ' else
              if i.IsEven then
                ' + ' else
                ' - ';
            wr += 'self.val';
            wr += sz-det_sz;
            wr += col_i;
            wr += '*';
            if det_sz=2 then
            begin
              wr += 'self.val';
              wr += sz-1;
              wr += col_is.Except(|col_i|).Single;
            end else
            begin
              wr += 'det';
              foreach var old_col_i in col_is.Except(|col_i|) do
                wr += old_col_i;
            end;
          end;
          
          wr += ';'#10;
        end;
      
      wr += '    end;'#10;
      
      wr += '    '#10;
      {$endregion Determinant}
      
    end;
    
    {$endregion Mtr method's}
    
    {$region ConvOperator's}
    
    private static procedure WriteConvOps(wr: Writer; org_t1, org_t2: TypeCombo);
    begin
      if org_t1.Name.IsMatrix <> org_t2.Name.IsMatrix then exit;
      
      foreach var (t1,t2) in |org_t1,org_t2|.Permutations do
      begin
        var t1_name := t1.Name.ToString(true);
        var t2_name := t2.Name.ToString(true);
        
        var need_conv := t1.Name.IsFloat and not t2.Name.IsFloat;
        var write_in_conv := procedure(write_body: Action)->
        begin
          if need_conv then
          begin
            wr += 'Convert.To';
            wr += t2.Name.OriginalType;
            wr += '(';
          end;
          write_body;
          if need_conv then
            wr += ')';
        end;
        
        var conv_op_word :=
          if need_conv or t2.Name.IsAnySizeBiggerThan(t1.Name) then
            'explicit' else 'implicit';
        
        var var_name := if t1.Name.IsVector then 'v' else 'm';
        
        wr += 'function operator ';
        wr += conv_op_word;
        wr += '(';
        wr += var_name;
        wr += ': ';
        wr += t1_name;
        wr += '): ';
        wr += t2_name;
        wr += '; extensionmethod := ';
        
        t1.NameConditional(
          t1_sz->
          begin
            var t2_sz := t2.Name.VectorSize;
            
            wr += 'new ';
            wr += t2_name;
            wr += '(';
            wr.WriteNumbered(t2_sz,
              (wr,i)->
              begin
                if i >= t1_sz then
                begin
                  wr += '0';
                  exit;
                end;
                write_in_conv(()->
                begin
                  wr += 'v.val';
                  wr += i;
                end);
              end,
              (wr,i)->(wr += ', '),
              0
            );
            wr += ')';
            
          end,
          (t1_sz1,t1_sz2)->
          begin
            var (t2_sz1,t2_sz2) := t2.Name.MatrixSizes;
            
            wr += t2_name;
            wr += '.FromCols(';
            wr.WriteNumbered(t2_sz2,
              (wr,col_i)->
              begin
                var t2_col_tname := t2.Name.MatrixColTypeName.ToString(nil);
                if (col_i>=t1_sz2) and (col_i>=t2_sz1) then
                begin
                  wr += 'default(';
                  wr += t2_col_tname;
                  wr += ')';
                end else
                if (t2_sz2>t1_sz2) and (col_i>t1_sz2) or (col_i>=t1_sz2) then
                begin
                  wr += 'new ';
                  wr += t2_col_tname;
                  wr += '(';
                  wr.WriteNumbered(t2_sz1,
                    (wr,row_i)->write_in_conv(()->
                      if (row_i<t1_sz1) and (col_i<t1_sz2) then
                      begin
                        wr += 'm.val';
                        wr += row_i;
                        wr += col_i;
                      end else
                        wr += if row_i=col_i then '1.0' else '0.0'
                    ),
                    (wr,row_i)->(wr += ', '),
                    0
                  );
                  wr += ')';
                end else
                begin
                  var need_vec_conv := need_conv or (t2_sz1>t1_sz1);
                  if need_vec_conv then
                  begin
                    wr += t2_col_tname;
                    wr += '(';
                  end;
                  wr += 'm.Col';
                  wr += col_i;
                  if need_vec_conv then
                    wr += ')';
                end;
              end,
              (wr,col_i)->(wr += ', '),
              0
            );
            wr += ')';
            
          end
        );
        wr += ';'#10;
        
      end;
      
      wr += #10;
    end;
    
    {$endregion ConvOperator's}
    
    {$region MtrExt}
    
    {$region Transpose}
    
    private procedure WriteTranspose(wr: Writer; own_name: string);
    begin
      var (sz1,sz2) := Name.MatrixSizes;
      
      wr += 'function Transpose(self: ';
      wr += own_name;
      wr += '); extensionmethod :='#10;
      
      wr += '  ';
      wr += self.tsp_type.Name.ToString(true);
      wr += '.FromCols(';
      wr.WriteNumbered(sz1,
        (wr,res_col_i)->
        begin
          wr += 'self.Row';
          wr += res_col_i;
        end,
        (wr,res_col_i)->(wr += ', '),
        0
      );
      wr += ');'#10;
      
      wr += #10;
    end;
    
    {$endregion Transpose}
    
    {$region Mtr*Vec}
    
    private procedure WriteMtrMltVec(wr: Writer; own_name: string; vec_t: TypeCombo; vec_name: string);
    begin
      if vec_t<>self.row_type then exit;
      
      wr += 'function operator*(m: ';
      wr += own_name;
      wr += '; v: ';
      wr += vec_name;
      wr += '); extensionmethod :='#10;
      
      wr += '  new ';
      wr += col_type.Name.ToString(nil);
      wr += '(';
      wr.WriteNumbered(col_type.Name.VectorSize,
        (wr,res_i)->
        begin
          wr += 'm.Row';
          wr += res_i;
          wr += '*v';
        end,
        (wr,res_i)->(wr += ', '),
        0
      );
      wr += ');'#10;
      
      wr += #10;
    end;
    
    {$endregion Mtr*Vec}
    
    {$region Vec*Mtr}
    
    private procedure WriteVecMltMtr(wr: Writer; own_name: string; vec_t: TypeCombo; vec_name: string);
    begin
      if vec_t<>self.col_type then exit;
      
      wr += 'function operator*(v: ';
      wr += vec_name;
      wr += '; m: ';
      wr += own_name;
      wr += '); extensionmethod :='#10;
      
      wr += '  new ';
      wr += row_type.Name.ToString(nil);
      wr += '(';
      wr.WriteNumbered(row_type.Name.VectorSize,
        (wr,res_i)->
        begin
          wr += 'm.Col';
          wr += res_i;
          wr += '*v';
        end,
        (wr,res_i)->(wr += ', '),
        0
      );
      wr += ');'#10;
      
      wr += #10;
    end;
    
    {$endregion Vec*Mtr}
    
    {$region Mtr*Mtr}
    
    private static procedure WriteMtrMltMtr(wr: Writer; t1,t2: TypeCombo; t1_name, t2_name: string);
    begin
      if t1.row_type<>t2.col_type then exit;
      
      var res_sz1 := t1.col_type.Name.VectorSize;
      var res_sz2 := t2.row_type.Name.VectorSize;
      var res_t := inherited ByName(TypeComboName.Matrix(t1.Name.OriginalType, res_sz1, res_sz2));
      
      wr += 'function operator*(m1: ';
      wr += t1_name;
      wr += '; m2: ';
      wr += t2_name;
      wr += '); extensionmethod :='#10;
      
      wr += '  ';
      wr += res_t.Name.ToString(true);
      wr += '.FromCols('#10;
      wr.WriteNumbered(res_sz2,
        (wr,col_i)->
        begin
          wr += '    new ';
          wr += res_t.col_type.Name.ToString(nil);
          wr += '(';
          wr.WriteNumbered(res_sz1,
            (wr,row_i)->
            begin
              wr += 'm1.Row';
              wr += row_i;
              wr += '*m2.Col';
              wr += col_i;
            end,
            (wr,row_i)->(wr += ', '),
            0
          );
          wr += ')';
        end,
        (wr,col_i)->(wr += ','#10),
        0
      );
      wr += #10;
      wr += '  );'#10;
      
      wr += #10;
    end;
    
    {$endregion Mtr*Mtr}
    
    private procedure WriteMtrExtWith(wr: Writer; own_name: string; old_t: TypeCombo; old_name: string);
    begin
      if self.Name.OriginalType <> old_t.Name.OriginalType then exit;
      
      if old_t.Name.IsVector then
      begin
        WriteMtrMltVec(wr, own_name, old_t, old_name);
        WriteVecMltMtr(wr, own_name, old_t, old_name);
      end else
      if old_t.Name.IsMatrix then
      begin
        WriteMtrMltMtr(wr, self,old_t, own_name,old_name);
        WriteMtrMltMtr(wr, old_t,self, old_name,own_name);
      end else
        raise new NotImplementedException;
      
    end;
    
    {$endregion MtrExt}
    
    {$endregion Writes}
    
    public function MakeWriteProc: NamedItemWriteProc;
    begin
      var main_name := self.Name.ToString(false);
      var simp_name := self.Name.ToString(true);
      
      if self.Name.IsMatrix then
      begin
        row_type.Use(true);
        col_type.Use(true);
        WritableNamedTypeHelper.UnordUse(()->tsp_type.Use(true));
      end;
      
      Result := (prev_written, intr_wr, impl_wr)->
      begin
        
        intr_wr += '  ///'#10;
        
        intr_wr += '  ';
        intr_wr += main_name;
        intr_wr += ' = record'#10;
        
        WriteFields(intr_wr);
        WriteConstructor(intr_wr);
        
        WriteIO(intr_wr, main_name);
        
        NameConditional(sz->exit(),
          (sz1,sz2)->
          begin
            self.WriteIdentity(intr_wr, main_name, sz1,sz2);
            self.WriteColRow(intr_wr, main_name, sz1,sz2);
          end
        );
        WriteValAt(intr_wr);
        
        NameConditional(
          sz->
          begin
            WriteVecArithmetics(intr_wr, main_name, sz);
            WriteVecMethods(intr_wr, main_name, sz);
          end,
          (sz1,sz2)->
            // Use Identity or IdentityKeepLast
            if sz1=sz2 then
              WriteMtrMethods(intr_wr, main_name, sz1)
        );
        
        intr_wr += '  end;'#10;
        
        if simp_name<>main_name then
        begin
          intr_wr += '  ///'#10;
          intr_wr += '  ';
          intr_wr += simp_name;
          intr_wr += ' = ';
          intr_wr += main_name;
          intr_wr += ';';
          intr_wr += #10;
        end;
        
        if Name.IsVector then
        begin
          
          begin
            intr_wr += '  ///'#10;
            intr_wr += '  P';
            intr_wr += main_name;
            intr_wr += ' = ^';
            intr_wr += main_name;
            intr_wr += ';';
            intr_wr += #10;
          end;
          
          if Name.IsFloat then
            for var with_ptr := false to true do
              for var with_ret := false to true do 
              begin
                intr_wr += '  ///'#10;
                
                intr_wr += '  ';
                intr_wr += if with_ret then
                  'Conv' else 'Use';
                intr_wr += main_name;
                if with_ptr then
                  intr_wr += 'SafePtr';
                intr_wr += 'Callback';
                if with_ret then
                  intr_wr += '<T>';
                intr_wr += ' = ';
                intr_wr += if with_ret then
                  'function' else 'procedure';
                intr_wr += '(';
                if with_ptr then
                  intr_wr += 'var ';
                intr_wr += 'v: ';
                intr_wr += main_name;
                intr_wr += ')';
                if with_ret then
                  intr_wr += ': T';
                intr_wr += ';'#10;
                
              end;
          
        end;
        
        intr_wr += '  '#10;
        
        foreach var prev_type in prev_written.OfType&<TypeCombo> do
        begin
          
          WriteConvOps(impl_wr, self, prev_type);
          
          if Name.IsMatrix then
            WriteMtrExtWith(impl_wr, simp_name, prev_type, prev_type.Name.ToString(true));
          
        end;
        if Name.IsMatrix then
        begin
          WriteMtrMltMtr(impl_wr, self,self, simp_name,simp_name);
          WriteTranspose(impl_wr, simp_name);
        end;
        
      end;
      
    end;
    
    protected procedure LogContents(l: Logger); override;
    begin
      l.Otp($'# {self.Name.ToString(true)} ({self.Name})');
      l.Otp($'');
    end;
    
  end;
  
  {$endregion TypeCombo}
  
  {$region CastableToList}
  
  CastableToList = record
    private items := new LazyUniqueItemList<PascalBasicType>;
    
    public constructor(br: BinReader) :=
      items.Add(
        br.ReadInt32Arr.Select(ind->
        begin
          var (ptr, lvls, dt) := LoadedBasicType.ByIndex(ind).FeedToTypeTable;
          if dt=nil then raise nil;
          if ptr<>0 then raise new InvalidOperationException;
          Result := dt as PascalBasicType;
          if Result=nil then
            raise new InvalidOperationException($'Expected basic type, found {dt}');
        end)
      );
    public constructor(pascal_type_name: string) :=
      items.Add( SeqGen(1, i->PascalBasicType.FindOrMake(pascal_type_name)) );
    ///--
    public constructor := raise new InvalidOperationException;
    
    private calculated: array of PascalBasicType;
    public function ToSeq: sequence of PascalBasicType;
    begin
      Result := calculated;
      // items.ToSeq cannot change, after it has been calculated
      if Result<>nil then exit;
      
      var res := items.ToSeq.ToList;
      
      begin
        var found_int32_types := |'Int32','UInt32','DummyEnum','DummyFlags'|.Where(tname->tname in res.Select(t->t.Name)).ToArray;
        if found_int32_types.Skip(1).Any or found_int32_types.Any(t->t.StartsWith('Dummy')) then
        begin
          foreach var tname in found_int32_types do
            if res.RemoveAll(t->t.Name=tname) <> 1 then
              raise new InvalidOperationException;
          res.Add(PascalBasicType.ByName(('Int32' not in found_int32_types ? 'U' : '') + 'Int32'));
        end;
      end;
      
      if res.Count>1 then
      begin
//        Otp($'Comparing: '+items.ToSeq.JoinToString);
        res.Sort((t1,t2)->t1.ByteSize-t2.ByteSize);
//        Otp('='*30);
      end;
      
      calculated := res.ToArray;
      Result := res;
    end;
    
  end;
  
  {$endregion CastableToList}
  
  {$region EnumsInGroup}
  
  EnumsInGroup = abstract class(MutiKindItem<EnumsInGroup, GroupKind>)
    
    public function IsBitfield: boolean; abstract;
    
    public procedure MarkReferenced; abstract;
    
    public function AllEnums: sequence of Enum; abstract;
    
  end;
  
  [PCUAlwaysRestore]
  SimpleEnumsInGroup = sealed class(EnumsInGroup)
    
    private is_bitfield: boolean;
    private enum_items: LazyUniqueItemList<Enum>;
    private constructor(is_bitfield: boolean; enum_inds: array of integer);
    begin
      self.is_bitfield := is_bitfield;
      self.enum_items := Enum.MakeLazySeq(enum_inds);
    end;
    public constructor(is_bitfield: boolean; enums: array of Enum);
    begin
      self.is_bitfield := is_bitfield;
      self.enum_items := new LazyUniqueItemList<Enum>(enums);
    end;
    private constructor := raise new InvalidOperationException;
    
    static constructor;
    begin
      DefineLoader(GK_Enum,     br->new SimpleEnumsInGroup(false, br.ReadInt32Arr));
      DefineLoader(GK_Bitfield, br->new SimpleEnumsInGroup(true,  br.ReadInt32Arr));
    end;
    
    public function Enums := enum_items.ToSeq;
    
    public function IsBitfield: boolean; override := is_bitfield;
    
    public function AllEnums: sequence of Enum; override := self.Enums;
    
    public procedure MarkReferenced; override :=
      foreach var e in Enums do
        e.UseFromGroup;
    
  end;
  
  EnumWithObjInfo = record
    private e_ind: integer;
    private inp_t: LoadedParData?;
    private otp_t: LoadedParData?;
    
    public static function Load(br: BinReader): EnumWithObjInfo;
    begin
      Result.e_ind := br.ReadInt32;
      Result.inp_t := br.ReadNullable(br->LoadedParData.Load(br, false));
      Result.otp_t := br.ReadNullable(br->LoadedParData.Load(br, false));
    end;
    
    public property Enum: EnumItems.Enum read EnumItems.Enum.ByIndex(e_ind);
    
    public property HasInput: boolean read inp_t<>nil;
    public property InputT: LoadedParData read inp_t.Value;
    
    public property HasOutput: boolean read otp_t<>nil;
    public property OutputT: LoadedParData read otp_t.Value;
    
  end;
  [PCUAlwaysRestore]
  ObjInfoEnumsInGroup = sealed class(EnumsInGroup)
    private _enums: array of EnumWithObjInfo;
    
    private constructor(enums: array of EnumWithObjInfo) := self._enums := enums;
    private constructor := raise new InvalidOperationException;
    
    static constructor := DefineLoader(GK_ObjInfo,
      br->new ObjInfoEnumsInGroup(br.ReadArr(EnumWithObjInfo.Load))
    );
    
    public function Enums := _enums;
    
    public function IsBitfield: boolean; override := false;
    
    public function AllEnums: sequence of Enum; override := self.Enums.Select(r->r.Enum);
    
    public procedure MarkReferenced; override :=
      foreach var r in Enums do
      begin
        r.Enum.UseFromGroup;
        if r.HasInput then
          r.InputT.MarkReferenced;
        if r.HasOutput then
          r.OutputT.MarkReferenced;
      end;
    
    public function EnmrBindings(pars: array of LoadedParData): sequence of EnumToTypeBindingInfo;
    begin
      
      if Enums.Any(r->r.HasInput) then
      begin
        var data_par_i := pars.FindIndex(par->
          (par.Name<>nil) and par.Name.EndsWith('_value')
          and (par.CalculatedDirectType = KnownDirectTypes.IntPtr)
          and (par.CalculatedPtr=0)
          and par.CalculatedReadonlyLvls.SequenceEqual(|1|)
        );
        if data_par_i=-1 then
          raise new InvalidOperationException;
        var size_par_i := data_par_i-1;
        if not pars[size_par_i].Name.EndsWith('_value_size') then
          raise new NotImplementedException;
        yield new EnumToTypeBindingInfo(size_par_i, data_par_i, nil); 
      end;
      
      if Enums.Any(r->r.HasOutput) then
      begin
        var data_par_i := pars.FindIndex(par->
          (par.Name<>nil) and par.Name.EndsWith('_value')
          and (par.CalculatedDirectType = KnownDirectTypes.IntPtr)
          and (par.CalculatedPtr=0)
          and not par.CalculatedReadonlyLvls.Any
        );
        if data_par_i=-1 then
          raise new InvalidOperationException;
        var size_par_i := data_par_i-1;
        if not pars[size_par_i].Name.EndsWith('_value_size') then
          raise new NotImplementedException;
        var ret_size_par_i := data_par_i+1;
        if not pars[ret_size_par_i].Name.EndsWith('_value_size_ret') then
          raise new NotImplementedException;
        yield new EnumToTypeBindingInfo(size_par_i, data_par_i, ret_size_par_i); 
      end;
      
    end;
    
  end;
  
  EnumWithPropList = record
    private e_ind: integer;
    private prop_t: LoadedParData;
    private list_end_ind: integer?; // if "nil" then not a list (single value)
    
    public static function Load(br: BinReader): EnumWithPropList;
    begin
      Result.e_ind := br.ReadInt32;
      Result.prop_t := LoadedParData.Load(br, false);
      Result.list_end_ind := br.ReadIndexOrNil;
    end;
    
    public property Enum: EnumItems.Enum read EnumItems.Enum.ByIndex(e_ind);
    
    public property PropertyT: LoadedParData read prop_t;
    
    public property IsValueList: boolean read list_end_ind<>nil;
    public property ValueListEnd: EnumItems.Enum read EnumItems.Enum.ByIndex(list_end_ind.Value);
    
    public function AllEnums: sequence of EnumItems.Enum;
    begin
      yield Enum;
      if IsValueList then
        yield ValueListEnd;
    end;
    
  end;
  [PCUAlwaysRestore]
  PropListEnumsInGroup = sealed class(EnumsInGroup)
    private _enums: array of EnumWithPropList;
    private global_list_end_inds: array of integer;
    
    private constructor(enums: array of EnumWithPropList; global_list_end_inds: array of integer);
    begin
      self._enums := enums;
      self.global_list_end_inds := global_list_end_inds;
    end;
    private constructor := raise new InvalidOperationException;
    
    static constructor := DefineLoader(GK_PropList,
      br->new PropListEnumsInGroup(br.ReadArr(EnumWithPropList.Load), br.ReadArr(br->br.ReadInt32))
    );
    
    public function Enums := _enums;
    
    public function GlovalListEnds := Enum.MakeLazySeq(global_list_end_inds).ToSeq;
    
    public function IsBitfield: boolean; override := false;
    
    public function AllEnums: sequence of Enum; override := self.Enums.SelectMany(r->r.AllEnums) + GlovalListEnds;
    
    public procedure MarkReferenced; override;
    begin
      foreach var r in Enums do
      begin
        r.Enum.UseFromGroup;
        r.PropertyT.MarkReferenced;
        if r.IsValueList then
          r.ValueListEnd.Use(false);
      end;
      foreach var e in GlovalListEnds do
        e.Use(false);
    end;
    
  end;
  
  {$endregion EnumsInGroup}
  
  {$region CommonDirectNamedType}
  
  CommonDirectNamedType<TSelf> = abstract class(NamedLoadedItem<TSelf, ApiVendorLName>, ILoadedNamedType, IDirectNamedType)
  where TSelf: NamedItem<TSelf, ApiVendorLName>, ILoadedNamedType, IDirectNamedType; //TODO #2640: Доделать для классов, чтобы можно было указывать CommonDirectNamedType
    
    static constructor;
    begin
      TypeLookup.RegisterNameLookupFunc(TSelf.ByName);
    end;
    
    protected static procedure RegisterTypeKind(kind: TypeRefKind) :=
      TypeLookup.RegisterIndexDerefFunc(kind, inherited ByIndex);
    
    //TODO mono#11034
    public function {ILoadedNamedType.}IsVoid := false;
    
    //TODO mono#11034
    public function {ILoadedNamedType.}FeedToTypeTable := System.ValueTuple.Create(0, nil as array of integer, IDirectNamedType(self));
    
    public function MakeWriteProc: NamedItemWriteProc; abstract;
    
    //TODO mono#11034
    function {IDirectNamedType.}IsInternalOnly := false;
    public function GetTypeOrder: FuncParamTypeOrder; abstract;
    //TODO mono#11034
    public function {IDirectNamedType.}GetRawName: object := self.Name;
    public function MakeWriteableName: string; abstract;
    
  end;
  
  {$endregion CommonDirectNamedType}
  
  {$region Group}
  
  Group = sealed class(CommonDirectNamedType<Group>)
    private castable_to: CastableToList;
    private enums: EnumsInGroup;
    
    private custom_members := new List<array of string>;
    public procedure AddCustomMember(lns: array of string) :=
      custom_members += lns;
    
    public constructor(br: BinReader);
    begin
      inherited Create(new ApiVendorLName(br), false);
      self.castable_to := new CastableToList(br);
      self.enums := EnumsInGroup.Load(br);
    end;
    public constructor(name: ApiVendorLName; castable_to_name: string; enums: EnumsInGroup);
    begin
      inherited Create(name, true);
      self.castable_to := new CastableToList(castable_to_name);
      self.enums := enums;
    end;
    private constructor := raise new InvalidOperationException;
    
    static constructor;
    begin
      RegisterLoader(br->new Group(br));
      RegisterTypeKind(TRK_Group);
    end;
    
    public property Body: EnumsInGroup read enums;
    
    public function GetTypeOrder: FuncParamTypeOrder; override := FPTO_Group;
    
    private function SortedEnums := Body.AllEnums
      .OrderBy(e->Abs(e.Value))
      // Messes up clBool.BLOCKING vs clBool.TRUE order
//      .ThenBy(e->e.Name)
    ;
    
    public procedure MarkBodyReferenced; override;
    begin
      Body.MarkReferenced;
      foreach var t in castable_to.ToSeq do
        t.Use(false);
    end;
    
    public function MakeWriteableName: string; override;
    begin
      Result := self.Name.api + self.Name.l_name + self.Name.vendor_suffix?.ToUpper;
    end;
    
    private function EnumValueStr(e: Enum) :=
      if e.Value=0 then
        '0' else
      if not Body.IsBitfield and (e.Value<=0) then
        e.Value.ToString else
      if Body.IsBitfield and BigInteger(e.Value).IsPowerOfTwo then
        '1 shl '+Log2(e.Value) else
        '$'+e.Value.ToString('X4');
    
    public function BaseSuffixFor(t: IDirectNamedType; allow_simplify: boolean := true): string;
    begin
      Result := '';
      if t=self then exit;
      if t not in castable_to.ToSeq.Cast&<IDirectNamedType> then
        raise new InvalidOperationException;
      if allow_simplify and (t=castable_to.ToSeq.First) then exit;
      Result := t.MakeWriteableName;
      Result[0] := Result[0].ToUpper;
    end;
    
    public function MakeWriteProc: NamedItemWriteProc; override;
    begin
      Result := (prev_written, wr, impl_wr)->
      begin
        var gr_api := self.Name.api;
        
        if not castable_to.ToSeq.Any then
//          Otp($'ERROR: {self} did not have base type');
          raise new InvalidOperationException($'{self} did not have base type');
        
        {$region Prepare}
        
        var zero_enums := Body.AllEnums.Where(e->e.Value=0).ToArray;
        
        var enum_names := new Dictionary<Enum, string>;
        var enum_escaped_names := new Dictionary<Enum, string>;
        foreach var e in Body.AllEnums do
        begin
          var ename := e.Name.l_name;
          if e.Name.vendor_suffix<>nil then
            ename += '_' + e.Name.vendor_suffix;
          if e.Name.api <> gr_api then
            ename := e.Name.api + '_' + ename;
          
          enum_names.Add(e, ename);
          
          if not ename.First.IsLetter then
            ename := '_'+ename else
          if ename in pas_keywords then
            ename := '&'+ename;
          
          enum_escaped_names.Add(e, ename);
        end;
        foreach var e in Body.AllEnums do
        begin
          var get_s := 'get_';
          var ename := enum_names[e];
          if not ename.StartsWith(get_s, true, nil) then continue;
          if not enum_names.Values.Contains(ename.Substring(get_s.Length), StringComparer.OrdinalIgnoreCase) then continue;
          ename := '_'+ename;
          enum_names[e] := ename;
          enum_escaped_names[e] := ename;
        end;
        
        if enum_names.Count=0 then
          Otp($'WARNING: {self} had 0 enums');
        
        var max_scr_w := enum_escaped_names.Values.Select(ename->ename.Length).DefaultIfEmpty(0).Max;
        
        {$endregion Prepare}
        
        foreach var base_t in castable_to.ToSeq index base_t_i do
        begin
          wr += '  ///'#10;
          
          wr += '  ';
          wr += MakeWriteableName;
          wr += BaseSuffixFor(base_t);
          wr += ' = record'#10;
          
          {$region Header}
          
          wr += '    public val: ';
          wr += base_t.Name;
          wr += ';'#10;
          
          wr += '    public constructor(val: ';
          wr += base_t.Name;
          wr += ') := self.val := val;'#10;
          
          if base_t.Name.EndsWith('IntPtr') then
          begin
            var U_prefix := if base_t.Name.StartsWith('U') then $'U' else nil;
            foreach var bit_count in |32,64| do
            begin
              wr += '    public constructor(val: ';
              wr += U_prefix;
              wr += 'Int';
              wr += bit_count;
              wr += ') := self.val := new ';
              wr += base_t.Name;
              wr += '(val);'#10;
            end;
          end;
          
          wr += '    '#10;
          
          {$endregion Header}
          
          {$region operator implicit}
          
          foreach var old_base_t in castable_to.ToSeq.Take(base_t_i) do
          begin
            
            foreach var (t1,t2) in |(base_t,old_base_t), (old_base_t,base_t)| do
            begin
              wr += '    public static function operator implicit(v: ';
              wr += MakeWriteableName;
              wr += BaseSuffixFor(t1);
              wr += '): ';
              wr += MakeWriteableName;
              wr += BaseSuffixFor(t2);
              wr += ' :='#10;
              wr += '      new ';
              wr += MakeWriteableName;
              wr += BaseSuffixFor(t2);
              wr += '(v.val);'#10;
            end;
            
            wr += '    '#10;
          end;
          
          {$endregion operator implicit}
          
          {$region Enums}
          
          foreach var e in SortedEnums do
          begin
            wr += '    public static property ';
            var ename_scr := enum_escaped_names[e];
            wr += ename_scr;
            wr += ': ';
            loop max_scr_w-ename_scr.Length do
              wr += ' ';
            wr += MakeWriteableName;
            wr += BaseSuffixFor(base_t);
            wr += ' read new ';
            wr += MakeWriteableName;
            wr += BaseSuffixFor(base_t);
            wr += '(';
            wr += EnumValueStr(e);
            wr += ');'#10;
          end;
          
          wr += '    '#10;
          {$endregion Enums}
          
          if Body.IsBitfield then
          begin
            {$region Flag compinations}
            
            if zero_enums.Any then
            begin
              wr += '    public property ANY_FLAGS: boolean read self.val<>0;'#10;
              wr += '    '#10;
            end;
            
            foreach var comb_op in |'operator+', 'operator or'| do
            begin
              wr += '    public static function ';
              wr += comb_op;
              wr += '(v1, v2: ';
              wr += MakeWriteableName;
              wr += BaseSuffixFor(base_t);
              wr += ') := new ';
              wr += MakeWriteableName;
              wr += BaseSuffixFor(base_t);
              wr += '(v1.val or v2.val);'#10;
            end;
            wr += '    '#10;
            
            wr += '    public static procedure operator+=(var v1: ';
            wr += MakeWriteableName;
            wr += BaseSuffixFor(base_t);
            wr += '; v2: ';
            wr += MakeWriteableName;
            wr += BaseSuffixFor(base_t);
            wr += ') := v1 := v1+v2;'#10;
            wr += '    '#10;
            
            wr += '    public static function operator in(v1, v2: ';
            wr += MakeWriteableName;
            wr += BaseSuffixFor(base_t);
            wr += ') := v1.val and v2.val = v1.val;'#10;
            wr += '    '#10;
            
            {$endregion Flag compinations}
          end;
          
          {$region ToString}
          
          wr += '    public function ToString: string; override;'#10;
          wr += '    begin'#10;
          if Body.IsBitfield then
          begin
            wr += '      var res := new StringBuilder;'#10;
            wr += '      var left_val := self.val;'#10;
            wr += '      if left_val=0 then'#10;
            wr += '      begin'#10;
            wr += '        Result := ''';
            if zero_enums.Any then
              wr.WriteSeparated(zero_enums,
                (wr,e)->(wr += enum_names[e]), '+'
              ) else
            begin
              wr += MakeWriteableName;
              wr += BaseSuffixFor(base_t);
              wr += '[0]';
            end;
            wr += ''';'#10;
            wr += '        exit;'#10;
            wr += '      end;'#10;
          end;
          var prev_vals := if Body.IsBitfield then nil else new HashSet<int64>;
          foreach var e in SortedEnums do
          begin
            if Body.IsBitfield and (e.Value=0) then continue;
            if (prev_vals<>nil) and not prev_vals.Add(e.Value) then continue;
            
            wr += '      if ';
            wr += enum_escaped_names[e];
            wr += if Body.IsBitfield then ' in ' else ' = ';
            wr += 'self then'#10;
            
            if Body.IsBitfield then
            begin
              wr += '      begin'#10;
              
              wr += '        res += ''';
              wr += enum_names[e];
              wr += '+'';'#10;
              
              wr += '        left_val := left_val and not ';
              wr += enum_escaped_names[e];
              wr += '.val;'#10;
              
              wr += '      end;'#10;
            end else
            begin
              
              wr += '        Result := ''';
              wr += enum_names[e];
              wr += ''' else'#10;
              
            end;
            
          end;
          if Body.IsBitfield then
          begin
            wr += '      if left_val<>0 then'#10;
            wr += '      begin'#10;
            wr += '        res += ''';
            wr += MakeWriteableName;
            wr += BaseSuffixFor(base_t);
            wr += '['';'#10;
            wr += '        res += self.val.ToString;'#10;
            wr += '        res += '']+'';'#10;
            wr += '      end;'#10;
            wr += '      res.Length -= 1;'#10;
            wr += '      Result := res.ToString;'#10;
          end else
          begin
            wr += '        Result := $''';
            wr += MakeWriteableName;
            wr += BaseSuffixFor(base_t);
            wr += '[{self.val}]'';'#10;
          end;
          wr += '    end;'#10;
          
          wr += '    '#10;
          {$endregion ToString}
          
          {$region Custom}
          
          foreach var lns in self.custom_members do
            foreach var l in lns.Append(nil) do
            begin
              wr += '    ';
              wr += l;
              wr += #10;
            end;
          
          {$endregion Custom}
          
          wr += '  end;'#10;
        end;
        
        if castable_to.ToSeq.Skip(1).Any then
        begin
          wr += '  ///'#10;
          wr += '  ';
          wr += MakeWriteableName;
          wr += BaseSuffixFor(castable_to.ToSeq.First, false);
          wr += ' = ';
          wr += MakeWriteableName;
          wr += ';'#10;
        end;
        
        wr += '  '#10;
      end;
    end;
    
    protected procedure LogContents(l: Logger); override;
    begin
      
      var bitfield_suf := '';
      if Body.IsBitfield then
        bitfield_suf := ' (Bitfield)';
      l.Otp($'# {self.MakeWriteableName} ({self.Name}) : {castable_to.ToSeq.JoinToString}{bitfield_suf}');
      
      var gr_api := self.Name.api;
      foreach var e in SortedEnums do
      begin
        var sb := new StringBuilder(#9);
        
        sb += e.Name.ToString(gr_api, false);
        
        sb += '[';
        sb += EnumValueStr(e);
        sb += ']';
        
        l.Otp(sb.ToString);
      end;
      
      l.Otp($'');
    end;
    
    public static procedure LogAllPropLists;
    begin
      var log := new FileLogger(GetFullPathRTA('Log/All ObjPropList''s.log'));
      loop 3 do log.Otp('');
      ForEachDefined(g->
      begin
        var enums := g.enums as PropListEnumsInGroup;
        if enums=nil then exit;
        
        log.Otp($'# {g.MakeWriteableName}');
        var api := g.Name.api;
        
        foreach var gle in enums.GlovalListEnds do
          log.Otp(gle.Name.ToString(api, false));
        
        foreach var r: EnumWithPropList in enums.Enums do
        begin
          log.Otp($'--- {r.Enum.Name.ToString(api, false)}');
          log.Otp('!type');
          log.Otp(r.PropertyT.ToString(false));
          if not r.IsValueList then continue;
          log.Otp('!list_end');
          log.Otp(r.ValueListEnd.Name.ToString(api, false));
        end;
        
        log.Otp('');
      end);
      loop 1 do log.Otp('');
      log.Close;
    end;
    
  end;
  
  GroupFixer = abstract class(NamedItemCommonFixer<GroupFixer, Group>)
    
  end;
  
  {$endregion Group}
  
  {$region IdClass}
  
  IdClass = sealed class(CommonDirectNamedType<IdClass>)
    private castable_to: CastableToList;
    
    public constructor(br: BinReader);
    begin
      inherited Create(new ApiVendorLName(br), false);
      self.castable_to := new CastableToList(br);
    end;
    public constructor(name: ApiVendorLName; castable_to_name: string);
    begin
      inherited Create(name, true);
      self.castable_to := new CastableToList(castable_to_name);
    end;
    private constructor := raise new InvalidOperationException;
    
    static constructor;
    begin
      RegisterLoader(br->new IdClass(br));
      RegisterTypeKind(TRK_IdClass);
    end;
    
    public function GetTypeOrder: FuncParamTypeOrder; override := FPTO_IdClass;
    
    public procedure MarkBodyReferenced; override;
    begin
      foreach var t in castable_to.ToSeq do
        t.Use(false);
    end;
    
    public function MakeWriteableName: string; override;
    begin
      Result := self.Name.api + self.Name.l_name.Split(' ').Select(w->'_'+w).JoinToString('');
      if self.Name.vendor_suffix=nil then exit;
      Result += '_';
      Result += self.Name.vendor_suffix;
    end;
    
    public function MakeWriteProc: NamedItemWriteProc; override;
    begin
      Result := (prev_written, wr, impl_wr)->
      begin
        wr += '  ///%';
        wr += MakeWriteableName;
        wr += '%'#10;
        var base_tname := castable_to.ToSeq.Single.Name;
        
        wr += '  ';
        wr += MakeWriteableName;
        wr += ' = record'#10;
        
        wr += '    public val: ';
        wr += base_tname;
        wr += ';'#10;
        
        wr += '    '#10;
        
        wr += '    public constructor(val: ';
        wr += base_tname;
        wr += ') := self.val := val;'#10;
        
        if base_tname.EndsWith('IntPtr') then
        begin
          var U_prefix := if base_tname.StartsWith('U') then $'U' else nil;
          foreach var bit_count in |32,64| do
          begin
            wr += '    public constructor(val: ';
            wr += U_prefix;
            wr += 'Int';
            wr += bit_count;
            wr += ') := self.val := new ';
            wr += base_tname;
            wr += '(val);'#10;
          end;
        end;
        
        wr += '    '#10;
        
        wr += '    public static property Zero: ';
        wr += MakeWriteableName;
        wr += ' read default(';
        wr += MakeWriteableName;
        wr += ');'#10;
        
        wr += '    '#10;
        
        wr += '    private static val_sz := Marshal.SizeOf&<';
        wr += base_tname;
        wr += '>;'#10;
        wr += '    public static property Size: integer read val_sz;'#10;
        wr += '    public property ValSize: integer read integer(val_sz);'#10;
        
        wr += '    '#10;
        
        wr += '    public function ToString: string; override := $''';
        wr += MakeWriteableName;
        wr += '[{self.val}]'';'#10;
        
        wr += '    '#10;
        
        wr += '  end;'#10;
        
        wr += '  '#10;
      end;
    end;
    
    protected procedure LogContents(l: Logger); override;
    begin
      l.Otp($'# {self.MakeWriteableName} ({self.Name}) : {castable_to.ToSeq.JoinToString}');
      l.Otp($'');
    end;
    
  end;
  
  IdClassFixer = abstract class(NamedItemCommonFixer<IdClassFixer, IdClass>)
    
  end;
  
  {$endregion IdClass}
  
  {$region Struct}
  
  StructField = record
    private descr := default(string);
    private base: LoadedParData;
    private vis := default(string);
    private def_val := default(string);
    
    private const default_vis = 'public';
    
    public constructor(br: BinReader);
    begin
      self.descr := nil;
      self.base := LoadedParData.Load(br, true);
      self.vis := default_vis;
      self.def_val := nil;
    end;
    public constructor(name: string; t: IDirectNamedType; descr, vis, def_val: string);
    begin
      self.descr := descr;
      self.base := new LoadedParData(name, t, ParArrSizeNotArray.Instance);
      self.vis := vis ?? default_vis;
      self.def_val := def_val;
    end;
    ///--
    public constructor := raise new InvalidOperationException;
    
    public procedure MarkReferenced := base.MarkReferenced;
    
    public function ToString(write_vis: boolean?; escape: boolean): string;
    begin
      var sb := new StringBuilder;
      if write_vis=nil then
        write_vis := vis<>default_vis;
      if write_vis.Value then
      begin
        sb += vis;
        sb += ' ';
      end;
      if escape and (base.Name in pas_keywords) then
        sb += '&';
      sb += base.ToString(true);
      if def_val<>nil then
      begin
        sb += ' := ';
        sb += def_val;
      end;
      Result := sb.ToString;
    end;
    public function ToString: string; override := ToString(nil, false);
    
  end;
  
  Struct = sealed class(CommonDirectNamedType<Struct>)
    private fields: array of StructField?;
    
    private custom_members := new List<array of string>;
    public procedure AddCustomMember(lns: array of string) :=
      custom_members += lns;
    
    public constructor(name: ApiVendorLName; fields: array of StructField?; from_fixer: boolean);
    begin
      inherited Create(name, from_fixer);
      self.fields := fields;
    end;
    
    static constructor;
    begin
      RegisterLoader(br->
        new Struct(new ApiVendorLName(br), br.ReadArr&<StructField?>(br->new StructField(br)), false)
      );
      RegisterTypeKind(TRK_Struct);
    end;
    
    public function GetTypeOrder: FuncParamTypeOrder; override := FPTO_Struct;
    
    public procedure MarkBodyReferenced; override;
    begin
      foreach var f in fields do
        if f<>nil then
          f.Value.MarkReferenced;
    end;
    
    public function MakeWriteableName: string; override;
    begin
      Result := '';
      if self.Name.api<>nil then
        Result += self.Name.api + '_';
      Result += self.Name.l_name;
      Result += self.Name.vendor_suffix;
    end;
    
    private static value_string_cache := new Dictionary<integer, Struct>;
    private function MakeValueStringStruct(par: LoadedParData): Struct;
    begin
      if par.CalculatedPtr<>0 then
        raise new InvalidOperationException;
      if par.CalculatedReadonlyLvls.Any then
        raise new InvalidOperationException;
      if par.ValCombo<>nil then
        raise new InvalidOperationException;
      var str_size := ParArrSizeConst(par.ArrSize).Value;
      
      if value_string_cache.TryGetValue(str_size, Result) then exit;
      
      var val_str_name := default(ApiVendorLName);
      val_str_name.l_name := 'value_ansi_string_'+str_size;
      
      var f := default(StructField);
      f.base := new LoadedParData('body', KnownDirectTypes.String, par.ArrSize);
      Result := new Struct(val_str_name, new Nullable<StructField>[](f), true);
      
      value_string_cache[str_size] := Result;
    end;
    
    public function MakeWriteProc: NamedItemWriteProc; override;
    begin
      
      if fields.Length=0 then
        raise new NotImplementedException;
      
      {$region value_ansi_string}
      
      if fields.Length=1 then
      begin
        var f := fields.Single;
        var as_par := f.Value.base;
        if (fields.Single.Value.base.CalculatedDirectType = KnownDirectTypes.String) then
        begin
          {$ifdef DEBUG}
          if self not in value_string_cache.Values then
            raise new InvalidOperationException;
          {$endif DEBUG}
          
          var len := ParArrSizeConst(as_par.ArrSize).Value;
          
          Result := (prev_written, wr, impl_wr)->
          begin
            wr += '  [StructLayout(LayoutKind.Explicit, Size = ';
            wr += len;
            wr += ')]'#10;
            
            wr += '  ///'#10;
            wr += '  ';
            wr += MakeWriteableName;
            wr += ' = record'#10;
            
            wr += '    '#10;
            
            wr += '    public property AnsiChars[i: integer]: Byte'#10;
            wr += '      read Marshal.ReadByte(new IntPtr(@self), i)'#10;
            wr += '      write Marshal.WriteByte(new IntPtr(@self), i, value); default;'#10;
            
            wr += '    public property Chars[i: integer]: char read char(AnsiChars[i]) write AnsiChars[i] := Byte(value);'#10;
            wr += '    '#10;
            
            wr += '    public constructor(s: string; allow_trim: boolean := false);'#10;
            wr += '    begin'#10;
            wr += '      var len := s.Length;'#10;
            wr += '      if len>';
            wr += len-1;
            wr += ' then'#10;
            wr += '        if allow_trim then'#10;
            wr += '          len := ';
            wr += len-1;
            wr += ' else'#10;
            wr += '          raise new System.OverflowException;'#10;
            wr += '      '#10;
            wr += '      self.AnsiChars[len] := 0;'#10;
            wr += '      for var i := 0 to len-1 do'#10;
            wr += '        self.Chars[i] := s[i];'#10;
            wr += '      '#10;
            wr += '    end;'#10;
            wr += '    '#10;
            
            wr += '    public function ToString: string; override;'#10;
            wr += '    begin'#10;
            //TODO Не очень хорошо...
            // - Как будет NativeUtils - надо будет протестить, как быстрее
            wr += '      var copy := self;'#10;
            wr += '      Result := Marshal.PtrToStringAnsi(new IntPtr(@copy));'#10;
            wr += '    end;'#10;
            wr += '    '#10;
            
            wr += '    public static function operator implicit(s: string): ';
            wr += MakeWriteableName;
            wr += ' := new ';
            wr += MakeWriteableName;
            wr += '(s);'#10;
            wr += '    public static function operator explicit(s: string): ';
            wr += MakeWriteableName;
            wr += ' := new ';
            wr += MakeWriteableName;
            wr += '(s, true);'#10;
            wr += '    '#10;
            
            wr += '    public static function operator implicit(s: ';
            wr += MakeWriteableName;
            wr += '): string := s.ToString;'#10;
            wr += '    '#10;
            
            if self.custom_members.Any then
              raise new InvalidOperationException;
            
            wr += '  end;'#10;
            
            wr += '  '#10;
          end;
          
          exit;
        end;
      end;
      
      {$endregion value_ansi_string}
      
      for var i := 0 to fields.Length-1 do
      begin
        if fields[i]=nil then continue;
        var f := fields[i].Value;
        var as_par := f.base;
        if as_par.CalculatedDirectType <> KnownDirectTypes.String then continue;
        
        var val_str_rec := MakeValueStringStruct(as_par);
        f.base := new LoadedParData(as_par.Name, val_str_rec, ParArrSizeNotArray.Instance);
        fields[i] := f;
        
      end;
      
      foreach var f in fields.OfType&<StructField> do
        f.base.CalculatedDirectType.Use(true);
      
      {$region CodeGen}
      
      Result := (prev_written, wr, impl_wr)->
      begin
        wr += '  ///'#10;
        
        wr += '  ';
        wr += MakeWriteableName;
        wr += ' = record'#10;
        
        foreach var nf in fields do
        begin
          wr += '    ';
          if nf<>nil then
          begin
            var f := nf.Value;
            wr += f.ToString(true, true);
            wr += ';';
            if f.descr<>nil then
            begin
              wr += ' // ';
              wr += f.descr;
            end;
          end;
          wr += #10;
        end;
        wr += '    '#10;
        
        begin
          var ctor_fields := fields.OfType&<StructField>.Where(f->f.def_val=nil);
          var max_ctor_field_w := ctor_fields.Max(f->f.base.Name.Length);
          
          wr += '    public constructor(';
          wr.WriteSeparated(ctor_fields,
            (wr,f)->(wr += f.ToString(false, true)), '; '
          );
          wr += ');'#10;
          
          wr += '    begin'#10;
          
          foreach var f in ctor_fields do
          begin
            wr += '      self.';
            wr += f.base.Name;
            loop max_ctor_field_w-f.base.Name.Length do
              wr += ' ';
            wr += ' := ';
            if f.base.Name in pas_keywords then
              wr += '&';
            wr += f.base.Name;
            wr += ';'#10;
          end;
          
          wr += '    end;'#10;
          
          wr += '    '#10;
        end;
        
        {$region Custom}
        
        foreach var lns in self.custom_members do
          foreach var l in lns.Append(nil) do
          begin
            wr += '    ';
            wr += l;
            wr += #10;
          end;
        
        {$endregion Custom}
        
        wr += '  end;'#10;
        
        wr += '  '#10;
      end;
      
      {$endregion CodeGen}
      
    end;
    
    protected procedure LogContents(l: Logger); override;
    begin
      l.Otp($'# {self.MakeWriteableName} ({self.Name})');
      foreach var f in fields do
        l.Otp(#9 + f?.ToString??'*');
      l.Otp($'');
    end;
    
  end;
  
  StructFixer = abstract class(NamedItemCommonFixer<StructFixer, Struct>)
    
  end;
  
  {$endregion Struct}
  
  {$region Delegate}
  
  Delegate = sealed class(CommonDirectNamedType<Delegate>)
    private pars: array of LoadedParData;
    
    static constructor;
    begin
      RegisterLoader(br->
      begin
        Result := new Delegate(new ApiVendorLName(br), false);
        Result.pars := br.ReadArr((br,par_i)->LoadedParData.Load(br, par_i<>0));
      end);
      RegisterTypeKind(TRK_Delegate);
    end;
    
    private function is_proc := pars[0].IsNakedVoid;
    
    public function Parameters := pars;
    public function ExistingParameters := pars.Skip(Ord(is_proc));
    
    public function GetTypeOrder: FuncParamTypeOrder; override := FPTO_Delegate;
    
    public procedure MarkBodyReferenced; override;
    begin
      foreach var p in Parameters do
        p.MarkReferenced;
    end;
    
    public function MakeWriteableName: string; override;
    begin
      Result := self.Name.api + self.Name.l_name + self.Name.vendor_suffix;
    end;
    
    public function MakeWriteProc: NamedItemWriteProc; override;
    begin
      
      foreach var par in ExistingParameters do
        par.CalculatedDirectType.Use(true);
      
      Result := (prev_written, wr, impl_wr)->
      begin
        
        wr += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
        
        wr += '  [UnmanagedFunctionPointer(CallingConvention.StdCall)]'#10;
        
        wr += '  ///'#10;
        
        wr += '  ';
        wr += MakeWriteableName;
        wr += ' = ';
        wr += if is_proc then 'procedure' else 'function';
        if ExistingParameters.Any then
        begin
          wr += '(';
          wr.WriteSeparated(ExistingParameters,
            (wr,par)->
            begin
              if par.Name in pas_keywords then
                wr += '&';
              wr += par.ToString(true);
            end, '; '
          );
          wr += ')';
        end;
        if not is_proc then
        begin
          wr += ': ';
          wr += pars[0].ToString(false);
        end;
        wr += ';'#10;
        
        wr += '  '#10;
      end;
      
    end;
    
    protected procedure LogContents(l: Logger); override;
    begin
      l.Otp($'# {self.MakeWriteableName} ({self.Name})');
      if pars[0].IsNakedVoid then
        l.Otp(#9'procedure') else
        l.Otp(#9'function: ' + pars[0].ToString(false));
      foreach var p in Parameters.Skip(1) do
        l.Otp(#9 + p.ToString(true));
      l.Otp($'');
    end;
    
  end;
  
  DelegateFixer = abstract class(NamedItemCommonFixer<DelegateFixer, Delegate>)
    
  end;
  
  {$endregion Delegate}
  
implementation

uses EnumItems;

{$region Fixers} type
  
  {$region Group}
  
  {$region New}
  
  [PCUAlwaysRestore]
  GroupAdder = sealed class(GroupFixer)
    private castable_to_name: string;
    private is_bitfield: boolean;
    private enums := new List<ValueTuple<ApiVendorLName,int64>>;
    
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, true);
      var data_enmr := data.GetEnumerator;
      
      if not data_enmr.MoveNext then raise new FormatException;
      self.castable_to_name := data_enmr.Current.Trim;
      
      if not data_enmr.MoveNext then raise new FormatException;
      self.is_bitfield := boolean.Parse(data_enmr.Current);
      
      while data_enmr.MoveNext do
      begin
        var l := data_enmr.Current;
        if string.IsNullOrWhiteSpace(l) then continue;
        
        var spl := l.Split('=');
        if spl.Length<>2 then raise new FormatException;
        
        var ename := ApiVendorLName.Parse(spl[0].Trim);
        
        var val_s := spl[1].Trim;
        var val := if val_s.StartsWith('0x') then
          Convert.ToInt64(val_s, 16) else
          Convert.ToInt64(val_s);
        
        enums += ValueTuple.Create(ename, val);
      end;
      
    end;
    
    static constructor;
    begin
      RegisterLoader('add',
        (name, data)->new GroupAdder(name, data)
      );
      RegisterPreAdder(gf->
      begin
        var ga := GroupAdder(gf);
        var enum_items := new Enum[ga.enums.Count];
        for var i := 0 to enum_items.Length-1 do
        begin
          var (ename, val) := ga.enums[i];
          var e := Enum.ByName(ename);
          if e=nil then
          begin
            e := new Enum(ename, val, false, true);
            e.UseFromReqList;
          end else
          if e.Value<>val then
            raise new InvalidOperationException;
          enum_items[i] := e;
        end;
        var enums := new SimpleEnumsInGroup(ga.is_bitfield, enum_items);
        Result := new Group(ga.Name, ga.castable_to_name, enums);
      end);
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion New}
  
  {$region Name}
  
  [PCUAlwaysRestore]
  GroupNameFixer = sealed class(GroupFixer)
    public new_name: ApiVendorLName;
    
    static constructor := RegisterLoader('rename',
      (name, data)->new GroupNameFixer(name, data)
    );
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, false);
      var name_l := data.Single(l->not string.IsNullOrWhiteSpace(l));
      self.new_name := ApiVendorLName.Parse( name_l );
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      gr.Rename(new_name);
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion Name}
  
  {$region Base}
  
  [PCUAlwaysRestore]
  GroupBaseFixer = sealed class(GroupFixer)
    public new_base_name: string;
    
    static constructor := RegisterLoader('base',
      (name, data)->new GroupBaseFixer(name, data)
    );
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, false);
      self.new_base_name := data.Single(l->not string.IsNullOrEmpty(l)).Trim;
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      if gr.castable_to.ToSeq.Any then
        raise new InvalidOperationException;
      gr.castable_to := new CastableToList(new_base_name);
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion Base}
  
  {$region CustopMember}
  
  [PCUAlwaysRestore]
  GroupCustopMemberFixer = sealed class(GroupFixer)
    public member_lns: array of string;
    
    static constructor := RegisterLoader('cust_memb',
      (name, data)->new GroupCustopMemberFixer(name, data)
    );
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, false);
      
      var res := new List<string>;
      var skiped := new List<string>;
      
      foreach var l in data do
        if not string.IsNullOrWhiteSpace(l) then
        begin
          res.AddRange(skiped);
          skiped.Clear;
          res += l;
        end else
        if res.Count<>0 then
          skiped += l;
      
      member_lns := res.ToArray;
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      gr.AddCustomMember( member_lns );
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion CustopMember}
  
  {$endregion Group}
  
  {$region IdClass}
  
  {$region New}
  
  [PCUAlwaysRestore]
  IdClassAdder = sealed class(IdClassFixer)
    private tname: string;
    
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, true);
      self.tname := data.Single(l->not string.IsNullOrWhiteSpace(l));
    end;
    
    static constructor;
    begin
      RegisterLoader('add',
        (name, data)->new IdClassAdder(name, data)
      );
      RegisterPreAdder(cl_f->
      begin
        var cl_a := IdClassAdder(cl_f);
        Result := new IdClass(cl_a.Name, cl_a.tname);
      end);
    end;
    
    public function Apply(cl: IdClass): boolean; override;
    begin
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion New}
  
  {$endregion IdClass}
  
  {$region Struct}
  
  {$region New}
  
  [PCUAlwaysRestore]
  StructAdder = sealed class(StructFixer)
    private fields: sequence of StructField?;
    
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, true);
      
      self.fields := data.Select(l->
      begin
        Result := default(StructField?);
        l := l.Trim;
        if l='*' then exit;
        
        var split_off_end := function(spl: string): string ->
        begin
          Result := nil;
          
          var ind := l.IndexOf(spl);
          if ind = -1 then exit;
          
          Result := l.Remove(0,ind+spl.Length).Trim;
          l := l.Remove(ind).Trim;
          
        end;
        
        var descr := split_off_end('//');
        var def_val := split_off_end(':=');
        var tname := split_off_end(':'); if tname=nil then raise new FormatException(l);
        
        var vis := default(string);
        begin
          var ind := l.ToCharArray.FindIndex(char.IsWhiteSpace);
          if ind<>-1 then
          begin
            vis := l.Remove(ind);
            l := l.Substring(ind).Trim;
          end;
        end;
        
        Result := new StructField(l, TypeLookup.FromNameString(tname), descr, vis, def_val);
      end);
      
    end;
    
    static constructor;
    begin
      RegisterLoader('add',
        (name, data)->new StructAdder(name, data)
      );
      RegisterPreAdder(sf->
      begin
        var sa := StructAdder(sf);
        Result := new Struct(sa.Name, sa.fields.ToArray, true);
      end);
    end;
    
    public function Apply(gr: Struct): boolean; override;
    begin
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion New}
  
  {$region CustopMember}
  
  [PCUAlwaysRestore]
  StructCustopMemberFixer = sealed class(StructFixer)
    public member_lns: array of string;
    
    static constructor := RegisterLoader('cust_memb',
      (name, data)->new StructCustopMemberFixer(name, data)
    );
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, false);
      
      var res := new List<string>;
      var skiped := new List<string>;
      
      foreach var l in data do
        if not string.IsNullOrWhiteSpace(l) then
        begin
          res.AddRange(skiped);
          skiped.Clear;
          res += l;
        end else
        if res.Count<>0 then
          skiped += l;
      
      member_lns := res.ToArray;
    end;
    
    public function Apply(s: Struct): boolean; override;
    begin
      s.AddCustomMember( member_lns );
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion CustopMember}
  
  {$endregion Struct}
  
  {$region Delegate}
  
  {$region Name}
  
  [PCUAlwaysRestore]
  DelegateNameFixer = sealed class(DelegateFixer)
    public new_name: ApiVendorLName;
    
    static constructor := RegisterLoader('rename',
      (name, data)->new DelegateNameFixer(name, data)
    );
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, false);
      var name_l := data.Single(l->not string.IsNullOrWhiteSpace(l));
      self.new_name := ApiVendorLName.Parse( name_l );
    end;
    
    public function Apply(d: Delegate): boolean; override;
    begin
      d.Rename(new_name);
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion Name}
  
  {$endregion Delegate}
  
{$endregion Fixers}

begin
  try
    TypeInitHelper.InitType(typeof(PascalBasicType));
    TypeInitHelper.InitType(typeof(TypeCombo));
  except
    on e: Exception do
      ErrOtp(e);
  end;
end.