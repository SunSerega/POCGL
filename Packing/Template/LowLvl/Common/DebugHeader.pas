


{$region DEBUG}{$ifdef DEBUG}

// Регистрация всех вызовов, их параметров и результатов
{ $define CallDebug}

{ $define ForceMaxDebug}
{$ifdef ForceMaxDebug}
  {$define CallDebug}
{$endif ForceMaxDebug}

{$endif DEBUG}{$endregion DEBUG}


