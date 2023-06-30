


# Change types:

- `!add`
- `!cust_memb`

---
### !add

Creates new struct.

Syntax:
```
# NewStructName
!add
private	a:	Byte := 0 // comment
		b:	Byte := 0
		c:	Byte // comment
*
public	d:	Byte
```
Default visibility is `public`.\
`*` turns into an empty line between fields.

---
### !cust_memb

Adds special member to the struct.

Syntax:
```
# StructName
!cust_memb
public procedure ...
```


