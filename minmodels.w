@* Intro. This program computes the minimal models of a boolean function. The
input format is DIMACS\null. The output is the set of variables that are~$0$ in
all minimal models.

This is the second program in a series. The main improvement is a smarter data
structure for conflicts.

@c
@<Includes@>@;
@h
@<Data structures@>@;
@<Globals@>@;
@<Helpers@>@;
@<Operations on conflicts@>@;

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

@ If |safe| is set to~|0| here, then the compiler should throw out all sanity
checks and generate a faster executable. You {\sl must not} have any
side-effects in the actual arguments for the |check| macro. Also, beware that a
|!safe| program may crash, for example on input that is invalid or too big.

@d safe 1 // whether to run sanity checks {\sl and} input validity checks
@d check(condition, message) if (safe && (condition)) { printf("%s\n", message); exit(1); }

@ Tracing (aka logging) may be activated selectively by setting |trace|.

@d trace_read_cnf (1<<0)
@d trace_models (1<<1)
@d trace_search (1<<2)
@d trace_hash (1<<3)
@d trace_all (-1)
@d trace (trace_models|trace_hash|trace_search) // what tracing is activated

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
    int unsat = 0; // whether |cnf| is unsatisfiable
    @<Evaluate conflicts and |cnf|@>@;
    if (!unsat && v_fixed == cnf_variables_count) @<Record model@>@;
    @<Advance or |break|@>@;
  }
}

@ @<Advance or |break|@>= { @+
  if (unsat || v_fixed == cnf_variables_count) {
    while (v_fixed > 0 && v[v_fixed]) --v_fixed;
    if (v_fixed == 0) break; // done
    v[v_fixed] = 1;
  } else v[++v_fixed] = 0;
}

@ The function |hits_conflict| returns whether the current partial variable
assignment implies a conflict recorded with the function |add_conflict|. Both
|hits_conflict| and |add_conflict| are described later.  If no conflict is
implied, then |cnf| is analyzed.

@<Evaluate conflicts and |cnf|@>= { @+
  unsat |= hits_conflict(v, v_fixed);
  unsat |= is_cnf_unsat(v, v_fixed);
  if (trace&trace_search) if (unsat) {
    printf("unsat ");
    @<Print model@>@;
  }
}

@ @<Helpers@>= 
int is_cnf_unsat(int *v, int v_fixed) {
  for (int i = 0; i < cnf_size; ++i) {
    while (1) {
      if (cnf[i] == 0) return 1; // unsat clause
      else if (cnf[i] > 0) { 
        if (cnf[i] > v_fixed || v[cnf[i]]) break;
      } else {
        if (-cnf[i] > v_fixed || !v[-cnf[i]]) break;
      }
      ++i;
    }
    while (cnf[++i] != 0);
  }
  return 0;
}

@ @<Print model@>= { @+
  for (int i = 1; i <= v_fixed; ++i)
    printf("%d", v[i]);
  printf("\n");
}

@ Once a (minimal) model is hit, it is added as a conflict.

@<Record model@>= { @+
  if (trace&trace_models) {
    printf("sat   ");  
    @<Print model@>@;
  }
  add_conflict(v);
}

@* Conflicts. Now the interesting part of this version. A conflict is a set of
variables that cannot all be~$1$ in a minimal model yet to be seen. ZDDs are
suitable for representing families of sets. Like BDDs, they are binary trees
whose non-leafs have branches |low| and |high| and whose leafs are the booleans
$0$~and~$1$.

@<Data structures@>=
typedef struct bdd_node_t {
  int variable;
  struct bdd_node_t *low, *high;
} bdd_node;

@ The booleans are represented by two special pointers |bdd_false| and
|bdd_true|.

@d bdd_false (&dummy_bdds[0])
@d bdd_true (&dummy_bdds[1])

@<Globals@>=
bdd_node dummy_bdds[2];

@ Both ZDDs and BDDs are hash-consed (aka reduced), meaning that there are no
two distinct |bdd_node|s that have the same values in their fields. This is
ensured by keeping |bdd_node|s in a hashtable. Whenever a |bdd_node| with a
certain content is needed, we first lookup the hashtable to see if there isn't
one already in there and, if there is, we reuse it.

@d bdd_bits_per_hash 20
@d bdd_table_size (1<<bdd_bits_per_hash)
@d bdd_hash_mask (bdd_table_size - 1)

@<Globals@>=
bdd_node bdd_table[bdd_table_size]; // |variable==0| means empty slot
int bdd_table_empty = bdd_table_size; // used only in |safe| mode

@ The function |bdd_lookup| computes the hash and does linear probing.
(The type |long long| is used to avoid warnings on systems that have
|sizeof(int) < sizeof(int*)|.)
 
@d prime1 1000003
@d prime2 10000019
@d prime3 100000007

@<Helpers@>=
bdd_node* bdd_lookup(int v, bdd_node *l, bdd_node *h) { @+
  int hash = v * prime1 + (long long) l * prime2 + (long long) h * prime3;
  hash = (hash >> (8 * sizeof(int) - bdd_bits_per_hash)) & bdd_hash_mask;
  while (1) {
    bdd_node *p = &bdd_table[hash];
    if (p->variable == 0) break;
    if (p->variable == v && p->low == l && p->high == h) break;
    hash = (hash + 1) & bdd_hash_mask;
    if (trace & trace_hash) printf("try hash %d\n", hash);
  }
  return &bdd_table[hash];
}

@ The function |generic_insert| uses |bdd_lookup| to find an empty slot or an
existing node with the same structure. The function |bdd_insert| adds the
constraint |high!=low|, while the function |zdd_insert| adds the constraint
|high!=bdd_false|.

@<Helpers@>=
bdd_node* generic_insert(int v, bdd_node *l, bdd_node *h) { @+
  bdd_node* r = bdd_lookup(v, l, h);
  if (r->variable == 0) --bdd_table_empty;
  check(bdd_table_empty < bdd_table_size / 2, 
      "The BDD hashtable is getting full.");
  if (trace&trace_hash) 
    printf("used bdd_nodes %d\n", bdd_table_size - bdd_table_empty);
  r->variable = v, r->low = l, r->high = h;
  return r;
}

bdd_node* bdd_insert(int v, bdd_node *l, bdd_node *h) 
{ @+ return l == h? l : generic_insert(v, l, h); @+ }

bdd_node* zdd_insert(int v, bdd_node *l, bdd_node *h) 
{ @+ return h == bdd_false? l: generic_insert(v, l, h); @+ }

@ Given this infrastructure, the set of conflicts is simply a pointer to
a |bdd_node|.

@<Globals@>=
bdd_node* conflicts = bdd_false;

@ Now, after setting up the infrastructure for creating |bdd_node|s, it is
time to see what they {\sl mean\/} in terms of conflicts.

@<Operations on conflicts@>=
int hits_conflict(int *v, int v_fixed) { @+
  bdd_node *p = conflicts;
  while (p != bdd_false && p != bdd_true) {
    if (p->variable > v_fixed) return 0;
    p = v[p->variable]? p->high: p->low;
  }
  return p == bdd_true;
}

@ Adding a conflict is a little more complicated. A generic way to compute the
union of two families of conflicts is
$$
\eqalign{
  (v, l_1, h_1) \lor (v, l_2, h_2) &= (v, l_1 \lor l_2, h_1 \lor h_2) \cr
  (v_1, l_1, h_1) \lor (v_2, l_2, h_2) &=
    (v_1, l_1 \lor (v_2, l_2, h_2), h_2 \lor (v_2, l_2, h_2))
    \qquad\hbox{\rm if $v_1<v_2$}.\cr
}
$$
The conflict $\{v_1,v_2,v_3\}$ is represented by $(v_1,0,(v_2,0,(v_3,0,1)))$.

@<Operations on conflicts@>=
void add_conflict(int *v) { @+
  bdd_node *p = bdd_true;
  for (int i = cnf_variables_count; i > 0; --i) if (v[i])
    p = zdd_insert(i, bdd_false, p);
  conflicts = zdd_or(conflicts, p);
}

@ @<Helpers@>=
bdd_node* zdd_or(bdd_node *a, bdd_node *b) {
  if (a == bdd_false) return b;
  if (b == bdd_false) return a;
  if (a == bdd_true || b == bdd_true) return bdd_true;
  if (a->variable == b->variable)
    return zdd_insert(a->variable, zdd_or(a->low, b->low), zdd_or(a->high, b->high));
  if (a->variable < b->variable)
    return zdd_or(b, a);
  return zdd_insert(b->variable, zdd_or(a, b->low), zdd_or(a, b->high));
}

@* TODO.
@ @<Print result@>=

@* Index.
