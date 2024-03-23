unit HashableArrays;

uses System;

type
  HashableReadonlyArray<TSelf, TItem> = abstract class(IEquatable<TSelf>)
  where TSelf: HashableReadonlyArray<TSelf, TItem>;
    private items: array of TItem;
    private static item_is_class := typeof(TItem).IsClass;
    private static equ_comp := System.Collections.Generic.EqualityComparer&<TItem>.Default;
    
    public constructor(items: array of TItem);
    begin
      if items=nil then raise nil;
      self.items := items;
    end;
    protected constructor := raise new InvalidOperationException;
    
    public property Size: integer read items.Length;
    public property Item[ind: integer]: TItem read items[ind]; default;
    public function ItemsSeq := System.Collections.Generic.IReadOnlyList&<TItem>(items as object); //TODO #2886: Надо доделать за ibond-ом...
    
    protected function BodyEquals(other: TSelf): boolean; virtual := true;
    
    public static function operator=(a1,a2: HashableReadonlyArray<TSelf, TItem>): boolean;
    begin
      Result := ReferenceEquals(a1, a2);
      if Result then exit;
      
      if a1.Size <> a2.Size then
        raise new InvalidOperationException;
      
      if not a1.BodyEquals(TSelf(a2)) then
        exit;
      
      for var i := 0 to a1.Size-1 do
        if not equ_comp.Equals(a1.Item[i], a2.Item[i]) then
          exit;
      
      Result := true;
    end;
    public static function operator<>(a1,a2: HashableReadonlyArray<TSelf, TItem>) := not(a1=a2);
    
    public function Equals(other: TSelf) := self=other;
    public function Equals(obj: object): boolean; override :=
      (obj is TSelf(var other)) and self.Equals(other);
    
    protected function HashCodeBitShift: integer; virtual := 0;
    private calculated_hc := default(integer?);
    public function GetHashCode: integer; override;
    begin
      if calculated_hc<>nil then
      begin
        Result := calculated_hc.Value;
        exit;
      end;
      Result := 0;
      
      var sh_c := HashCodeBitShift;
      for var i := 0 to Size-1 do
      begin
        var item := Items[i];
        if item=nil then continue;
        if sh_c<>0 then
          Result := (Result shl sh_c) xor (Result shr (32-sh_c));
        Result := Result xor item.GetHashCode;
      end;
      
      calculated_hc := Result;
    end;
    
  end;
  
end.