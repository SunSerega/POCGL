/// KMP-enforced parser
unit KEP;
{$zerobasedstrings}

{$region ToDo}

//ToDo Типы валидации:
// 
// - force: закрывать массивы сразу
// --- полезно в конце текста и в Negate
// - ~force: оставлять массивы открытыми, если можно пропарсить дальше
// 
// - direct: не для origin, то есть не пытаться использовать KMP на литералах
// - ~direct (indirect): для origin
// --- но если, к примеру, ' => [+"aba" "abc"] ':
// ----- надо перескакивать с "aba" прямиком на "abc", если третий символ оказался "c"
// --- ' -"ab0" -[-"aba" -"abb"] -"abc" '
// ----- можно посылать индекс проблемы парсинга, то есть
// ----- когда 0 не получилось пропарсить - известно что пропарсилось "ab"
// ----- то есть может быть 3 индекса - [0, 1, 2], потому что это литерал
// ----- а у [-"aba" -"abb"] 4, потому что результат последнего может быть "not ch in [a,b]", или "not ch in [b]"
// --- ' -" abcd" -[space "abc"] ' vs ' -[space "abc"] -" abcd" '
// ----- первое нельзя оптимизировать, второе можно, потому что char.IsWriteSpace(" ")
// --- ' -"bc" -"abc" '
// ----- а тут наверное не выйдет никак оптимизировать

//ToDo => "a":"b"
//ToDo => ["a" +["b" "a"]:]
// - Оба выражения должны парсить одно и то же
// - Но в первом случае ["b" "a"] будет парсится с TryDirect
// - А во втором всё через Indirect???
//ToDo => [ ~"a" "b" ]
// - Тут нет смысла Indirect'ить ~"a", надо Indirect'ить весь блок
// - Вообще смысл Indirect'а ещё и в KMP
// - Тогда не важно что всё кроме первого элемента массива опционально
//ToDo => [ +["a":"b" "c"] "a":"b" "d" ]
// - Тут получается у массива бесконечность возможных кодов для KMP
//ToDo => [ +["a":"b" "c" "d":"e" "f"] "a":"b" char "d":"e" "g" ]
// - А тут их бесконечность^2 - то есть надо минимум 2 дополнительных числа чтоб описать как именно пропарсилось ~~[]
//ToDo => [ +[ [ "a":"b" "c" ]:"d" "e" ] ... ]
// - бесконечность^бесконечность, потому что для каждого тела [...]:"d" нужно ещё 1 число
// --- [0]: 0..2, 0=ничего, 1=[...]:"d", 2=всё пропарсило
// --- [1], если [0]>=1: 0..?, кол-во дополнительных тел внешнего массива
// --- [2..2+[1]*2+0]: 0..2, сколько пропарсено в теле внешнего массива
// --- [2..2+[1]*2+1]: 0..?, кол-во дополнительных тел внутреннего массива
// - На самом деле тело внутреннего массива тоже имеет состояние 0..1 - ещё доп. числа
// - Но в дополнительных телах может быть только значение 1..1, не несущее информации
//ToDo Написать в ReadMe.md что indirect-ить сложные выражения плохо

//ToDo => [~~[ "abcab" ] "abc"]
// - Тут результат нахождения "abcab" делает бесполезным парсинг "abc"
// - Дополнить в процессе реализации

// => [
//   ~~[ +"a":"b" ]
//   "abababa"
// ]
// Тут есть входные варианты:
// - [0]: ~"a", data=0
// - [1, 0, 0]: "a"~"b", data=0
// - [1, 0, 1]: "ab"~"a", data=0
// - [1, 1, 0]: "aba"~"b", data=0
// - [1, 1, 1]: "abab"~"a", data=0
// - [1, 2, 0]: "ababa"~"b", data=0
// - [1, 2, 1]: "ababab"~"a", data=0
// - [1, 3, 0]: "abababa"~"b", data=7, Result = [7].[1,3,0] => ""~"b"
// - [1, 3, 1]: "abababab"~"a", data=7, Result = [7].[1,3,1] => "b"~"a"
// - [1, 4, 0]: "ababababa"~"a", data=7, Result = [7].[1,4,0] => "ba"~"b"
// и т.д. до бесконечности
// То есть все первые варианты объеденяются в [0]
// Затем начиная с data=7 всё объединяется в [1,3,0]
// В общем случае надо перекидывать вперёд информацию о том что ещё пропарсилось
// Но тут result уходит в никуда, поэтому остаётся только [0] и [1,3,0]
//ToDo Надо придумать как тут заменить [1,3,0] на [1]
// - Допустим тут всего 1 вариант за [1] - [,3], а значит не важно какие данные идут дальше

// => [
//   ~~[ +"a":"с" ]
//   "aba"
// ]
// Входные варианты:
// - [0]: ~"a", data=0
// - [1, 0, 0]: "a"~"с", data = 1
// - [1, 0, 1]: "aс"~"a", data = -1
// - [1, 1, 0]: "aсa"~"с", data = -1
// и т.д. до бесконечности
// Тут data это [сколько удалось пропарсить у литерала "aba"]

//ToDo 1. %УБРАТЬ% Проходим для получения вариантов состояния:
// - prev: список[ {id: array of integer} {состояние следующих символов: StringCondition} ] - возможные предыдущие варианты
// - Result: список[ {id: array of integer} {parent_id: array of integer} {состояние следующих символов: StringCondition} ]
// - ToDo стоэ, не "array of integer" - надо иметь возможность хранить бесконечный алгоритм
// --- Каждое второе число это кол-во повторений (n*"ba" в примере выше), а следующее - собственно условие ( [""~"b"] и ["b"~"a"] )
// --- Лучше вообще не присваивать числа до следующей стадии
// --- Вместо этого хранится: {id: integer} {минимум состояния: StringCondition} +? {умножаемое состояние: StringCondition}
// --- Если есть умножаемое состояние - после него надо ещё хранить следующий объект состояния
// --- При этом состояние в результате - надо учитывать случай когда использовало ["a" + 3*"ba"] + затем оставило информацию об остальных состояниях предка
// --- А так же случай, когда использовало ["a" + 2*"ba" + "b"] и оставило ["a" + n*"ba" + "?"~"?" ]
// --- Или использовало                    ["a" + 2*"ba" + ~"b"] и оставило только ~"b"

//ToDo 1. Проходим для получения вариантов состояния:
// - prev: List< {id: integer} {cond: StringCondition} ?? {mlt_cond: StringCondition} {List<следующие варианты>} >
// - Result: List<
//     {id: integer} {cond: StringCondition} {parent: {указание варианта}, {n из n*mlt_cond} и следующие варианты}
//     {id: integer} {cond: StringCondition} {mlt_cond} List< {следующий} {parent: {указание варианта} {mlt_offset} и следующие варианты} >
//   >
// - А может быть указывать всех возможных предков, чтоб на следующей стадии было видно что делать в том случае
//ToDo 2. Скармливаем варианты конца [0] прохода - [1]-ому, но уже смотрим в чём отличие для [2]vs[3] и т.д. проходах, а не собираем результаты
// - Можно проходить пока не будет дубля предыдущего состояния
// - Но надо думать в первую очередь о конечном коде - как он будет различать состояния [0], [1], [2] и т.д.
//ToDo 3. 

//ToDo Всё это мусор, KMP массивов литералов не нужен ни в какой реальной ситуации
//ToDo Зато что может быть нужно, так это KMP нескольких частей одного блока. К примеру чтоб эффективно искать вложенность:
// - # OpBlock[ "begin"[=>[ [=>~~"begin" OpBlock]/["op1"/"op2" =>";"]:[]=>"end"] ]
// --- (через шаблоны можно красивее)
// - Тут нормально что массив KEP'нутый - потому что его тело содержит [=>~~"begin" OpBlock]
// --- Другими словами после каждого успешного тела массива - KMP-данные сбрасываются - и это спасает от бесконечных состояний
// - Таким образом через KMP ищет строки "begin" и "end"
// - При пост-origin парсинге надо отматывать массив в обратную сторону, ради меж-элементного пространства, при этом игнорируя возможность origin-элементов
// - Однако что насчёт симетрии парсинга и эквивалентности без-origin кода?
//ToDo А как это будет сочетать несколько типов вложенности, к примеру f1(()->begin ; end);
// - Плохой пример, тут можно просто добавить =>"->"
// - Тогда так: ( [ [ () ] ] )
// - Дык а какая разница - просто и ( и [ имеют одно тело, которое ищет "("/"[" + свою закрывашку
//ToDo Так же одновременный KMP имеет смысл в случае [ =>+"abc" "def" ]

//ToDo И чтоб это всё работало - надо таки расширить дополнение так чтоб состояние после ~ влияло на то что идёт дальше - в данном случае избавляя от необходиости парсить "begin" дважды
// - На самом деле если думать о реализации - это получается трата кучи лишней памяти
// - Зачем хранить состояние "begin", когда оно 100% пропарсится после ~~"begin"?
// - В случае OpBlock это заменяется на шаблон-перечисление как показано ниже
// - А в случае #spacing[ existing_spacing/[~existing_spacing ...] ] - это выглядит как костыль
// - В идеале сделать бы синтаксическую конструкцию лично для KEP минимизации, дающей заменять весь блок на другой
// --- Стопэ, это ведь я описал одно из применений токенов... А я всё думаю как скостылить







//ToDo Проверить сравнение конструкций на равенство
// - Name и Nameless равны если равны их sub_defs
// - Лучше наконец сделать им общий класс - предок
// - а SyntaxBlock переименовать в SyntaxContainer и наследовать от него SytaxOptional и т.п., чтоб парсить их из .dat красивее
//ToDo Неудаляемые имена # >name
// - Их нельзя инлайнить
// - И при сравнении с другим блоком - как раз другой блок надо заменять на это имя
// --- Для этого надо их все добавить "cache[sn] := sn" в самом начале оптимизации
// --- Сейчас cache не даёт оптимизировать тело... Может разделить оптимизацию тела и инлайн?
// - Кроме того, что происходит со словарём, если у ключа меняется hash-code, к примеру потому что заменился sub_def?
//ToDo Сейчас в GenCode этого вообще нет - надо делать кастомный Comparer или как его там, для HashSet

//ToDo После Indirect+TryDirect прохода по содержимому блока - надо пройти ещё раз по тому что осталось не пропарсено, чтоб накидать ошибок
// - Но только если не Negated
//ToDo И тогда expand (расширение из origin блока) и direct тоже разные вещи
// - Во время expand надо возвращать StringSection.Invalid, вместо ошибок

//ToDo В "def/def/def" если opt.NeedErrors:
// - Надо создавать временный список ошибок
// - При ошибке - ошибку пишет в список и возвращает false (ошибка парсинга)
// - Если все стороны дали ошибку - возвращается агрегатная ошибка, содержащая все внутренние
// --- Вложенные агрегатные можно разворачивать

//ToDo ~[ "a":"b" "c" ] / [ "a":"b" "c" ]
// - Тут оба блока можно парсить общим методом - негация не имеет силы, потому что последний элемент - литерал, игнорирует силу негации

//ToDo "#name1[ "+" container ] #container[ name1/name2/... ]"
// - Нужен ли тут инлайн?
// - Будет ли вообще преимущество по скорости, или инлайн будет лишним раздуванием генерируемого кода?

//ToDo Синтаксис "#name[]" - для более точного определения блока
// - Сначала реализовать параллельно с предыдущим, затем удалить старый

//ToDo "\u12AB" или что то типа того в строках?
// - "a"U<d13>"b"   - 'a'#13'b'
// - "a"U<x12AB>"b" - 'a'+char($12AB)+'b'

//ToDo Шаблоны блоков:
// - # >KeyWord<Literal>[ Literal ]
// - Генерировать несколько типов - generic и его реализации, чтоб все можно было дополнять семантикой
//ToDo И наверное всё же стоит сделать какие то директивы на шаблонах:
// - # OpBlock<jump?jump:>[ (jump?[=>"begin"]:"begin") [ =>[...]:";" =>"end" ] ]
// - Получается что есть 2 варианта - "OpBlock<jump>" и "OpBlock<>"="OpBlock"
// - Другими словами, раз есть пустое значение - это шаблонный параметр по-умолчанию

//ToDo Комментарии в .kep файлах

{$endregion ToDo}

interface

uses Fixers;
uses PathUtils;
uses Parsing;

{$region Utils}

type
  NamedBlockDef = sealed partial class end;
  DefSourceContext = record
    block := default(NamedBlockDef);
    fname := default(string);
    range: SIndexRange := (i1: StringIndex.Invalid; i2: StringIndex.Invalid);
  end;
  
  SyntaxException = sealed class(Exception)
    
    public constructor(message: string; source_context: DefSourceContext);
    
  end;
  
  KEParser = sealed class
    private sources := new List<string>;
    private AllNamedBlocks := new Dictionary<string, NamedBlockDef>;
    
    public function AddSource(fname: string): KEParser;
    begin
      sources += fname;
      Result := self;
    end;
    public function AddSources(dir: string): KEParser;
    begin
      foreach var fname in EnumerateAllFiles(dir, '*.kep') do
        AddSource(fname);
      Result := self;
    end;
    
    public function Parse: Dictionary<string, NamedBlockDef>;
    
  end;
  
{$endregion Utils}

{$region Parse}

type
  {$region Base}
  
  SyntaxDef = abstract partial class
    protected parser: KEParser;
    protected source_context: DefSourceContext;
    
    protected constructor(parser: KEParser; source_context: DefSourceContext);
    begin
      self.parser := parser;
      self.source_context := source_context;
      if not source_context.range.i2.IsInvalid then
        raise new System.InvalidOperationException;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    private static function ReadSubDef(parser: KEParser; var _text: StringSection; on_origin: ()->(); source_context: DefSourceContext): SyntaxDef;
    
    private static function CharIsDefName(ch: char) :=
    ch.IsLetter or ch.IsDigit or (ch = '_');
    
  end;
  
  {$endregion Base}
  
  {$region Independant}
  
  LiteralDef = sealed partial class(SyntaxDef)
    private s: string;
    
    public property LiteralValue: string read s;
    
    public constructor(parser: KEParser; var text: StringSection; source_context: DefSourceContext);
    begin
      inherited Create(parser, source_context);
      var res_section := text.TakeFirst(1);
      while true do
      begin
        var next := res_section.Next(text);
        if next=nil then raise new SyntaxException($'Unexpected string end', source_context);
        case next.Value of
          '"': break;
          '\': res_section.range.i2 += 2;
          else res_section.range.i2 += 1;
        end;
      end;
      res_section.range.i2 += 1;
      text := text.WithI1(res_section.I2);
      self.source_context.range.i2 := res_section.I2;
      res_section := res_section.TrimFirst(1).TrimLast(1);
      if res_section.Length=0 then raise new SyntaxException($'Empty string', self.source_context);
      self.s := res_section.ToString;
    end;
    
  end;
  
  NameRefDef = sealed partial class(SyntaxDef)
    private val: string;
    
    public property Name: string read val;
    
    public constructor(parser: KEParser; val: string; source_context: DefSourceContext);
    begin
      inherited Create(parser, source_context);
      self.val := val;
      self.source_context.range.i2 := self.source_context.range.i1+val.Length;
    end;
    
    private static All := new Dictionary<string, NameRefDef>;
    public static function Make(parser: KEParser; val: string; source_context: DefSourceContext): NameRefDef;
    begin
      if All.TryGetValue(val, Result) then exit;
      Result := new NameRefDef(parser, val, source_context);
      All[val] := Result;
    end;
    
  end;
  
  {$endregion Independant}
  
  {$region Modifier}
  
  ModifierDef = abstract partial class(SyntaxDef)
    protected sub_def: SyntaxDef;
    
    protected constructor(parser: KEParser; sub_def: SyntaxDef; source_context: DefSourceContext);
    begin
      inherited Create(parser, source_context);
      self.sub_def := sub_def;
    end;
    //ToDo #???? тут (и ниже) надо "Create"?
    private constructor := inherited Create;
    
  end;
  
  OptionalDef = sealed partial class(ModifierDef)
    private try_rem, try_add: boolean;
    
    public constructor(parser: KEParser; sub_def: SyntaxDef; try_rem, try_add: boolean; source_context: DefSourceContext);
    begin
      inherited Create(parser, sub_def, source_context);
      self.try_rem := try_rem;
      self.try_add := try_add;
    end;
    private constructor := inherited Create;
    
  end;
  
  NegateDef = sealed partial class(ModifierDef)
    
    protected constructor(parser: KEParser; var text: StringSection; source_context: DefSourceContext);
    begin
      inherited Create(parser, source_context);
      if not text.StartsWith('~') then raise new System.InvalidOperationException;
      text.range.i1 += 1;
      
      self.sub_def := SyntaxDef.ReadSubDef(parser, text, nil, source_context);
      
      self.source_context.range.i2 := text.I1;
    end;
    private constructor := inherited Create;
    
  end;
  
  LabeledDef = sealed partial class(ModifierDef)
    private name: string;
    
    public constructor(parser: KEParser; var text: StringSection; source_context: DefSourceContext);
    begin
      inherited Create(parser, source_context);
      if not text.StartsWith('{') then raise new System.InvalidOperationException;
      text.range.i1 += 1;
      
      var name_section := text.TakeFirstWhile(CharIsDefName);
      self.name := name_section.ToString;
      
      text.range.i1 := name_section.I2;
      if not text.StartsWith('}') then raise new SyntaxException($'Missing "}"', source_context);
      text.range.i1 += 1;
      
      source_context.range.i1 := text.I1;
      text := text.TrimFirstWhile(char.IsWhiteSpace);
      self.sub_def := SyntaxDef.ReadSubDef(parser, text, nil, source_context);
      
      self.source_context.range.i2 := text.I1;
    end;
    private constructor := inherited Create;
    
  end;
  
  ArrayDef = sealed partial class(ModifierDef)
    private separator := default(SyntaxDef);
    
    public constructor(parser: KEParser; sub_def: SyntaxDef; var text: StringSection; source_context: DefSourceContext);
    begin
      inherited Create(parser, sub_def, source_context);
      
      var section := text.TrimAfterFirst(#10);
      if section.IsInvalid then section := text;
      section := section.TrimFirstWhile(char.IsWhiteSpace);
      text.range.i1 := section.I1;
      
      if section.Length=0 then exit;
      separator := SyntaxDef.ReadSubDef(parser, text, nil, source_context);
      self.source_context.range.i2 := text.I1;
      
    end;
    private constructor := inherited Create;
    
  end;
  
  {$endregion Modifier}
  
  {$region Container}
  
  ContainerDef = abstract partial class(SyntaxDef)
    protected sub_defs := new List<SyntaxDef>;
    
  end;
  
  PaletteDef = sealed partial class(ContainerDef)
    
    public constructor(parser: KEParser; first: SyntaxDef; var text: StringSection; source_context: DefSourceContext);
    begin
      inherited Create(parser, source_context);
      self.sub_defs += first;
      
      text := text.TrimFirst(1).TrimFirstWhile(char.IsWhiteSpace);
      source_context.range.i1 := text.I1;
      var next := ReadSubDef(parser, text, nil, source_context);
      if text.IsInvalid then raise new SyntaxException($'Missing syntax definition after /', source_context);
      if next is PaletteDef(var sub_p) then
        self.sub_defs.AddRange(sub_p.sub_defs) else
        self.sub_defs += next;
      
      self.source_context.range.i2 := text.I1;
    end;
    private constructor := inherited Create;
    
  end;
  
  BlockDef = abstract partial class(ContainerDef)
    protected origin_ind: integer? := nil;
    
    public property HasOrigin: boolean read origin_ind.HasValue;
    public property OriginInd: integer read origin_ind.Value;
    
    protected function ReadSubDef(parser: KEParser; var text: StringSection; source_context: DefSourceContext) :=
    inherited ReadSubDef(parser, text, ()->
    begin
      if origin_ind<>nil then
        raise new SyntaxException($'Multiple origin points', source_context);
      origin_ind := sub_defs.Count;
    end, source_context);
    
  end;
  NamedBlockDef = sealed partial class(BlockDef)
    private name_modifier: char? := nil;
    private name: string;
    
    public property BlockName: string read name;
    public property BlockNameModifier: char? read name_modifier;
    
    public constructor Create(parser: KEParser; name, _text, fname: string);
    begin
      inherited Create(parser, new DefSourceContext);
      
      if name[0] in '>?' then
      begin
        self.name_modifier := name[0];
        name := name.Substring(1).TrimStart;
      end;
      
      if not name.All(CharIsDefName) then
        raise new System.FormatException($'{fname}: [{name}] is not valid, use letters, digits and "_"');
      if parser.AllNamedBlocks.ContainsKey(name) then
        raise new System.InvalidOperationException($'Name "{name}" defined in [{parser.AllNamedBlocks[name].source_context.fname}] and [{fname}]');
      
      self.source_context.block := self;
      self.source_context.fname := fname;
      self.name := name;
      parser.AllNamedBlocks[name] := self;
      
      var source_context := self.source_context;
      var text := new StringSection(_text);
      while true do
      begin
        text := text.TrimFirstWhile(char.IsWhiteSpace);
        source_context.range.i1 := text.I1;
        sub_defs += ReadSubDef(parser, text, source_context);
        if text.Length=0 then break;
      end;
      
    end;
    
  end;
  NamelessBlockDef = sealed partial class(BlockDef)
    
    public constructor(parser: KEParser; var text: StringSection; source_context: DefSourceContext);
    begin
      inherited Create(parser, source_context);
      text.range.i1 += 1; // '['
      text := text.TrimFirstWhile(char.IsWhiteSpace);
      while true do
      begin
        source_context.range.i1 := text.I1;
        sub_defs += ReadSubDef(parser, text, source_context);
        if text.IsInvalid then raise new SyntaxException($'Missing block end', source_context);
        text := text.TrimFirstWhile(char.IsWhiteSpace);
        if text.StartsWith(']') then break;
      end;
      text.range.i1 += 1; // ']'
      self.source_context.range.i2 := text.I1;
    end;
    
  end;
  
  {$endregion Container}
  
{$endregion Parse}

{$region WrapperBase}

type
  {$region Base}
  
  DefWrapperException = sealed class(Exception)
    
    public constructor(message: string; def: SyntaxDef) :=
    inherited Create($'[{def.source_context.fname}#{def.source_context.block.name}:{def.source_context.range}] {message}');
    
  end;
  
  DefWrapperBase = abstract class
    
    protected procedure AddChild(name: string; dw: DefWrapperBase); abstract;
    protected procedure SealChildren; abstract;
    
  end;
  
  SyntaxDef = abstract partial class
    
    protected procedure MakeWrapperBody(dw: DefWrapperBase; converter: SyntaxDef->DefWrapperBase; cache: Dictionary<SyntaxDef, DefWrapperBase>); abstract;
    public function MakeWrapper(converter: SyntaxDef->DefWrapperBase; cache: Dictionary<SyntaxDef, DefWrapperBase>): DefWrapperBase;
    begin
      if cache.TryGetValue(self, Result) then exit;
      var source := self;
      if source is NameRefDef(var nr) then
      begin
        var res: NamedBlockDef;
        if source.parser.AllNamedBlocks.TryGetValue(nr.Name, res) then
          source := res;
      end;
      Result := converter(source);
      cache[self] := Result;
      source.MakeWrapperBody(Result, converter, cache);
      Result.SealChildren;
    end;
    public function MakeWrapper(converter: SyntaxDef->DefWrapperBase) :=
    MakeWrapper(converter, new Dictionary<SyntaxDef, DefWrapperBase>);
    
  end;
  
  {$endregion Base}
  
  {$region Independant}
  
  LiteralDef = sealed partial class(SyntaxDef)
    
    protected procedure MakeWrapperBody(dw: DefWrapperBase; converter: SyntaxDef->DefWrapperBase; cache: Dictionary<SyntaxDef, DefWrapperBase>); override := exit;
    
  end;
  
  NameRefDef = sealed partial class(SyntaxDef)
    
    protected procedure MakeWrapperBody(dw: DefWrapperBase; converter: SyntaxDef->DefWrapperBase; cache: Dictionary<SyntaxDef, DefWrapperBase>); override := exit;
    
  end;
  
  {$endregion Independant}
  
  {$region Modifier}
  
  ModifierDef = abstract partial class(SyntaxDef)
    
    protected procedure MakeWrapperBody(dw: DefWrapperBase; converter: SyntaxDef->DefWrapperBase; cache: Dictionary<SyntaxDef, DefWrapperBase>); override :=
    dw.AddChild('sub_def', sub_def.MakeWrapper(converter, cache));
    
  end;
  
  ArrayDef = sealed partial class(ModifierDef)
    
    protected procedure MakeWrapperBody(dw: DefWrapperBase; converter: SyntaxDef->DefWrapperBase; cache: Dictionary<SyntaxDef, DefWrapperBase>); override;
    begin
      inherited;
      if separator<>nil then
        dw.AddChild('separator', separator.MakeWrapper(converter, cache));
    end;
    
  end;
  
  {$endregion Modifier}
  
  {$region Container}
  
  ContainerDef = abstract partial class(SyntaxDef)
    
    protected procedure MakeWrapperBody(dw: DefWrapperBase; converter: SyntaxDef->DefWrapperBase; cache: Dictionary<SyntaxDef, DefWrapperBase>); override :=
    for var i := 0 to sub_defs.Count-1 do
    begin
      var name := default(string);
      var sub_def := sub_defs[i];
      if sub_def is LabeledDef(var l) then
      begin
        name := l.name;
        sub_def := l.sub_def;
      end;
      dw.AddChild(name, sub_def.MakeWrapper(converter, cache));
    end;
    
  end;
  
  PaletteDef = sealed partial class(ContainerDef)
    
  end;
  
  BlockDef = abstract partial class(ContainerDef)
    
  end;
  NamedBlockDef = sealed partial class(BlockDef)
    
  end;
  NamelessBlockDef = sealed partial class(BlockDef)
    
  end;
  
  {$endregion Container}
  
{$endregion WriteBase}

implementation

{$region Parse impl}

constructor SyntaxException.Create(message: string; source_context: DefSourceContext) :=
inherited Create($'[{source_context.fname}#{source_context.block.name}:{source_context.range}] {message}');

static function SyntaxDef.ReadSubDef(parser: KEParser; var _text: StringSection; on_origin: ()->(); source_context: DefSourceContext): SyntaxDef;
begin
  Result := nil;
  var text := _text;
  if text.Length=0 then raise new System.InvalidOperationException;
  
  var is_origin := (on_origin<>nil) and text.StartsWith('=>');
  if is_origin then
  begin
    on_origin;
    text := text.TrimFirst('=>'.Length).TrimFirstWhile(char.IsWhiteSpace);
    source_context.range.i1 := text.I1;
  end;
  
  var modifier_char: char? := nil;
  var inner_source_context := source_context;
  if text.StartsWith('+') then
  begin
    if is_origin then raise new SyntaxException($'Modifier on origin point', source_context);
    modifier_char := text[0];
    text := text.TrimFirst(1).TrimFirstWhile(char.IsWhiteSpace);
    inner_source_context.range.i1 := text.I1;
  end;
  
  if text.StartsWith('"') then
    Result := new LiteralDef(parser, text, inner_source_context) else
  if text.StartsWith('~') then
    Result := new NegateDef(parser, text, inner_source_context) else
  if text.StartsWith('{') then
    Result := new LabeledDef(parser, text, inner_source_context) else
  if text.StartsWith('[') then
    Result := new NamelessBlockDef(parser, text, inner_source_context) else
  begin
    var name := text.TakeFirstWhile(CharIsDefName);
    if name.Length=0 then
      raise new SyntaxException($'Can''t parse >>>{text}<<<', inner_source_context);
    Result := NameRefDef.Make(parser, name.ToString, inner_source_context);
    text.range.i1 += name.Length;
  end;
  text := text.TrimFirstWhile(char.IsWhiteSpace);
  
  if text.StartsWith('/') then
  begin
    if modifier_char<>nil then
      raise new SyntaxException($'Ambiguous modifier at {text.I1}, add nameless block definition', source_context);
    
    Result := new PaletteDef(parser, Result, text, inner_source_context);
    
  end else
  if text.StartsWith(':') then
  begin
    
    text.range.i1 += 1;
    Result := new ArrayDef(parser, Result, text, inner_source_context);
    
  end;
  
  if modifier_char<>nil then
    Result := new OptionalDef(parser, Result, modifier_char='-', modifier_char='+', source_context);
  
  _text := text;
end;

{$endregion Parse impl}

function KEParser.Parse: Dictionary<string, NamedBlockDef>;
begin
  var defs :=
    sources.SelectMany(fname->
      FixerUtils.ReadBlocks(fname, false)
      .Select(\(name, lines)->(fname, name, lines.JoinToString(#10)))
    ).ToArray
  ;
  
//          ReadAllText(fname)
//          .Replace(#13#10, #10)
//          .Replace(#13, #10)
  
  foreach var (fname, name, text) in defs do
    new NamedBlockDef(self, name, text, fname);
  
  Result := self.AllNamedBlocks;
end;

end.