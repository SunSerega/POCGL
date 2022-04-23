## uses OpenCLABC;

var Q := HQFQ(()->1);

(Q >= Q).Println;
Q.HandleWithoutRes(e->true).Println;
Q.HandleDefaultRes(e->true, 2).Println;
Q.HandleReplaceRes(lst->3).Println;