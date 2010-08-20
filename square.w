@* Intro. A {\it shuffle\/} of two words is obtained by merging, in some order,
the letters of the two words. A {\it square\/} is a shuffle of a word with
itself. This program counts how many squares are there of length~$2$,~$4$,
$6$,~$\ldots$ It works for words over the alphabet~$\{0,1\}$.

@ To generate all squares of length~$2n$ we go through all $2^n$ words of
length~$n$ and through all ${2n\choose n}$ merging patterns. Once a shuffle is
computed, it is inserted in a hashtable. The runtime is proportional
to~$2n\times2^{3n}$, so it should work in reasonable time up to $n\approx8$.

@ The ${2n\choose n}$ merging patterns are generated using Algorithm~C
in TAoCP~7.2.1.3.

@c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
@<Debug@>@;
@<Hashtable@>@;

int main() {
  for (int n = 0; n <= 12; ++n) {
    hash_clear();
    for (int w = 0; w < (1<<n); ++w){
      int p; // merging pattern, goes thru ${2n\choose n}$ bitstrings
      int pw, pr, pj; // used to generate |p|
      p = ((1<<n)-1)<<n;
      pw = (1 << (2*n+1))-1;
      pr = n;
      while (1) {
        @<Visit merging pattern |p|@>@;
        @<Advance |p| or |break|@>@;
      }
    }
if (0) for (int k=0;k<hsize;++k) if (htable[k]>=0) 
printf("** %02x\n", htable[k]);
    printf("%d %d\n", n, hcount);
  }
}

@ @<Visit...@>= {
if (0) printf("** p %02x\n", p);
  int shuffle = 0;
  int i, j; // indices in |w|
  int k; // index in |p| and |shuffle|
  for (i = j = k = 0; k < 2*n; ++k) {
    if ((p>>k)&1) {
      if ((w>>i++)&1) shuffle |= 1<<k;
    } else {
      if ((w>>j++)&1) shuffle |= 1<<k;
    }
  }
if(0)if (bitparity(shuffle)) printf("OOPS w=%x p=%02x s=%02x\n", w,p,shuffle);
  hash_insert(shuffle);
}

@ @<Advance...@> = {
  for (pj=pr; !((pw>>pj)&1); ++pj) pw |= (1<<pj);
  if (pj == 2*n) break;
  pw &= ~(1<<pj);
  if ((p>>pj)&1) {
    if ((pj&1)||((p>>(pj-2))&1)) {
      p |= (1<<(pj-1));
      p &= ~(1<<pj);
      if (pr==pj && pj>1) pr = pj-1;
      else if (pr==pj-1) pr = pj;
    } else {
      p |= (1<<(pj-2));
      p &= ~(1<<pj);
      if (pr==pj) pr = pj-2>1? pj-2: 1;
      else if (pr==pj-2) pr = pj-1;
    }
  } else {
    if (!(pj&1)||((p>>(pj-1))&1)) {
      p |= (1<<pj);
      p &= ~(1<<(pj-1));
      if (pr==pj && pj>1) pr = pj - 1;
      else if (pr == pj - 1) pr = pj;
    } else {
      p |= (1<<pj);
      p &= ~(1<<(pj-2));
      if (pr == pj-2) pr=pj;
      else if (pr==pj-1) pr=pj-2;
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

void hash_insert(int x) {
  int h = ((x * 2654435769) >> (32 - hbits)) & hmask;
  while (htable[h]>=0 && htable[h]!=x) h = (h+1)&hmask;
  if (htable[h]<0) {
    ++hcount;
    htable[h]=x;
  }
  if (hcount > hsize/2) {
    printf("need bigger hash\n");
    exit(1);
  }
}

@ @<Debug@>=
int bitparity(int x) { return x==0? 0 : (x&1)^bitparity(x>>1); }
