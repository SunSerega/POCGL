unit PackingUtils;

uses System.Diagnostics;
uses System.Threading;
uses System.Threading.Tasks;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

{$region MiscUtils calls}

procedure Otp(line: string) :=
MiscUtils.Otp(line);

procedure ErrOtp(e: Exception) :=
MiscUtils.ErrOtp(e);

function GetFullPath(fname: string; base_folder: string := System.Environment.CurrentDirectory): string :=
MiscUtils.GetFullPath(fname, base_folder);

function is_secondary_proc := MiscUtils.is_secondary_proc;

{$endregion MiscUtils calls}

procedure RunInSTA(a: Action0);
begin
  try
    var thr := new Thread(()->
    try
      a;
    except
      on e: Exception do ErrOtp(e);
    end);
    thr.ApartmentState := ApartmentState.STA;
    thr.Start;
  except
    on e: Exception do ErrOtp(e);
  end;
end;

end.