﻿## uses OpenCLABC;

procedure Test<T>(q: CommandQueue<T>) := Write(q);

Test&<object>(new object);
Test&<object>(new Exception('TestOK') as object);
Test&<object>(nil as object);
Test&<object>(1 as object);
Test&<integer>(2);