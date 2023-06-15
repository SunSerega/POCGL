


Genral syntax of `.dat` files:
```

# GroupName
!change_type1
%change specific syntax line 1%
%change specific syntax line 2%
!change_type2
%change specific syntax%

```
---
# Change types:

- `!add`
- `!remove`
- `!rename`
- `!bitmask`
- `!add_enum`
- `!cust_memb`

---
### !add

Creates new group.

Syntax:
```
# AddableGroup
!add
UInt32
true
x=56
y=0xAB
```
First line specifies enum value type.\
Second line specifies if group is bitmask.

---
### !remove

Syntax:
```
# RemovableGroup
!remove
```

---
### !rename

Syntax:
```
# OldEnumName
!rename
NewEnumName
```

---
### !bitmask

Syntax:
```
# GroupName
!bitmask
True
```

---
### !add_enum

Syntax:
```
# GroupName
!add_enum
val1	= 1
val2	= 0x2
```

---
### !cust_memb

Syntax:
```
# ErrorCode
!cust_memb

public procedure RaiseIfError;
begin
  //ToDo ...
end;

```

---

