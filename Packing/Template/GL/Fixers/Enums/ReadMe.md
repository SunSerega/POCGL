


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


