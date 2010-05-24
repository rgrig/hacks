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
  @<Initialize@>@;
  @<Read DIMACS@>@;
  @<Compute minimal models@>@;
  @<Print result@>@;
}

@ The DIMACS format starts with comment lines, continues with a header line,
and the body follows. Comment lines start with |'c'|; the header line follows
the format |"p cnf %d %d"|, where the first integer is the number of variables
and the second integer is the number of clauses.  The body is a big list of
space separated numbers, which typically spans multiple lines. A positive
number represents a variable, a negative number represents a negated variable,
and zero marks the end of a clause.

Parsing is relaxed. It allows comment lines anywhere in the file, and defines a
comment line as being one whose first {\sl non-space} character is~|'c'|. The
number of clauses declared in the header line is checked in safe mode, but
otherwise is ignored and the whole body is read.

The result of parsing is that |cnf| contains the body and |cnf_variables_count|
the number of variables announced on the header line.

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

@ @d cnf_max (1<<20) // maximum size of |cnf|

@<Globals@>=
int cnf[cnf_max];
int cnf_size; // |cnf[0]| to |cnf[cnf_size-1]| are meaningful
int cnf_variables_count; 

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
@d trace (0) // what tracing is activated

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

@* Conflicts. Subtrees of the search tree are sometimes not visited, because it
is possible to determine early that none of their leafs satisfy~|cnf|. One
mechanism partially evaluates~|cnf| on a partial variable assignment and
another mechanism checks if the subtree's root (which is a search state) `hits'
a conflict. For the purposes of this program, a {\sl conflict\/} is a set of
literals that cannot all be in a minimal model.

ZDDs are a data structure suitable for representing a family of sets from an
ordered universe. A ZDD is a tree whose non-leafs have two distinguished
children, |low| and |high|, and whose leafs are $0$~or~$1$. The |high| branch
never points to leaf~$0$. Each non-leaf also has a |variable|. A child's
|variable| is greater than the parent's |variable|. An |auxiliary| field is
used by some algorithms.

There is a similar data structure, the BDD, whose invariants are different.
However, BDDs and ZDDs can co-exist and share memory, which is why there is
only one data type.

@<Data structures@>=
struct dd_node {
  int variable;
  int low;
  int high;
  int auxiliary;
};

@ These nodes are kept in a hashtable so that no two nodes that contain the
same three values in the fields |variable|,~|low|, and~|high| exist. This
method of avoiding memory waste is called {\sl hash-consing}. The values of
|low| and |high| are indexes in the hashtable if they are non-negative. The
leafs $0$~and~$1$ are represented as $-1$~and~$-2$, respectively. The 
hashtable uses linear probing. 

@d dd_false (-1)
@d dd_true (-2)
@d dd_bits 20  // how many bits are used for the hash

@<Globals@>=
struct dd_node dd_table[1<<dd_bits]; // |variable==0| means empty slot
int dd_table_used = 0; // used only in |safe| mode

@ The simplest algorithm on |dd_node|s is a recursive depth-first traversal
that zeros the |auxiliary| field of all reachable |dd_node|s. For the code here
to work, we must ensure that at no point a node has a non-zero |auxiliary|
while its parent has a zero |auxiliary|.

@<Helpers@>=
void dd_clean_auxiliary(int zdd) {
  struct dd_node* n = &dd_table[zdd];
  if (zdd < 0) return;
  if (n->auxiliary == 0) return;
  n->auxiliary = 0;
  dd_clean_auxiliary(n->low);
  dd_clean_auxiliary(n->high);
}

@ The function |dd_lookup| computes the hash and does linear probing.
 
@d prime1 0x678DDE6F
@d prime2 0xB504F33B
@d prime3 0xBB67AE93

@<Helpers@>=
int dd_lookup(int v, int l, int h) { @+
  int hash = v * prime1 + l * prime2 + h * prime3;
  hash = (hash >> (32 - dd_bits)) & ((1<<dd_bits)-1);
  while (1) {
    struct dd_node *p = &dd_table[hash];
    if (trace & trace_hash) printf("probe %d\n", hash);
    if (p->variable == 0) break;
    if (p->variable == v && p->low == l && p->high == h) break;
    hash = (hash + 1) & ((1<<dd_bits)-1);
  }
  return hash;
}

@ The function |dd_insert| uses |dd_lookup| to find an empty slot or an
existing node with the same structure. The function |zdd_insert| adds the
constraint |high!=dd_false|.

@<Helpers@>=
int dd_insert(int v, int l, int h) { @+
  int hash = dd_lookup(v, l, h);
  struct dd_node* r = &dd_table[hash];
  if (r->variable == 0) ++dd_table_used;
  check(dd_table_used > (1<<(dd_bits-1)), "dd_table is getting full");
  if (trace&trace_hash) printf("dd_table_used %d\n", dd_table_used);
  r->variable = v, r->low = l, r->high = h;
  return hash;
}

int zdd_insert(int v, int l, int h) 
{ @+ return h == dd_false? l: dd_insert(v, l, h); @+ }

@ Initially, the set of conflicts is empty.

@<Globals@>=
int conflicts = dd_false;

@ A partial variable assignment contains all the literals in some conflict if
there is a path from |conflicts| to |dd_true| that takes the |high| branch only
if |variable| is set to~$1$ in the partial variable assignment. This test takes
time linear in the size of the ZDD.

@<Operations on conflicts@>=
int hits_conflict_rec(int zdd, int *v, int v_fixed) {
  struct dd_node* n = &dd_table[zdd];
  if (zdd == dd_false) return 0;
  if (zdd == dd_true) return 1;
  if (n->auxiliary) return 0;
  n->auxiliary = 1;
  if (hits_conflict_rec(n->low, v, v_fixed)) return 1;
  if (n->variable > v_fixed || !v[n->variable]) return 0;
  return hits_conflict_rec(n->high, v, v_fixed);
}

int hits_conflict(int *v, int v_fixed) { @+
  int r = hits_conflict_rec(conflicts, v, v_fixed);
  dd_clean_auxiliary(conflicts);
  return r;
}

@ To add conflict $\{v_1,v_2,v_3\}$ we union the ZDD
$(v_1,0,(v_2,0,(v_3,0,1)))$ to the ZDD |conflicts|.

@<Operations on conflicts@>=
void add_conflict(int *v) { @+
  int c = dd_true;
  for (int i = cnf_variables_count; i > 0; --i) if (v[i])
    c = zdd_insert(i, dd_false, c);
  conflicts = zdd_union(conflicts, c);
}


@ The union of two ZDDs is easily expressed recursively.  In order to not redo
much work we need a memocache that remembers known facts of the form $a\cup
b=c$.

@<Data structures@>=
struct dd_memo_data {
  int leftop;
  int rightop;
  int result;
};

@ @<Globals@>=
struct dd_memo_data zdd_union_memo[1<<dd_bits];

@ @<Helpers@>=
int zdd_union(int z1, int z2) {
  struct dd_node* n1 = &dd_table[z1];
  struct dd_node* n2 = &dd_table[z2];
  struct dd_memo_data* m = &zdd_union_memo[z1^z2];
  if (z1 == dd_false) return z2;
  if (z2 == dd_false) return z1;
  if (z1 == dd_true && z2 == dd_true) return dd_true;
  if (z1 == dd_true) 
    return m->result = zdd_insert(n2->variable, zdd_union(dd_true, n2->low), n2->high);
  if (z2 == dd_true) 
    return m->result = zdd_insert(n1->variable, zdd_union(dd_true, n1->low), n1->high);
  if (m->leftop == z1 && m->rightop == z2) return m->result;
  if (n1->variable == n2->variable)
    return m->result = zdd_insert(n1->variable, zdd_union(n1->low, n2->low), zdd_union(n1->high, n2->high));
  else if (n1->variable < n2->variable)
    return m->result = zdd_insert(n1->variable, zdd_union(n1->low, z2), n1->high);
  else
    return m->result = zdd_insert(n2->variable, zdd_union(z1, n2->low), n2->high);
}

@ Initially |leftop| is set to an impossible value, so that there aren't any
`false' memocache hits.

@<Initialize@>= { @+
  for (int i = 0; i < (1<<dd_bits); ++i) zdd_union_memo[i].leftop=-3;
}

@ @<Print result@>= { @+
  int seen[cnf_variables_count + 1];
  memset(seen, 0, sizeof(seen));
  mark_seen(conflicts, seen);
  for (int i = 1; i <= cnf_variables_count; ++i) if (!seen[i])
    printf("%d\n", i); 
}

@ @<Includes@>=
#include <string.h>

@ @<Helpers@>=
void mark_seen(int z, int* seen) {
  struct dd_node* n = &dd_table[z];
  if (z == dd_false || z == dd_true || n->auxiliary) return;
  n->auxiliary = 1;
  seen[n->variable] = 1;
  mark_seen(n->low, seen);
  mark_seen(n->high, seen);
}


@* TODO.

@* Index.
