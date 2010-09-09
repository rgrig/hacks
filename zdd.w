@* Intro. This program is a small experiment to see how hard it is to represent
{\sc CNF} formulas as {\sc ZDD}s.

@c
@<Includes@>@;
@<Data types@>@;
@<Globals@>@;
@<Functions@>@;
int main() { @+
  @<Initialize@>@;
  @<Read {\sc CNF} and build {\sc ZDD}@>@;
  @<Report mems@>@;
}

@ To debug this program I use sanity checks activated by |safe| and logging
activated by |trace|.

@d safe 1
@d trace (0)
@d assert(cond) 
  if (safe && !(cond)) {
    printf("FAIL@@%d: %s", __LINE__, #cond);
    exit(1);
  }

@ @<Includes@>=
#include <stdio.h>
#include <stdlib.h>

@ To count mems we use some convenient macros.

@d o ++mems
@d oo mems+=2
@d ooo mems+=3
@d oooo mems+=4
@d ooooo mems+=5
@d oooooo mems+=6

@<Globals@>=
int mems; // memory references

@ Let's start with the {\sc ZDD} infrastructure.

@<Data types@>=
struct dd_node {
  int variable;
  int low;
  int high;
  int auxiliary;
};

@ All |dd_node|s are kept in a big hashtable, which is statically allocated for
simplicity (and speed). Nodes will be identified by their index in this big
table, except for |dd_fls| and |dd_tru|, which are represented by negative
integers.

@d dd_bits 20
@d dd_size (1<<dd_bits)
@d dd_mask (dd_size-1)
@d dd_fls (-2)
@d dd_tru (-1)
@d V(x) dd_table[x].variable
@d LO(x) dd_table[x].low
@d HI(x) dd_table[x].high

@<Globals@>=
struct dd_node dd_table[dd_size]; // |V(x)==0| means that slot |x| is empty
int dd_table_used;

@ Lookup uses linear probing.

@d prime1 0x678DDE6F
@d prime2 0xB504F33B
@d prime3 0xBB67AE93

@<Functions@>=
int dd_lookup(int v, int l, int h) { @+
  int z = ((v * prime1 + l * prime2 + h * prime3) >> (32-dd_bits))&dd_mask;
  assert(v != 0);
  while ((o, V(z) != v) || (o, LO(z) != l) || (o, HI(z) != h))
    z = (z + 1) & dd_mask;
  return z;
}

@ To insert a node we use the location given by |dd_lookup|.

@<Functions@>=
int dd_mk(int v, int l, int h) { @+
  int z = dd_lookup(v, l, h);
  ooo, V(z) = v, LO(z) = l, HI(z) = h;
  assert(++dd_table_used < dd_size / 2);
  return z;
}

@ A {\sc ZDD}'s |high| branch never points to |dd_fls|.

@<Functions@>=
int zdd(int v, int l, int h) 
{ @+ return h == dd_fls? l : dd_mk(v, l, h); @+ }

@ The big {\sc ZDD} will be built by computing repeated unions. A memocache
keeps the results of unions so they are not done over and over.

@<Data types@>=
struct memo {
  int a, b, c; // $c=a\cup b$ and $a<b$
};

@ @<Globals@>=
struct memo memocache[dd_size];

@ The recursive union algorithm is straightforward.

@<Functions@>=
int zdd_union(int a, int b) { @+
  struct memo* m = &memocache[a ^ b]; // shorthand name
  if (a > b) return zdd_union(b, a);
  if (a == b) return a;
  if (a == dd_fls) return b;
  assert(dd_fls<dd_tru);
  if (a == dd_tru) return ooo, zdd(V(b), zdd_union(dd_tru, LO(b)), HI(b));
  if ((o, m->a == a) && (o, m->b == b)) return o, m->c;
  oo, m->a = a, m->b = b;
  if (oo, V(a) == V(b))
    return oooooo, m->c = zdd(V(a), zdd_union(LO(a),LO(b)), zdd_union(HI(a),HI(b)));
  if (oo, V(a) < V(b))
    return oooo, m->c = zdd(V(a), zdd_union(LO(a), b), HI(a));
  return oooo, m->c = zdd(V(b), zdd_union(LO(b), a), HI(b));
}

@ 

@* TODO.
@ @<Initialize@>=
@ @<Read...@>=
@ @<Report...@>=
