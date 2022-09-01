unit Markings;

uses Parsing  in '..\..\..\Utils\Parsing';

type
  MarksInfo = abstract class
    private s_beg, s_end: string;
    private sub_marks: array of MarksInfo;
    private begs: array of string;
    
    public constructor(s_beg, s_end: string; params sub_marks: array of MarksInfo);
    begin
      self.s_beg := s_beg;
      self.s_end := s_end;
      self.sub_marks := sub_marks;
      self.begs := sub_marks.ConvertAll(m->m.s_beg);
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public procedure MarkAll(text: StringSection; validate: (StringSection, boolean, MarksInfo)->StringIndex) :=
    while true do
    begin
      var beg := text.SubSectionOfFirstUnescaped(begs);
      if beg.IsInvalid then exit;
      text.range.i1 := beg.I1;
      var info := sub_marks[begs.FindIndex(bs->bs=beg)];
      
      var ind := 0;
      while true do
      begin
        var len := text.IndexOfUnescaped(info.s_beg.Length+ind, info.s_end);
        if not len.IsInvalid then len += info.s_end.Length;
        
        var s := text;
        var eot := len.IsInvalid;
        if not eot then s := s.TakeFirst(len);
        
        var new_head := validate(s, eot, info);
        if new_head.IsInvalid then
          ind := len-info.s_end.Length+1 else
        begin
          text.range.i1 := new_head;
          break;
        end;
      end;
      
    end;
    public procedure MarkAll(text: string; validate: (StringSection, boolean, MarksInfo)->StringIndex) :=
    MarkAll(new StringSection(text), validate);
    
  end;
  
  DescrHeadTemplateMarks = sealed class(MarksInfo)
    
    public constructor := inherited Create(
      '[%','%]'
    );
    
  end;
  
  DescrHeadMarks = sealed class(MarksInfo)
    
    public constructor := inherited Create(
      '#',#10,
      new DescrHeadTemplateMarks
    );
    
  end;
  
  DescrBodyTemplateMarks = sealed class(MarksInfo)
    
    public constructor := inherited Create(
      '{%','%}'
    );
    
  end;
  
  DescrBlockMarks = sealed class(MarksInfo)
    
    public constructor := inherited Create(
      '#', #10
      , new DescrHeadMarks
    );
    
  end;
  
  DescrFileMarksInfo = sealed class(MarksInfo)
    
    public constructor := inherited Create(
      nil,nil
      , new DescrBlockMarks
      , new DescrBodyTemplateMarks
    );
    
    private static _instance := new DescrFileMarksInfo;
    public static property Instance: DescrFileMarksInfo read _instance;
    
  end;
  
end.
