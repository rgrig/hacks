@* Intro. Some programs, such as {\tt ocamldebug} point inside text files
using a character count, instead of a (line, column) pair.

@s line foo
@c
#include <stdio.h>

int main(int argc, char* argv[]) {
  if (argc != 3) @<Display usage and exit@>@;
  int position;
  if (sscanf(argv[1],"%d",&position) != 1) @<Display usage and exit@>@;
  if (position < 0) @<Report outside file and finish@>@;
  FILE* f = fopen(argv[2],"r");
  if (!f) @<Display usage and exit@>@;
  char c;
  int line = 1, column = 1;
  while ((c = fgetc(f)) != EOF) {
    ++column, --position;
    if (position == 0) @<Report line:col and finish@>@;
    if (c == '\n') ++line, column = 1;
  }
  @<Report outside file...@>@;
}

@ @<Display usage and exit@>= {
  printf("pos <byte_count> <file_name>\n");
  return 1;
}

@ @<Report outside file...@> = {
  printf("outside\n");
  return 0;
}

@ @<Report line:col...@>= {
  printf("%d:%d\n",line,column);
  return 0;
}

@
% vim:tw=75:fo+=t:
