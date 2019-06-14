uses RNNData;

begin
  var db := System.IO.File.OpenRead('training.db');
  var br := new System.IO.BinaryReader(db);
  
  var table := new Dictionary<word,char>;
  loop br.ReadInt32 do
  begin
    var val := char(br.ReadUInt16);
    var key := br.ReadUInt16;
    table.Add(key,val);
  end;
  
  var training_data: array of array of byte := ArrGen(br.ReadInt32,
    i1->
    begin
      var bts := new byte[br.ReadInt32*2];
      
      if db.Read(bts,0,bts.Length) <> bts.Length then
        raise new System.IO.EndOfStreamException;
      
      Result := bts;
    end
  );
  
  var a := new AI(table.Count,800);
  
  var i := 0;
  
  a.TrainOn(training_data, 
    ai->
    begin
      i += 1;
      
      System.Threading.Tasks.Parallel.Invoke(
        
        ()->
        begin
          var f := System.IO.File.Create($'Gens\Gen {i}');
          ai.Save(new System.IO.BinaryWriter(f));
          f.Close;
        end,
        
        ()->
        begin
          writeln($'Поколение {i}:');
          ai.OutputData
          .Take(500)
          .Select(w->table[w])
          .Print
        end
        
      );
      
    end
  )
  
end.