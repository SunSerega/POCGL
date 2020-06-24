uses OpenCLABC;

begin
  Context.Default.SyncInvoke(
    ConstQueue&<integer>.Create(5).Cast&<word>
  );
end.