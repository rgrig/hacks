\def\dts{\mathinner{\ldotp\ldotp}}

@* Intro. This program generates all binary squares of length $0$,~$2$, $4$,
\dots A (binary) {\it square\/} is a shuffle of a (bit) string with itself. A
string {\it shuffle\/} of two strings is obtained by merging them in some
order. (Here, `merging' is used in the sense of merge-sort.)

@ First we generate all squares, and then we go through all bitstrings and
check that a certain recognition algorithm gives correct results.

@d N 6 // maximum half-length of a string being handled

@c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
@<Hashtable@>@;
@<Recognition@>@;

int main() {
  for (int n = 0; n <= N; ++n) {
    @<Generate all squares@>@;
    @<Try the recognition algorithm@>@;
  }
}

@ To generate all squares of length~$2n$ we go through all strings of
length~$n$ and all merging patterns of length~$2n$.

@<Generate all squares@>= {
  hash_clear();
  int sn; // strings of length $n$
  for (sn = 0; sn < (1<<n); ++sn){
    @<Initialize merging pattern generation@>@;
    while (1) {
      @<Visit |mp|@>@;
      @<Advance |mp| or |break|@>@;
    }
  }
}

@ @<Visit |mp|@>= {
  int square = 0;
  int i, j; // indices in |sn|
  int k; // index in |mp| and |square|
  for (i = j = k = 0; k < 2*n; ++k) {
    if ((mp>>k)&1) {
      if ((sn>>i++)&1) square |= 1<<k;
    } else {
      if ((sn>>j++)&1) square |= 1<<k;
    }
  }
  hash_insert(square);
}

@ We try a {\sl Range Concatenation Grammar\/} proposed by Sylvain on
the TCS Q\&A site. Rules:
\par\qquad $S(XY)\to A(X,Y)$
\par\qquad $A(aX_1,aX_2Y_1Y_2)\to A(X_1,Y_1) A(X_2,Y_2)$
\par\qquad $A(\epsilon,\epsilon)\to \epsilon$

There's a function for $s$ and a function for $a$. These return true when
there is a derivation that reaches~$\epsilon$. The results are cached in
tables of booleans |cache_a| and |cache_s|. The arguments of the functions
|S| and |A| are ranges in the string |snn| being processed.

@<Try the recognition...@>= {
  printf("%d %d\n", n, hcount);
  for (snn = 0; snn < (1<<(2*n)); ++snn) {
    memset(cache_a,-1,sizeof(cache_a));
    memset(cache_s,-1,sizeof(cache_s));
    char rr = s(0,2*n);
    char hr = htable[hash_search(snn)] == snn;
    if (rr != hr) printf("OOPS %04x %d %d\n", snn, rr, hr);
  }
}

@ @<Recognition@>=
int snn; // a string of length $2n$ that is being recognized
char cache_s[2*N+1][2*N+1]; // |cache_s[i][j]| says whether $S({\it snn}[i\dts j))$ may reach $\epsilon$
char cache_a[2*N+1][2*N+1][2*N+1][2*N+1];

char a(int i, int j, int k, int l) { 
  int ii, jj;
  if (i == j) return k == l;
  if (cache_a[i][j][k][l]!=-1) return cache_a[i][j][k][l];
  if (((snn>>i)&1)!=((snn>>k)&1)) return cache_a[i][j][k][l] = 0;
  for (ii = k+1; ii <= l; ++ii) {
    for (jj = ii; jj <= l; ++jj) {
      if (a(i+1,j,ii,jj) && a(k+1,ii,jj,l)) {
printf("%04x A(%d,%d,%d,%d)->A(%d,%d,%d,%d)A(%d,%d,%d,%d)\n",snn,i,j,k,l,i+1,j,ii,jj,k+1,ii,jj,l);
        return cache_a[i][j][k][l] = 1;
      }
    }
  }
  return cache_a[i][j][k][l] = 0;
}

char s(int i, int j) {
  int k; 
  if (cache_s[i][j]!=-1) return cache_s[i][j];
  for (k=i; k <= j; ++k)
    if (a(i,k,k,j)) break;
  return cache_s[i][j] = (k<=j);
}


@ The ${2n\choose n}$ merging patterns are generated using Algorithm~C
in TAoCP~7.2.1.3.

@<Initialize merging...@>=
int mp; // merging pattern
int mpw, mpr, mpj; // |w|, |r|, and |j| from Algorithm C
mp = ((1<<n)-1)<<n;
mpw = (1 << (2*n+1))-1;
mpr = n;

@ @<Advance |mp|...@> = {
  for (mpj=mpr; !((mpw>>mpj)&1); ++mpj) mpw |= (1<<mpj);
  if (mpj == 2*n) break;
  mpw &= ~(1<<mpj);
  if ((mp>>mpj)&1) {
    if ((mpj&1)||((mp>>(mpj-2))&1)) {
      mp |= (1<<(mpj-1));
      mp &= ~(1<<mpj);
      if (mpr==mpj && mpj>1) mpr = mpj-1;
      else if (mpr==mpj-1) mpr = mpj;
    } else {
      mp |= (1<<(mpj-2));
      mp &= ~(1<<mpj);
      if (mpr==mpj) mpr = mpj-2>1? mpj-2: 1;
      else if (mpr==mpj-2) mpr = mpj-1;
    }
  } else {
    if (!(mpj&1)||((mp>>(mpj-1))&1)) {
      mp |= (1<<mpj);
      mp &= ~(1<<(mpj-1));
      if (mpr==mpj && mpj>1) mpr = mpj - 1;
      else if (mpr == mpj - 1) mpr = mpj;
    } else {
      mp |= (1<<mpj);
      mp &= ~(1<<(mpj-2));
      if (mpr == mpj-2) mpr=mpj;
      else if (mpr==mpj-1) mpr=mpj-2;
    }
  }
}

@ The hashtable uses linear probing. The hash function is multiplicative.

@d hbits 24
@d hsize (1<<hbits)
@d hmask (hsize-1)

@<Hashtable@>=
int htable[hsize];
int hcount;

void hash_clear() {
  hcount = 0;
  memset(htable,-1,sizeof(htable));
}

int hash_search(int x) {
  int h = ((x * 2654435769) >> (32 - hbits)) & hmask;
  while (htable[h]>=0 && htable[h]!=x) h = (h+1)&hmask;
  return h;
}

void hash_insert(int x) {
  int h = hash_search(x);
  if (htable[h]<0) {
    ++hcount;
    htable[h]=x;
  }
  if (hcount > hsize/2) {
    printf("need bigger hash\n");
    exit(1);
  }
}


