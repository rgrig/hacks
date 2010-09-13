#include <stdio.h>
int main() {
  char*s="#include <stdio.h>\nint main() {\n  char*s=\"%\";\n  char*t=s;\n  while (*s != '%') putchar(*s++);\n  while (*t) {\n    if (*t=='\\n')  { putchar('\\\\'); putchar('n'); }\n    else if (*t=='\"') { putchar('\\\\'); putchar('\"'); }\n    else if (*t=='\\\\') { putchar('\\\\'); putchar('\\\\'); }\n    else putchar(*t);\n    ++t;\n  }\n  while (*++s) putchar(*s);\n}\n";
  char*t=s;
  while (*s != '%') putchar(*s++);
  while (*t) {
    if (*t=='\n')  { putchar('\\'); putchar('n'); }
    else if (*t=='"') { putchar('\\'); putchar('"'); }
    else if (*t=='\\') { putchar('\\'); putchar('\\'); }
    else putchar(*t);
    ++t;
  }
  while (*++s) putchar(*s);
}
