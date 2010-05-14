@* Intro. This program computes the minimal models of a boolean function. The
input format is DIMACS\null. The output is the set of variables that are~$0$ in
all minimal models. The data structures are dumb but, I hope, it is possible to
significantly improve the speed by choosing better ones and keeping the overall
structure.

@c
@<Includes@>@;
@h
@<Globals@>@;
@<Helpers@>@;

int main() @+ {
  @<Read DIMACS@>@;
  @<Compute minimal models@>@;
  @<Print result@>@;
}

@ The formula is represented internally very similar to how it appears in the
input file.

@d cnf_max (1<<20) // maximum size of |cnf|

@<Globals@>=
int cnf[cnf_max];
int cnf_size; // |cnf[0]| to |cnf[cnf_size-1]| are meaningful
int cnf_variables_count; 

@ The following parsing procedure is forgiving and will succeed on invalid
DIMACS files. All clauses are read, even if fewer are announced by the |"p cnf"|
line.

@s line foo

@<Read DIMACS@>= { @+
  const int ll = 1 << 20; // longest line, including |"\n\0"|
  char line[ll]; // the last read line
  char *p; // pointer in |line|
  line[ll-2] = '\0';
read_lines:
  while (fgets(line,ll,stdin)) {
    check(line[ll-2], "Line too long.");
    for (p = line; isspace(*p); ++p);
    switch (*p) {
    case 'c': 
      goto read_lines;
    case 'p': 
      sscanf(p,"p cnf %d",&cnf_variables_count); @+ break;
    default:
      for (int d; sscanf(p," %d%n",&cnf[cnf_size], &d) == 1; ++cnf_size) {
        p += d;
        check(cnf_size > cnf_max, "Input too big.");
      }
    }
  }
  if (trace&trace_read_cnf) @<Print |cnf|@>@;
  if (safe) {
    for (int i = 0; i < cnf_size; ++i)
      check(abs(cnf[i])>cnf_variables_count, "Wrong literal.");
    check(cnf[cnf_size - 1] != 0, "Last integer in input should be 0.");
  }
}

@ @<Includes@>=
#include <ctype.h>
#include <stdio.h>

@ If |safe| is set to |0| here, then the compiler should throw out all
sanity checks and generate a faster executable. You {\sl must not} have any
side-effects in the actual arguments for the |check| macro. Also, beware that a
|!safe| program may crash on invalid input.

@d safe 1 // whether to run sanity checks {\sl and} input validity checks
@d check(condition, message) if (safe && (condition)) { printf("%s\n", message); exit(1); }

@ Tracing (aka logging) may be activated selectively by setting |trace|.

@d trace_read_cnf (1<<0)
@d trace_models (1<<1)
@d trace_search (1<<2)
@d trace_all (-1)
@d trace (trace_models) // what tracing is activated

@ @<Includes@>=
#include <stdlib.h>

@ @<Print |cnf|@>= { @+ 
  for (int i = 0; i < cnf_size; ++i) {
    printf("%d ", cnf[i]);
    if (cnf[i] == 0) printf("\n");
  }
}

@ To find all minimal models we try variable assignments in increasing
lexicographic order. When a model is found, a set of literals is recorded in
|conflicts|, such that no bigger model will be visited. As a small optimization,
instead of setting all variables and then evaluating the |cnf|, the variables
are set one by one: By partially evaluating |conflicts| and |cnf| it is possible
sometimes to see that all variable assignments with a certain prefix are not
minimal models.

@<Compute minimal models@>= { @+
  int v[cnf_variables_count + 1]; // the current variable assignment
  int v_fixed = 0; 
    // how many variables are fixed, |v[1]| to |v[v_fixed]| are meaningful
  while (1) {
    int sat = 1; // whether |cnf| is possibly satisfiable
    @<Evaluate conflicts and |cnf|@>@;
    if (sat && v_fixed == cnf_variables_count) @<Record model@>@;
    @<Advance or |break|@>@;
  }
}

@ @<Globals@>=
int conflicts[cnf_max]; // conflicts represented in CNF
int conflicts_size; // how much of |conflicts| is used

@ @<Advance or |break|@>= { @+
  if (!sat || v_fixed == cnf_variables_count) {
    while (v_fixed > 0 && v[v_fixed]) --v_fixed;
    if (v_fixed == 0) break; // done
    v[v_fixed] = 1;
  } else v[++v_fixed] = 0;
}

@ The function |evaluate_cnf| returns false only if the partial variable
assignment in |v| makes the formula evaluate to false.

@<Evaluate conflicts and |cnf|@>= { @+
  sat &= evaluate_cnf(conflicts, conflicts_size, v, v_fixed);
  sat &= evaluate_cnf(cnf, cnf_size, v, v_fixed);
  if (trace&trace_search) if (!sat) {
    printf("unsat ");
    @<Print model@>@;
  }
}

@ @<Helpers@>= 
int evaluate_cnf(int *f, int f_size, int *v, int v_size) {
  for (int i = 0; i < f_size; ++i) {
    while (f[i]!=0&&abs(f[i])<=v_size&&((f[i]>0&&!v[f[i]])||(f[i]<0&&v[-f[i]]))) ++i;
    if (f[i] == 0) return 0; // unsat clause
    while (f[i] != 0) ++i;
  }
  return 1;
}

@ @<Print model@>= { @+
  for (int i = 1; i <= v_fixed; ++i)
    printf("%d", v[i]);
  printf("\n");
}

@ A conflict is a clause that makes sure at least one of the variables set
to~$1$ in the current model will be~$0$ in all subsequent explored variable
assignments.

@<Record model@>= { @+
  if (trace&trace_models) {
    printf("sat   ");  
    @<Print model@>@;
  }
  for (int i = 1; i <= cnf_variables_count; ++i) if (v[i]) {
    check(conflicts_size > cnf_max, "Too many minimal models.");
    conflicts[conflicts_size++] = -i;
  }
  check(conflicts_size > cnf_max, "Too many minimal models.");
  conflicts[conflicts_size++] = 0;
}

@ Finally, the variables that are~$0$ in all minimal models are those that
do not appear in |conflicts|.

@<Print result@>= { @+
  int v[cnf_variables_count + 1];
  memset(v, 0, sizeof v);
  for (int i = 0; i < conflicts_size; ++i)
    v[abs(conflicts[i])] = 1;
  for (int i = 1; i <= cnf_variables_count; ++i) if (!v[i])
    printf("%d\n", i);
}

@ @<Includes@>=
#include <string.h>

@* Index.
