unit _2_DocModule;

uses Visual;
uses System.Windows;
uses System.Windows.Controls;

uses _3_DocFile;

type
  VisualDocModule = sealed class(contentcontrol)
    
    public constructor(name: string);
    begin
      self.Content := name;
    end;
    
  end;
  
  LogicDocModule = sealed class
    
    private vis: VisualDocModule;
    public property Visual: VisualDocModule read vis;
    
    public constructor(dir, name: string);
    begin
      vis := new VisualDocModule(name);
      
      
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
  end;
  
end.