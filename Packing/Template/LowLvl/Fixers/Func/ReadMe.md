


# Change types:

- `!possible_par_types`

- `!limit_ovrs`

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
or
```
# FuncName
!limit_ovrs
 *	| var ErrorCode	| var ErrorCode	|
 *	| IntPtr		| var ErrorCode	|
 *	| var ErrorCode	| IntPtr		|
```


