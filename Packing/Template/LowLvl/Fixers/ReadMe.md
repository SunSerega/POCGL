
Genral syntax of `.dat` files:
```
# ItemName
!change_type1
%change specific syntax line 1%
%change specific syntax line 2%
!change_type2
%change specific syntax%
```

---

Items can be grouped:
```
# ItemName1
# ItemName2
!change
```
Here `!change` applies to both.

---

Item name can be a template:
```
# ItemName[%1,2%]
!change
```
Unwraps to:
```
# ItemName1
!change
# ItemName2
!change
```

---

Template can be named:
```
# ItemName[%ind:1,2%]
!change{%ind%}
```
Unwraps to:
```
# ItemName1
!change1
# ItemName2
!change2
```

---

And can have insert conditions:
```
# ItemName[%ind:1,2%]
!change_{%ind?a:b%}
```
Unwraps to:
```
# ItemName1
!change_a
# ItemName2
!change_b
```


