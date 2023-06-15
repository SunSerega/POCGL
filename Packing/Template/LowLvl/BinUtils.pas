unit BinUtils;

{$savepcu false}//TODO #2853

uses System;

type
  BinReader = System.IO.BinaryReader;
  
function ReadArr<T>(self: BinReader; read_val: (BinReader,integer)->T): array of T; extensionmethod;
begin
  var c := self.ReadInt32;
  if c=0 then
  begin
    Result := System.Array.Empty&<T>;
    exit;
  end;
  Result := new T[c];
  for var i := 0 to Result.Length-1 do
    Result[i] := read_val(self, i);
end;
function ReadArr<T>(self: BinReader; read_val: BinReader->T): array of T; extensionmethod :=
  self.ReadArr((br,i)->read_val(br));
function ReadInt32Arr(self: BinReader); extensionmethod := self.ReadArr(br->br.ReadInt32);

function ReadNullable<T>(self: BinReader; read_val: BinReader->T): T?; extensionmethod;
  where T: record;
begin
  Result := nil;
  if not self.ReadBoolean then exit;
  Result := read_val(self);
end;
function ReadOrNil<T>(self: BinReader; read_val: BinReader->T): T; extensionmethod;
  where T: class;
begin
  Result := nil;
  if not self.ReadBoolean then exit;
  Result := read_val(self);
end;

function ReadEnum<T>(self: BinReader): T; extensionmethod;
  where T: System.Enum, record;
begin
  {$ifdef DEBUG}
  if typeof(T).GetEnumUnderlyingType <> typeof(Int32) then
    raise new NotSupportedException;
  {$endif DEBUG}
  //TODO #????: as object
  Result := T(self.ReadInt32() as object);
end;

end.