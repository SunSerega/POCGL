uses OpenCLABC;

type t1 = class end;

begin
  Context.Default.SyncInvoke(
    CommandQueueBase(new t1 as object)
    .Cast&<object>.Cast&<t1>
    .Cast&<object>.Cast&<t1>
  ).GetType.Name.Println;
end.