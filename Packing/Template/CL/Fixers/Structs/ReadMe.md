


Genral syntax of `.dat` files:
```

# StructName
!change_type1
%change specific syntax line 1%
%change specific syntax line 2%
!change_type2
%change specific syntax%

```
---
# Change types:

- `!add`
- `!vis`
- `!default`
- `!comment`

---
### !add

Creates new group.

Syntax:
```
# AddableStruct
!add
x: Byte
*
y: string
```

`*` would be replaced with empty line

---
### !vis

Changes visibility of fields

Syntax:
```
# StructName
!vis
x = private
y = internal
```

---
### !default

Sets default value of field

Syntax:
```
# StructName
!default
x = 5
y = 'abc'
```

---
### comment

Adds comment to end of field definition line

Syntax:
```
# StructName
x = Поле x содержащее Byte
y = Строка
```

---


