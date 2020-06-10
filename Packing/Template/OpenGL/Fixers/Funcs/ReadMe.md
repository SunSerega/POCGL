


Genral syntax of `.dat` files:
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

- `!repl_par_t`

- `!possible_par_types`

- `!repl_ovrs`
- `!limit_ovrs`

---
### !repl_par_t

Replaces all instances of specified type in parameter with new types.

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

Changes possible types of each parameter.

Syntax:
```
# FuncName
!possible_par_types
 -array of byte +array of T	| *	|
```

---
### !repl_ovrs

Clears overloads list, then adds specified overloads.

Syntax:
```
# FuncName
!repl_ovrs
 byte | word	|
 byte | string	|
```

---
### !limit_ovrs

Removes all overloads, that don't match any of templates.

Syntax:
```
# FuncName
!limit_ovrs
 *	| array of T	| array of T	|
 *	| var T			| var T			|
 *	| IntPtr		| IntPtr		|
```
```
# FuncName
!limit_ovrs
 *	| var ErrorCode	| var ErrorCode	|
 *	| IntPtr		| var ErrorCode	|
 *	| var ErrorCode	| IntPtr		|
```

---


