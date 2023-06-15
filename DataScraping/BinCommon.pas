unit BinCommon;

type
  
  TypeRefKind = (TRK_Invalid = 0
    , TRK_Basic = 1
    , TRK_Group = 2
    , TRK_IdClass = 3
    , TRK_Struct = 4
    , TRK_Delegate = 5
  );
  
  EnumWithInfoKind = (EWIK_Invalid = 0
    , EWIK_Basic = 1
    , EWIK_ObjInfo = 2
    , EWIK_PropList = 3
    , EWIK_PropListEnd = 4
  );
  
  GroupKind = (GU_Invalid = 0
    , GK_Enum = 1
    , GK_Bitfield = 2
    , GK_ObjInfo = 3
    , GK_PropList = 4
  );
  
  ParArrSizeKind = (PASK_Invalid = 0
    , PASK_NotArray = 1
    , PASK_Arbitrary = 2
    , PASK_Const = 3
    , PASK_ParRef = 4
    , PASK_Mlt = 5
    , PASK_Div = 6
  );
  
  ParValComboKind = (PVCK_Invalid = 0
    , PVCK_Vector = 1
    , PVCK_Matrix = 2
  );
  
end.