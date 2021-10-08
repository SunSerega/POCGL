unit KEP;
{$zerobasedstrings}

interface

uses PathUtils  in '..\..\PathUtils' ;
uses Parsing    in '..\..\Parsing'   ;

type
  ParseException = sealed class(Exception)
    
  end;
  
  {$region Generated}
  
  {$region SN_space}
  
  SN_spaceValidator = sealed partial class
    
    
    
  end;
  SN_space = sealed partial class
    
  end;
    
  {$endregion SN_space}
  
  {$region Array0}
  
  Array0Validator = sealed partial class
    
    
    
  end;
  Array0 = sealed partial class
    
  end;
    
  {$endregion Array0}
  
  {$region Optional0}
  
  Optional0Validator = sealed partial class
    
    
    
  end;
  Optional0 = sealed partial class
    
  end;
    
  {$endregion Optional0}
  
  {$region Array1}
  
  Array1Validator = sealed partial class
    
    
    
  end;
  Array1 = sealed partial class
    
  end;
    
  {$endregion Array1}
  
  {$region Optional1}
  
  Optional1Validator = sealed partial class
    
    
    
  end;
  Optional1 = sealed partial class
    
  end;
    
  {$endregion Optional1}
  
  {$region Literal0}
  
  Literal0Validator = sealed partial class
    
    function ValidatorNextIndirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal0 = sealed partial class
    
  end;
    
  {$endregion Literal0}
  
  {$region Array2}
  
  Array2Validator = sealed partial class
    
    
    
  end;
  Array2 = sealed partial class
    
  end;
    
  {$endregion Array2}
  
  {$region Optional2}
  
  Optional2Validator = sealed partial class
    
    
    
  end;
  Optional2 = sealed partial class
    
  end;
    
  {$endregion Optional2}
  
  {$region Literal1}
  
  Literal1Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal1 = sealed partial class
    
  end;
    
  {$endregion Literal1}
  
  {$region Literal2}
  
  Literal2Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal2 = sealed partial class
    
  end;
    
  {$endregion Literal2}
  
  {$region Palette0}
  
  Palette0Validator = sealed partial class
    
    
    
  end;
  Palette0 = sealed partial class
    
  end;
    
  {$endregion Palette0}
  
  {$region Array3}
  
  Array3Validator = sealed partial class
    
    
    
  end;
  Array3 = sealed partial class
    
  end;
    
  {$endregion Array3}
  
  {$region Optional4}
  
  Optional4Validator = sealed partial class
    
    
    
  end;
  Optional4 = sealed partial class
    
  end;
    
  {$endregion Optional4}
  
  {$region NamelessBlock0}
  
  NamelessBlock0Validator = sealed partial class
    
    
    
  end;
  NamelessBlock0 = sealed partial class
    
  end;
    
  {$endregion NamelessBlock0}
  
  {$region Optional3}
  
  Optional3Validator = sealed partial class
    
    
    
  end;
  Optional3 = sealed partial class
    
  end;
    
  {$endregion Optional3}
  
  {$region SN_letter}
  
  SN_letterValidator = sealed partial class
    
    
    
  end;
  SN_letter = sealed partial class
    
  end;
    
  {$endregion SN_letter}
  
  {$region SN_digit}
  
  SN_digitValidator = sealed partial class
    
    
    
  end;
  SN_digit = sealed partial class
    
  end;
    
  {$endregion SN_digit}
  
  {$region Literal3}
  
  Literal3Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal3 = sealed partial class
    
  end;
    
  {$endregion Literal3}
  
  {$region Palette1}
  
  Palette1Validator = sealed partial class
    
    
    
  end;
  Palette1 = sealed partial class
    
  end;
    
  {$endregion Palette1}
  
  {$region Array4}
  
  Array4Validator = sealed partial class
    
    
    
  end;
  Array4 = sealed partial class
    
  end;
    
  {$endregion Array4}
  
  {$region Array5}
  
  Array5Validator = sealed partial class
    
    
    
  end;
  Array5 = sealed partial class
    
  end;
    
  {$endregion Array5}
  
  {$region Literal4}
  
  Literal4Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal4 = sealed partial class
    
  end;
    
  {$endregion Literal4}
  
  {$region Array7}
  
  Array7Validator = sealed partial class
    
    
    
  end;
  Array7 = sealed partial class
    
  end;
    
  {$endregion Array7}
  
  {$region Optional6}
  
  Optional6Validator = sealed partial class
    
    
    
  end;
  Optional6 = sealed partial class
    
  end;
    
  {$endregion Optional6}
  
  {$region NamelessBlock2}
  
  NamelessBlock2Validator = sealed partial class
    
    
    
  end;
  NamelessBlock2 = sealed partial class
    
  end;
    
  {$endregion NamelessBlock2}
  
  {$region Optional5}
  
  Optional5Validator = sealed partial class
    
    
    
  end;
  Optional5 = sealed partial class
    
  end;
    
  {$endregion Optional5}
  
  {$region Literal5}
  
  Literal5Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal5 = sealed partial class
    
  end;
    
  {$endregion Literal5}
  
  {$region Negate0}
  
  Negate0Validator = sealed partial class
    
    
    
  end;
  Negate0 = sealed partial class
    
  end;
    
  {$endregion Negate0}
  
  {$region Optional7}
  
  Optional7Validator = sealed partial class
    
    
    
  end;
  Optional7 = sealed partial class
    
  end;
    
  {$endregion Optional7}
  
  {$region Array10}
  
  Array10Validator = sealed partial class
    
    
    
  end;
  Array10 = sealed partial class
    
  end;
    
  {$endregion Array10}
  
  {$region Palette2}
  
  Palette2Validator = sealed partial class
    
    
    
  end;
  Palette2 = sealed partial class
    
  end;
    
  {$endregion Palette2}
  
  {$region Array19}
  
  Array19Validator = sealed partial class
    
    
    
  end;
  Array19 = sealed partial class
    
  end;
    
  {$endregion Array19}
  
  {$region Optional18}
  
  Optional18Validator = sealed partial class
    
    
    
  end;
  Optional18 = sealed partial class
    
  end;
    
  {$endregion Optional18}
  
  {$region NamelessBlock1}
  
  NamelessBlock1Validator = sealed partial class
    
    
    
  end;
  NamelessBlock1 = sealed partial class
    
  end;
    
  {$endregion NamelessBlock1}
  
  {$region Array6}
  
  Array6Validator = sealed partial class
    
    
    
  end;
  Array6 = sealed partial class
    
  end;
    
  {$endregion Array6}
  
  {$region Literal6}
  
  Literal6Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal6 = sealed partial class
    
  end;
    
  {$endregion Literal6}
  
  {$region Array8}
  
  Array8Validator = sealed partial class
    
    
    
  end;
  Array8 = sealed partial class
    
  end;
    
  {$endregion Array8}
  
  {$region Literal7}
  
  Literal7Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal7 = sealed partial class
    
  end;
    
  {$endregion Literal7}
  
  {$region Literal8}
  
  Literal8Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal8 = sealed partial class
    
  end;
    
  {$endregion Literal8}
  
  {$region Literal9}
  
  Literal9Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal9 = sealed partial class
    
  end;
    
  {$endregion Literal9}
  
  {$region Negate1}
  
  Negate1Validator = sealed partial class
    
    
    
  end;
  Negate1 = sealed partial class
    
  end;
    
  {$endregion Negate1}
  
  {$region SN_char}
  
  SN_charValidator = sealed partial class
    
    
    
  end;
  SN_char = sealed partial class
    
  end;
    
  {$endregion SN_char}
  
  {$region NamelessBlock3}
  
  NamelessBlock3Validator = sealed partial class
    
    
    
  end;
  NamelessBlock3 = sealed partial class
    
  end;
    
  {$endregion NamelessBlock3}
  
  {$region Literal10}
  
  Literal10Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal10 = sealed partial class
    
  end;
    
  {$endregion Literal10}
  
  {$region Palette3}
  
  Palette3Validator = sealed partial class
    
    
    
  end;
  Palette3 = sealed partial class
    
  end;
    
  {$endregion Palette3}
  
  {$region Array9}
  
  Array9Validator = sealed partial class
    
    
    
  end;
  Array9 = sealed partial class
    
  end;
    
  {$endregion Array9}
  
  {$region Literal11}
  
  Literal11Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal11 = sealed partial class
    
  end;
    
  {$endregion Literal11}
  
  {$region Literal12}
  
  Literal12Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal12 = sealed partial class
    
  end;
    
  {$endregion Literal12}
  
  {$region Array11}
  
  Array11Validator = sealed partial class
    
    
    
  end;
  Array11 = sealed partial class
    
  end;
    
  {$endregion Array11}
  
  {$region Optional8}
  
  Optional8Validator = sealed partial class
    
    
    
  end;
  Optional8 = sealed partial class
    
  end;
    
  {$endregion Optional8}
  
  {$region Palette4}
  
  Palette4Validator = sealed partial class
    
    
    
  end;
  Palette4 = sealed partial class
    
  end;
    
  {$endregion Palette4}
  
  {$region Palette5}
  
  Palette5Validator = sealed partial class
    
    
    
  end;
  Palette5 = sealed partial class
    
  end;
    
  {$endregion Palette5}
  
  {$region Array13}
  
  Array13Validator = sealed partial class
    
    
    
  end;
  Array13 = sealed partial class
    
  end;
    
  {$endregion Array13}
  
  {$region Optional10}
  
  Optional10Validator = sealed partial class
    
    
    
  end;
  Optional10 = sealed partial class
    
  end;
    
  {$endregion Optional10}
  
  {$region Literal15}
  
  Literal15Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal15 = sealed partial class
    
  end;
    
  {$endregion Literal15}
  
  {$region Literal16}
  
  Literal16Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal16 = sealed partial class
    
  end;
    
  {$endregion Literal16}
  
  {$region Negate2}
  
  Negate2Validator = sealed partial class
    
    
    
  end;
  Negate2 = sealed partial class
    
  end;
    
  {$endregion Negate2}
  
  {$region NamelessBlock5}
  
  NamelessBlock5Validator = sealed partial class
    
    
    
  end;
  NamelessBlock5 = sealed partial class
    
  end;
    
  {$endregion NamelessBlock5}
  
  {$region Array14}
  
  Array14Validator = sealed partial class
    
    
    
  end;
  Array14 = sealed partial class
    
  end;
    
  {$endregion Array14}
  
  {$region Optional12}
  
  Optional12Validator = sealed partial class
    
    
    
  end;
  Optional12 = sealed partial class
    
  end;
    
  {$endregion Optional12}
  
  {$region Negate3}
  
  Negate3Validator = sealed partial class
    
    
    
  end;
  Negate3 = sealed partial class
    
  end;
    
  {$endregion Negate3}
  
  {$region Palette6}
  
  Palette6Validator = sealed partial class
    
    
    
  end;
  Palette6 = sealed partial class
    
  end;
    
  {$endregion Palette6}
  
  {$region NamelessBlock4}
  
  NamelessBlock4Validator = sealed partial class
    
    
    
  end;
  NamelessBlock4 = sealed partial class
    
  end;
    
  {$endregion NamelessBlock4}
  
  {$region Optional11}
  
  Optional11Validator = sealed partial class
    
    
    
  end;
  Optional11 = sealed partial class
    
  end;
    
  {$endregion Optional11}
  
  {$region Optional17}
  
  Optional17Validator = sealed partial class
    
    
    
  end;
  Optional17 = sealed partial class
    
  end;
    
  {$endregion Optional17}
  
  {$region Literal13}
  
  Literal13Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal13 = sealed partial class
    
  end;
    
  {$endregion Literal13}
  
  {$region Array12}
  
  Array12Validator = sealed partial class
    
    
    
  end;
  Array12 = sealed partial class
    
  end;
    
  {$endregion Array12}
  
  {$region Optional9}
  
  Optional9Validator = sealed partial class
    
    
    
  end;
  Optional9 = sealed partial class
    
  end;
    
  {$endregion Optional9}
  
  {$region Literal14}
  
  Literal14Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal14 = sealed partial class
    
  end;
    
  {$endregion Literal14}
  
  {$region Literal17}
  
  Literal17Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal17 = sealed partial class
    
  end;
    
  {$endregion Literal17}
  
  {$region Array15}
  
  Array15Validator = sealed partial class
    
    
    
  end;
  Array15 = sealed partial class
    
  end;
    
  {$endregion Array15}
  
  {$region Optional13}
  
  Optional13Validator = sealed partial class
    
    
    
  end;
  Optional13 = sealed partial class
    
  end;
    
  {$endregion Optional13}
  
  {$region Palette7}
  
  Palette7Validator = sealed partial class
    
    
    
  end;
  Palette7 = sealed partial class
    
  end;
    
  {$endregion Palette7}
  
  {$region Palette8}
  
  Palette8Validator = sealed partial class
    
    
    
  end;
  Palette8 = sealed partial class
    
  end;
    
  {$endregion Palette8}
  
  {$region Array16}
  
  Array16Validator = sealed partial class
    
    
    
  end;
  Array16 = sealed partial class
    
  end;
    
  {$endregion Array16}
  
  {$region Optional14}
  
  Optional14Validator = sealed partial class
    
    
    
  end;
  Optional14 = sealed partial class
    
  end;
    
  {$endregion Optional14}
  
  {$region Literal18}
  
  Literal18Validator = sealed partial class
    
    function ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
    function ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
    
  end;
  Literal18 = sealed partial class
    
  end;
    
  {$endregion Literal18}
  
  {$region Array17}
  
  Array17Validator = sealed partial class
    
    
    
  end;
  Array17 = sealed partial class
    
  end;
    
  {$endregion Array17}
  
  {$region Optional15}
  
  Optional15Validator = sealed partial class
    
    
    
  end;
  Optional15 = sealed partial class
    
  end;
    
  {$endregion Optional15}
  
  {$region NamelessBlock6}
  
  NamelessBlock6Validator = sealed partial class
    
    
    
  end;
  NamelessBlock6 = sealed partial class
    
  end;
    
  {$endregion NamelessBlock6}
  
  {$region Negate5}
  
  Negate5Validator = sealed partial class
    
    
    
  end;
  Negate5 = sealed partial class
    
  end;
    
  {$endregion Negate5}
  
  {$region Negate4}
  
  Negate4Validator = sealed partial class
    
    
    
  end;
  Negate4 = sealed partial class
    
  end;
    
  {$endregion Negate4}
  
  {$region Optional16}
  
  Optional16Validator = sealed partial class
    
    
    
  end;
  Optional16 = sealed partial class
    
  end;
    
  {$endregion Optional16}
  
  {$region NamelessBlock7}
  
  NamelessBlock7Validator = sealed partial class
    
    
    
  end;
  NamelessBlock7 = sealed partial class
    
  end;
    
  {$endregion NamelessBlock7}
  
  {$region Array18}
  
  Array18Validator = sealed partial class
    
    
    
  end;
  Array18 = sealed partial class
    
  end;
    
  {$endregion Array18}
  
  {$region Negate6}
  
  Negate6Validator = sealed partial class
    
    
    
  end;
  Negate6 = sealed partial class
    
  end;
    
  {$endregion Negate6}
  
  {$region KEPFile}
  
  KEPFileValidator = sealed partial class
    
    
    
  end;
  KEPFile = sealed partial class
    
  end;
    
  {$endregion KEPFile}
  
  {$region NamedBlockDef}
  
  NamedBlockDefValidator = sealed partial class
    
    
    
  end;
  NamedBlockDef = sealed partial class
    
  end;
    
  {$endregion NamedBlockDef}
  
  {$region DefNameChar}
  
  DefNameCharValidator = sealed partial class
    
    
    
  end;
  DefNameChar = sealed partial class
    
  end;
    
  {$endregion DefNameChar}
  
  {$region BlockDefBody}
  
  BlockDefBodyValidator = sealed partial class
    
    
    
  end;
  BlockDefBody = sealed partial class
    
  end;
    
  {$endregion BlockDefBody}
  
  {$region ItemName}
  
  ItemNameValidator = sealed partial class
    
    
    
  end;
  ItemName = sealed partial class
    
  end;
    
  {$endregion ItemName}
  
  {$region LiteralDef}
  
  LiteralDefValidator = sealed partial class
    
    
    
  end;
  LiteralDef = sealed partial class
    
  end;
    
  {$endregion LiteralDef}
  
  {$region NameRef}
  
  NameRefValidator = sealed partial class
    
    
    
  end;
  NameRef = sealed partial class
    
  end;
    
  {$endregion NameRef}
  
  {$region OptionalDef}
  
  OptionalDefValidator = sealed partial class
    
    
    
  end;
  OptionalDef = sealed partial class
    
  end;
    
  {$endregion OptionalDef}
  
  {$region OptionalDefHeader}
  
  OptionalDefHeaderValidator = sealed partial class
    
    
    
  end;
  OptionalDefHeader = sealed partial class
    
  end;
    
  {$endregion OptionalDefHeader}
  
  {$region ArrayDef}
  
  ArrayDefValidator = sealed partial class
    
    
    
  end;
  ArrayDef = sealed partial class
    
  end;
    
  {$endregion ArrayDef}
  
  {$region NamelessBlockDef}
  
  NamelessBlockDefValidator = sealed partial class
    
    
    
  end;
  NamelessBlockDef = sealed partial class
    
  end;
    
  {$endregion NamelessBlockDef}
  
  {$region line_break_literal}
  
  line_break_literalValidator = sealed partial class
    
    
    
  end;
  line_break_literal = sealed partial class
    
  end;
    
  {$endregion line_break_literal}
  
  {$region NegateDef}
  
  NegateDefValidator = sealed partial class
    
    
    
  end;
  NegateDef = sealed partial class
    
  end;
    
  {$endregion NegateDef}
  
  {$region PaletteDef}
  
  PaletteDefValidator = sealed partial class
    
    
    
  end;
  PaletteDef = sealed partial class
    
  end;
    
  {$endregion PaletteDef}
  
  {$region PaletteDefItem}
  
  PaletteDefItemValidator = sealed partial class
    
    
    
  end;
  PaletteDefItem = sealed partial class
    
  end;
    
  {$endregion PaletteDefItem}
  
  {$region PaletteDefSeparator}
  
  PaletteDefSeparatorValidator = sealed partial class
    
    
    
  end;
  PaletteDefSeparator = sealed partial class
    
  end;
    
  {$endregion PaletteDefSeparator}
  
  {$region ArrayDefCustomValue}
  
  ArrayDefCustomValueValidator = sealed partial class
    
    
    
  end;
  ArrayDefCustomValue = sealed partial class
    
  end;
    
  {$endregion ArrayDefCustomValue}
  
  {$endregion Generated}
  
implementation

{$region Generated}

{$region SN_space}



{$endregion SN_space}

{$region Array0}



{$endregion Array0}

{$region Optional0}



{$endregion Optional0}

{$region Array1}



{$endregion Array1}

{$region Optional1}



{$endregion Optional1}

{$region Literal0}

function Literal0Validator.ValidatorNextIndirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
end;
function Literal0Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal0}

{$region Array2}



{$endregion Array2}

{$region Optional2}



{$endregion Optional2}

{$region Literal1}

function Literal1Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal1Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal1}

{$region Literal2}

function Literal2Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal2Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal2}

{$region Palette0}



{$endregion Palette0}

{$region Array3}



{$endregion Array3}

{$region Optional4}



{$endregion Optional4}

{$region NamelessBlock0}



{$endregion NamelessBlock0}

{$region Optional3}



{$endregion Optional3}

{$region SN_letter}



{$endregion SN_letter}

{$region SN_digit}



{$endregion SN_digit}

{$region Literal3}

function Literal3Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal3Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal3}

{$region Palette1}



{$endregion Palette1}

{$region Array4}



{$endregion Array4}

{$region Array5}



{$endregion Array5}

{$region Literal4}

function Literal4Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal4Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal4}

{$region Array7}



{$endregion Array7}

{$region Optional6}



{$endregion Optional6}

{$region NamelessBlock2}



{$endregion NamelessBlock2}

{$region Optional5}



{$endregion Optional5}

{$region Literal5}

function Literal5Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal5Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal5}

{$region Negate0}



{$endregion Negate0}

{$region Optional7}



{$endregion Optional7}

{$region Array10}



{$endregion Array10}

{$region Palette2}



{$endregion Palette2}

{$region Array19}



{$endregion Array19}

{$region Optional18}



{$endregion Optional18}

{$region NamelessBlock1}



{$endregion NamelessBlock1}

{$region Array6}



{$endregion Array6}

{$region Literal6}

function Literal6Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal6Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal6}

{$region Array8}



{$endregion Array8}

{$region Literal7}

function Literal7Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal7Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal7}

{$region Literal8}

function Literal8Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal8Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal8}

{$region Literal9}

function Literal9Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal9Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal9}

{$region Negate1}



{$endregion Negate1}

{$region SN_char}



{$endregion SN_char}

{$region NamelessBlock3}



{$endregion NamelessBlock3}

{$region Literal10}

function Literal10Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal10Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal10}

{$region Palette3}



{$endregion Palette3}

{$region Array9}



{$endregion Array9}

{$region Literal11}

function Literal11Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal11Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal11}

{$region Literal12}

function Literal12Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal12Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal12}

{$region Array11}



{$endregion Array11}

{$region Optional8}



{$endregion Optional8}

{$region Palette4}



{$endregion Palette4}

{$region Palette5}



{$endregion Palette5}

{$region Array13}



{$endregion Array13}

{$region Optional10}



{$endregion Optional10}

{$region Literal15}

function Literal15Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal15Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal15}

{$region Literal16}

function Literal16Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal16Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal16}

{$region Negate2}



{$endregion Negate2}

{$region NamelessBlock5}



{$endregion NamelessBlock5}

{$region Array14}



{$endregion Array14}

{$region Optional12}



{$endregion Optional12}

{$region Negate3}



{$endregion Negate3}

{$region Palette6}



{$endregion Palette6}

{$region NamelessBlock4}



{$endregion NamelessBlock4}

{$region Optional11}



{$endregion Optional11}

{$region Optional17}



{$endregion Optional17}

{$region Literal13}

function Literal13Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal13Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal13}

{$region Array12}



{$endregion Array12}

{$region Optional9}



{$endregion Optional9}

{$region Literal14}

function Literal14Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal14Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal14}

{$region Literal17}

function Literal17Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal17Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal17}

{$region Array15}



{$endregion Array15}

{$region Optional13}



{$endregion Optional13}

{$region Palette7}



{$endregion Palette7}

{$region Palette8}



{$endregion Palette8}

{$region Array16}



{$endregion Array16}

{$region Optional14}



{$endregion Optional14}

{$region Literal18}

function Literal18Validator.ValidatorNextTryDirect(text: StringSection; ind: StringIndex): sequence of StringIndex;
begin
  
end;
function Literal18Validator.ValidatorNextDirect(text: StringSection; ind: StringIndex; err: HashSet<ParseException>): sequence of StringIndex;
begin
  
end;

{$endregion Literal18}

{$region Array17}



{$endregion Array17}

{$region Optional15}



{$endregion Optional15}

{$region NamelessBlock6}



{$endregion NamelessBlock6}

{$region Negate5}



{$endregion Negate5}

{$region Negate4}



{$endregion Negate4}

{$region Optional16}



{$endregion Optional16}

{$region NamelessBlock7}



{$endregion NamelessBlock7}

{$region Array18}



{$endregion Array18}

{$region Negate6}



{$endregion Negate6}

{$region KEPFile}



{$endregion KEPFile}

{$region NamedBlockDef}



{$endregion NamedBlockDef}

{$region DefNameChar}



{$endregion DefNameChar}

{$region BlockDefBody}



{$endregion BlockDefBody}

{$region ItemName}



{$endregion ItemName}

{$region LiteralDef}



{$endregion LiteralDef}

{$region NameRef}



{$endregion NameRef}

{$region OptionalDef}



{$endregion OptionalDef}

{$region OptionalDefHeader}



{$endregion OptionalDefHeader}

{$region ArrayDef}



{$endregion ArrayDef}

{$region NamelessBlockDef}



{$endregion NamelessBlockDef}

{$region line_break_literal}



{$endregion line_break_literal}

{$region NegateDef}



{$endregion NegateDef}

{$region PaletteDef}



{$endregion PaletteDef}

{$region PaletteDefItem}



{$endregion PaletteDefItem}

{$region PaletteDefSeparator}



{$endregion PaletteDefSeparator}

{$region ArrayDefCustomValue}



{$endregion ArrayDefCustomValue}

{$endregion Generated}

end.