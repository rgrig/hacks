\def\fb#1{{\bf#1}}
\def\fls{\bottom}
\def\tru{\top}

@* Intro. This program computes the minimal models of a boolean
function. The input format is DIMACS\null. The output is the
set of variables that are~$0$ in all minimal models. The data
structure operations are (very) slow, but the overall structure
of the program should allow significant efficiancy gains by
plugging in more efficient data structures.

@c
@<Includes@>@;
@h
@<Globals@>@;
@<Debugging helpers@>@;
@<Helpers@>@;

int main() @+ {
  @<Read DIMACS@>@;
  @<Compute minimal models@>@;
  @<Print result@>@;
}

@ The formula is represented internally very similar to how it
appears in the input file.

@d cnf_max (1<<20) // maximum size of |cnf|

@<Globals@>=
int cnf[cnf_max];
int m; // number of variables
int n; // number of clauses

@ The following parsing procedure is forgiving and will succeed
on invalid DIMACS files.

@s line foo
@d line_max (1<<20) // longest line length, including |"\n\0"|

@<Read DIMACS@>= { @+
  int nn = 0; // number of clauses actually read, only used in |safe| mode
  int cnf_sz = 0; // how much of |cnf| is used
  char line[line_max]; // the last read line
  register char *p; // pointer in |line|
  line[line_max-2] = '\0';
read_lines:
  while (fgets(line,line_max,stdin)) {
    check(line[line_max-2], "Line too long.");
    for (p = line; isspace(*p); ++p);
    switch (*p) {
    case 'c': goto read_lines;
    case 'p': sscanf(p,"p cnf %d %d",&m,&n); @+ break;
    default:
      for (int d; sscanf(p," %d%n",&cnf[cnf_sz], &d) == 1; ++cnf_sz) {
        p += d;
        check(cnf_sz > cnf_max, "Input too big.");
        if (safe && !cnf[cnf_sz]) ++nn;
      }
    }
  }
  if (trace&trace_read_cnf) @<Print |cnf|@>;
  check(n != nn, "Wrong number of clauses.");
}

@ @<Includes@>=
#include <ctype.h>
#include <stdio.h>

@ If |safe| is set to |0| here, then the compiler should throw
out all sanity checks and generate a faster executable. You {\sl
must not} have any side-effects in the actual arguments for
the |check| macro. Also, beware that a program compiled with
|safe==0| may crash on invalid input.

@d safe 1 // whether to run sanity checks {\sl and} input validity checks
@d check(condition, message) if (safe && (condition)) { printf("%s\n", message); exit(1); }

@ Tracing (aka logging) may be activated selectively by setting |trace|.

@d trace_read_cnf (1<<0)
@d trace_all (-1)
@d trace (trace_all) // tracing is activated

@ @<Includes@>=
#include <stdlib.h>

@ @<Print |cnf|@>= { @+ 
  int *l = cnf - 1; // current literal
  printf("p cnf %d %d\n", m, n);
  for (int i = 0; i < n; ++i) {
    while (*++l) printf("%d ", *l);
    printf("0\n");
  }
}


@ TODO.

@ @<Includes@>=
@ @<Debugging helpers@>=
@ @<Helpers@>=
@ @<Read DIMACS@>=
@ @<Compute minimal models@>=
@ @<Print result@>=

