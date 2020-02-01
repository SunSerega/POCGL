


Genral syntax of `Enums.dat`:
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
true
x=56
y=0xAB
```
First line specifies if group is bitmask

---
### !remove

Syntax:
```
# RemovalbeGroup
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


