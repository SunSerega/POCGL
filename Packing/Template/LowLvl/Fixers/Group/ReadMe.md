


# Change types:

- `!add`
- `!rename`
- `!base`
- `!cust_memb`

---
### !add

Creates new group.

Syntax:
```
# NewGroupName
!add
UInt32
true
x=56
y=0xAB
```
First line specifies underlying basic type.\
Second line specifies if group is bitmask.

---
### !rename

Syntax:
```
# OldGroupName
!rename
NewGroupName
```

---
### !base

Sets underlying basic type.\
Errors out of basic type is already set.

Syntax:
```
# GroupName
!base
BasicTypeName
```

---
### !cust_memb

Adds special member to the group.

Syntax:
```
# api::ErrorCode
!cust_memb

public procedure RaiseIfError;
begin
  //ToDo ...
end;

```


