uses OpenCLABC;

type t1 = class end;

begin
  Context.Default.SyncInvoke(
	CQ(new t1)
    .Cast&<object>.Cast&<t1>
    .Cast&<object>.Cast&<t1>
  ).ToString.Println;
end.