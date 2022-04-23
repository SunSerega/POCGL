## uses OpenCLABC;

(HTPQ(()->begin end) + new ConstQueueNil).Println;

Println(
  (HTFQ(()->0) + new ConstQueueNil).Println
  + HTPQ(()->begin end)
);