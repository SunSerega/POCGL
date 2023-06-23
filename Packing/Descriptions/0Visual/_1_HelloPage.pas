unit _1_HelloPage;

uses Visual;
uses System.Windows;
uses System.Windows.Controls;

uses _2_DocModule;

type
  VisualHelloPage = sealed class(ScrollViewer)
    private sp := new StackPanel;
    
    public constructor;
    begin
      self.Content := sp;
    end;
    
    public procedure AddButton(name: string; press: Action0);
    begin
      var b := new Button;
      sp.Children.Add(b);
      b.Content := name;
      b.Click += (o,e)->press();
      //TODO Remove
      if name='OpenCLABC' then press();
    end;
    
  end;
  
  LogicHelloPage = sealed class
    
    private vis: VisualHelloPage;
    public property Visual: VisualHelloPage read vis;
    
    public constructor;
    begin
      vis := new VisualHelloPage;
    end;
    
    public procedure Add(dir, name: string; switch_to: FrameworkElement->());
    begin
      vis.AddButton(name, ()->
      begin
        var module := new LogicDocModule(dir, name);
        switch_to(module.Visual);
      end);
    end;
    public procedure Add(dir: string; switch_to: FrameworkElement->()) :=
      Add(dir, System.IO.Path.GetFileName(dir), switch_to);
    
    
  end;
  
end.