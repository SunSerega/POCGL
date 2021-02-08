uses OpenCLABC;

begin
  Context.Default.SyncInvoke(
    HFQ(()->5).Cast&<word>
  );
end.