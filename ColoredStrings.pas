unit ColoredStrings;
{$zerobasedstrings}

uses Parsing;

type
  ColoredString<TKey> = sealed partial class
    private constructor := raise new System.InvalidOperationException;
  end;
  ColoredStringPart<TKey> = class
    private _key: TKey;
    private range: SIndexRange;
    
    private _root: ColoredString<TKey>;
    private _parent: ColoredStringPart<TKey>;
    private parts: array of ColoredStringPart<TKey>;
    
    private constructor(key: TKey; range: SIndexRange; parts: array of ColoredStringPart<TKey>);
    begin
      self._key  := key;
      self.range := range;
      self.parts := parts;
      foreach var part in parts do
      begin
        {$ifdef DEBUG}
        if part._parent<>nil then raise new System.InvalidOperationException;
        {$endif DEBUG}
        part._parent := self;
      end;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public property Key: TKey read _key;
    public property SubParts: array of ColoredStringPart<TKey> read parts;
    public property TextRange: SIndexRange read range;
    
    public property Root: ColoredString<TKey> read _root;
    public property Parent: ColoredStringPart<TKey> read _parent;
    
    public function GetSection: StringSection;
    public function ToString: string; override := GetSection.ToString;
    
    public procedure &ForEach(use: ColoredStringPart<TKey>->());
    begin
      use(self);
      foreach var part in parts do
        part.ForEach(use);
    end;
    
    public function EnmrTowardsRoot: sequence of ColoredStringPart<TKey>;
    begin
      var p := self;
      repeat
        yield p;
        p := p.Parent;
      until p=nil;
    end;
    
    private key_lookup: Dictionary<TKey, List<ColoredStringPart<TKey>>>;
    private function GetByKey(key: TKey): IList<ColoredStringPart<TKey>>;
    begin
      if key_lookup=nil then
      begin
        key_lookup := new Dictionary<TKey, List<ColoredStringPart<TKey>>>;
        self.ForEach(p->
        begin
          var l: List<ColoredStringPart<TKey>>;
          if not key_lookup.TryGetValue(self.key, l) then
          begin
            l := new List<ColoredStringPart<TKey>>;
            key_lookup[self.key] := l;
          end;
          l += p;
        end);
      end;
      Result := new System.Collections.ObjectModel.ReadOnlyCollection<ColoredStringPart<TKey>>(key_lookup[key]);
    end;
    public property ByKey[key: TKey]: IList<ColoredStringPart<TKey>> read GetByKey; default;
    public function GetAllKeys{: ICollection<TKey>} := key_lookup.Keys;
    
  end;
  
  ColoredString<TKey> = sealed partial class(ColoredStringPart<TKey>)
    private _text: string;
    
    private constructor(key: TKey; text: string; parts: array of ColoredStringPart<TKey>);
    begin
      inherited Create(key, new SIndexRange(0,text.Length), parts);
      self._text := text;
      self.ForEach(p->(p._root := self));
    end;
    
    public property Text: string read _text;
    
  end;
  
  ColoredStringBuilderBase<TKey> = abstract class
    
    protected sb: StringBuilder;
    protected range := SIndexRange.Invalid;
    
    public constructor(sb: StringBuilder);
    begin
      self.sb := sb;
      range.i1 := sb.Length;
    end;
    public constructor := Create(new StringBuilder);
    
    {$region Append}
    
    public procedure Append(ch: char) :=
    if range.i2.IsInvalid then sb += ch else
      raise new System.InvalidOperationException($'{TypeName(self)} is sealed');
    
    public procedure Append(ch: char; c: integer) :=
    loop c do Append(ch);
    
    public procedure Append(s: string) :=
    for var i := 0 to s.Length-1 do Append(s[i]);
    
    public procedure Append(s: StringSection) :=
    for var i := 0 to s.Length-1 do Append(s[i]);
    
    public static procedure operator+=(b: ColoredStringBuilderBase<TKey>; ch: char) := b.Append(ch);
    public static procedure operator+=(b: ColoredStringBuilderBase<TKey>; s: string) := b.Append(s);
    public static procedure operator+=(b: ColoredStringBuilderBase<TKey>; s: StringSection) := b.Append(s);
    
    {$endregion Append}
    
    public procedure MarkSealed := range.i2 := sb.Length;
    
    public procedure AddSubRange(key: TKey; build: ColoredStringBuilderBase<TKey> -> ()); abstract;
    
    protected function GetFixedRange: SIndexRange;
    begin
      Result := self.range;
      if Result.i2.IsInvalid then Result.i2 := sb.Length;
    end;
    protected function GetText: string;
    begin
      var r := GetFixedRange;
      Result := sb.ToString(r.i1, r.Length);
    end;
    
  end;
  UnColoredStringBuilder<TKey> = sealed class(ColoredStringBuilderBase<TKey>)
    
    public procedure AddSubRange(key: TKey; build: ColoredStringBuilderBase<TKey> -> ()); override := build(self);
    
    public function Finish := GetText;
    
  end;
  ColoredStringBuilder<TKey> = sealed class(ColoredStringBuilderBase<TKey>)
    private parts := new List<ColoredStringBuilder<TKey>>;
    private _key: TKey;
    
    public constructor(key: TKey; sb: StringBuilder);
    begin
      inherited Create(sb);
      self._key := key;
    end;
    public constructor(key: TKey) := Create(key, new StringBuilder);
    private constructor := raise new System.InvalidOperationException;
    
    public property Key: TKey read _key;
    
    public procedure AddSubRange(key: TKey; build: ColoredStringBuilderBase<TKey> -> ()); override;
    begin
      var part := new ColoredStringBuilder<TKey>(key, self.sb);
      build(part);
      part.MarkSealed;
      self.parts += part;
    end;
    
    private function FinishAllParts: array of ColoredStringPart<TKey>;
    begin
      SetLength(Result, parts.Count);
      for var i := 0 to parts.Count-1 do
        Result[i] := parts[i].FinishAsPart;
    end;
    private function FinishAsPart :=
    new ColoredStringPart<TKey>(self.key, self.GetFixedRange, FinishAllParts);
    
    public function Finish: ColoredString<TKey>;
    begin
      Result := new ColoredString<TKey>(self.key, GetText, FinishAllParts);
      var i0 := self.range.i1;
      Result.ForEach(p->
      begin
        p.range.i1 -= i0;
        p.range.i2 -= i0;
      end);
    end;
    
  end;
  
function ColoredStringPart<TKey>.GetSection := new StringSection(Root.text, self.range);

end.