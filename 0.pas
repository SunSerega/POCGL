uses OpenCLABC;

begin
  try
    Context.Default.SyncInvoke(
      HFQ(
        ()->
        begin
          Result := 0;
          raise new Exception;
        end
      )
    );
  except
    on e: Exception do
      writeln(e);
  end;
end.