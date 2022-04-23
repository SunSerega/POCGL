## uses OpenCLABC;
var Q1 := HTFQ(()->5);

Println( (Q1+Q1) + (Q1+Q1) );
Println( (Q1*Q1) * (Q1*Q1) );

Println( (Q1+Q1) * (Q1+Q1) );
Println( (Q1*Q1) + (Q1*Q1) );