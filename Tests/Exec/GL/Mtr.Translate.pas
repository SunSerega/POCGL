## uses OpenGL;

Mtr2f.TranslatePrefix(10).Println;
Mtr3f.TranslatePrefix(10,20).Println;
Mtr4f.TranslatePrefix(10,20,30).Println;
(Mtr2x4f.IdentityKeepLast*Mtr4x4f.TranslatePrefix(10,20,30)).Println;
(Mtr4x2f.IdentityKeepLast*Mtr2x2f.TranslatePrefix(10)).Println;

Mtr2f.TranslatePostfix(10).Println;
Mtr3f.TranslatePostfix(10,20).Println;
Mtr4f.TranslatePostfix(10,20,30).Println;
(Mtr4x4f.TranslatePostfix(10,20,30)*Mtr4x2f.IdentityKeepLast).Println;
(Mtr2x2f.TranslatePostfix(10)*Mtr2x4f.IdentityKeepLast).Println;
