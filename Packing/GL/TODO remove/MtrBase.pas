unit MtrBase;

{$apptype windows}
{$reference System.Windows.Forms.dll}

//ToDo issue компилятора:
// - #2021

{$region Misc helpers}

function gl_to_pas_t(self: string): string; extensionmethod;
begin
  case self of
    ''+'f':     Result := 'single';
    ''+'d':     Result := 'double';
  end;
end;

type t_descr = (
  (integer,integer), // sz
  string,            // gl_t
  string             // pas_t
);

function GetName(self: t_descr); extensionmethod :=
$'Mtr{self[0][0]}x{self[0][1]}{self[1]}';

function GetRowTName(self: t_descr); extensionmethod :=
$'Vec{self[0][1]}{self[1]}';

function GetColTName(self: t_descr); extensionmethod :=
$'Vec{self[0][0]}{self[1]}';

function GetMltResT(self: (t_descr,t_descr)): t_descr; extensionmethod :=
((self[0][0][0], self[1][0][1]), self[0][1], self[0][2]);

function GetTransposedT(self: t_descr): t_descr; extensionmethod :=
((self[0][1], self[0][0]), self[1], self[2]);

{$endregion Misc helpers}

end.