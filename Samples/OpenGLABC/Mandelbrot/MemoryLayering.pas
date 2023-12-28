unit MemoryLayering;

{$savepcu false} //TODO

type
  MemoryLayerDataList<T> = sealed class(IEnumerable<T>)
    private a := new T[16];
    private i1 := 0;
    private i2 := 0;
    {$ifdef DEBUG}
    private list_v := int64(0);
    {$endif DEBUG}
    
    private procedure IncInd(var ind: integer) :=
      ind := (ind+1) mod a.Length;
    
    public function IsEmpty := i1=i2;
    
    public function PeekOldest: T;
    begin
      {$ifdef DEBUG}
      if IsEmpty then raise new System.InvalidOperationException;
      {$endif DEBUG}
      Result := a[i1];
    end;
    public function RemoveOldest: T;
    begin
      {$ifdef DEBUG}
      if IsEmpty then raise new System.InvalidOperationException;
      list_v += 1;
      {$endif DEBUG}
      
      Result := a[i1];
      a[i1] := default(T);
      IncInd(i1);
      
    end;
    
    public procedure TryRemoveEachSingle(valid_remove_table: Dictionary<T,boolean>; on_rem: T->());
    begin
      {$ifdef DEBUG}
      list_v += 1;
      {$endif DEBUG}
      
      var look_i := i1;
      var store_i := i1;
      while look_i<>i2 do
      begin
        var o := a[look_i];
        
        var valid_remove: boolean;
        var need_remove := valid_remove_table.TryGetValue(o, valid_remove);
        {$ifdef DEBUG}
        if need_remove and not valid_remove then
          $'Could not remove from memory: {o}'.Println;
//          raise new System.InvalidOperationException;
        {$endif DEBUG}
        valid_remove_table[o] := false;
        
        if need_remove then
          on_rem(o) else
        begin
          if look_i<>store_i then
            a[store_i] := o;
          IncInd(store_i);
        end;
        
        IncInd(look_i);
      end;
      
      self.i2 := store_i;
      while look_i<>store_i do
      begin
        a[store_i] := default(T);
        IncInd(store_i);
      end;
      
    end;
    
    public procedure AddNewest(o: T);
    begin
      {$ifdef DEBUG}
      if o in self then
        raise new System.InvalidOperationException;
      list_v += 1;
      {$endif DEBUG}
      a[i2] := o;
      i2 := (i2+1) mod a.Length;
      if i1<>i2 then exit;
      var n_a := new T[a.Length*2];
      for var d := 0 to a.Length-1 - i1 do
        n_a[d] := a[i1+d];
      for var d := 0 to i1-1 do
        n_a[a.Length-i1+d] := a[d];
      i1 := 0;
      i2 := a.Length;
      a := n_a;
    end;
    
    private function Enmr: sequence of T;
    begin
      var enmr_i := self.i1;
      {$ifdef DEBUG}
      var org_list_v := list_v;
      {$endif DEBUG}
      while enmr_i<>i2 do
      begin
        {$ifdef DEBUG}
        if org_list_v <> self.list_v then
          raise new System.InvalidOperationException;
        {$endif DEBUG}
        yield a[enmr_i];
        IncInd(enmr_i);
      end;
      {$ifdef DEBUG}
      while enmr_i<>i1 do
      begin
        if a[enmr_i] <> default(T) then
          raise new System.InvalidOperationException;
        IncInd(enmr_i);
      end;
      {$endif DEBUG}
    end;
    public function GetEnumerator := Enmr.GetEnumerator;
    public function System.Collections.IEnumerable.GetEnumerator: System.Collections.IEnumerator := GetEnumerator;
    
  end;
  
  IMemoryLayerData = interface
    function GetByteSize: int64;
  end;
  MemoryLayer<TData> = abstract class
  where TData: IMemoryLayerData;
    private l := new MemoryLayerDataList<TData>;
    private newly_added := new List<TData>;
    
    private _name: string;
    
    private allowed_size: int64;
    private filled_size := int64(0);
    protected function GetRealFilledSize: int64; abstract;
    
    public constructor(name: string; allowed_size: int64);
    begin
      self._name := name;
      self.allowed_size := allowed_size;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public property Name: string read _name;
    public function Enmr := l.Enmr;
    
    public procedure BeginUpdate(item_new_table: Dictionary<TData, boolean>);
    begin
      self.filled_size := GetRealFilledSize;
      l.TryRemoveEachSingle(item_new_table, data->(self.filled_size -= data.GetByteSize));
    end;
    public procedure EndUpdate;
    begin
      // First added is the most important
      // Store it last it's the newest in l
      for var i := newly_added.Count-1 downto 0 do
        l.AddNewest(newly_added[i]);
      newly_added.Clear;
    end;
    
    public function TryAdd(new_data: TData; on_displaced: TData->()): boolean;
    begin
      Result := false;
      var new_data_sz := new_data.GetByteSize;
      var max_filled_size := allowed_size-new_data_sz;
      
      while filled_size > max_filled_size do
      begin
        if l.IsEmpty then
        begin
          on_displaced(new_data);
          exit;
        end;
        var old_data := l.PeekOldest; // First only peek, in case on_displaced throws
        var old_data_size := old_data.GetByteSize;
        on_displaced(old_data);
        if old_data <> l.RemoveOldest then
          raise new System.InvalidOperationException;
        filled_size -= old_data_size;
      end;
      
      newly_added += new_data;
      filled_size += new_data_sz;
      Result := true;
    end;
    
  end;
  
end.