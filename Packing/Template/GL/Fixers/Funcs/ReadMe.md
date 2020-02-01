


Genral syntax of `Funcs.dat`:
```

# FuncName
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
- `!repl_par_t`
- `!possible_par_types`
- `!clear_ovrs`
- `!add_ovrs`
- `!rem_ovrs`

---
### !add

Creates new func.

Syntax:
```
# AddableFunc
!add
byte
x: word
y: ntv_char **
```
First line specifies return type. Can be `void` for procedure.

---
### !remove

Syntax:
```
# RemovalbeFunc
!remove
```

---
### !repl_par_t

Replaces all instances of specified type in parameter with new type.

Syntax:
```
# FuncName
!repl_par_t
DummyEnum=GroupName
InvalidTypeName= TypeName1 | array of TypeName2
```
`DummyEnum` should be used exactly once.\
`InvalidTypeName` should be used exactly 2 times.

`TypeName1` would not be matched with `array of TypeName1`.

Return type is always before parameters.\
Same applies to other change types. 

---

### !possible_par_types

Changes possible types of each parameter

Syntax:
```
# FuncName
!possible_par_types
 -array of byte +array of T | * |
```

---

### !clear_ovrs

Deletes all overloads. It only makes sense if there is `!add_ovr` next.

Syntax:
```
# FuncName
!clear_ovrs
!add_ovr
...
```

---

### !add_ovrs

Adds overloads to overload list.

Syntax:
```
# FuncName
!add_ovrs
 byte | word |
 byte | string |
```

---

### !rem_ovrs

Removes overloads to overload list.

Syntax:
```
# FuncName
!rem_ovrs
 byte | word |
 byte | string |
```

---


