@* Intro. I use this program to quickly list for each identifier in an OCaml
program the definition sites and the use sites. There is no parsing involved,
just lexing. For example, if the identifier $i$ is defined several times,
then there is only one entry for it listing several definition and, perhaps,
several uses. What constitutes a definition is also quite approximative:
the preceding identifier is {\tt let}.

For speed, simplicity, and predictability I allocate memory statically.
The values are chosen just big enough to handle the OCaml compiler
(2011-07-25), which is one of the biggest OCaml programs around.

@d max_word (1 << 8) /* the maximum length of a word */
@d max_trie (1 << 18) /* the maximum size of the trie */
@d max_positions (1 << 21) /* the maximum number of positions */

@c
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *f; /* the current open file */
char word[max_word]; /* the last read word */
int word_sz; /* how many characters of |word| are used */
int c; /* the last read character (may be |EOF|) */

int trie[max_trie][256];
  /* |0| means `no link present', positive values index in |trie| */
int uses[max_trie]; /* |uses[k]| indexes the head of a list in |positions| */
int defs[max_trie]; /* |defs[k]| indexes the head of a list in |positions| */
int trie_sz = 1; /* how much of |trie| is used, size for |trie|, |uses|, and |defs| */

struct {
  int file; /* index in |argv| */
  int line;
  int column;
  int next; /* index in |positions| */
} positions[max_positions];
int positions_sz; /* how many elements of |positions| are used */

int line; /* current line */
int column; /* current position */

int main(int argc, char* argv[]) {
  for (int file = 1; file < argc; ++file) @<Process |argv[file]|@>@;
  @<Print results@>@;
  return 0;
}

@ To clarify the data structures, we begin with printing the results.
The |trie| maps words to the positions where they were seen. For each word
there are two lists, one with uses and one with definitions. All these
lists are stored in |positions|.

@<Print results@>= {
  int trie_stack_idx[max_word]; /* for backtracking, index in |trie| */
  int trie_stack_chr[max_word];
    /* |trie[trie_stack_idx[k]][trie_stack_chr[k]]| for |0<=k<trie_stack_sz|
      tracks where we've been */
  int i; /* index in |trie| */
  int j; /* index in |trie[i]| */
  word_sz = i = j = 0;
  while (1) {
    if (!j && (uses[i] || defs[i])) {
      int p; /* index in |positions| */
      word[word_sz] = 0;
      if (!uses[i]) fprintf(stderr, "%s appears unused\n", word);
      printf("%s[",word);
      p = defs[i];
      @<Print positions starting at |p|@>@;
      printf("](");
      p = uses[i];
      @<Print positions starting at |p|@>@;
      printf(")\n");
    }
    if (trie[i][j]) {
      trie_stack_idx[word_sz] = i;
      trie_stack_chr[word_sz] = j;
      word[word_sz++] = j;
      i = trie[i][j];
      j = 0;
    } else {
      while (j == 255 && word_sz) {
        --word_sz;
        i = trie_stack_idx[word_sz];
        j = trie_stack_chr[word_sz];
      }
      if (j == 255 && !word_sz) break;
      ++j;
    }
  }
}

@ @<Print positions starting at |p|@>=
while (p) {
  printf("%s:%d:%d",argv[positions[p].file],positions[p].line,positions[p].column);
  p = positions[p].next;
  if (p) putchar(' ');
}

@ Of course, we must also build those data structures.

@d fail(m) {
  fprintf(stderr,"INTERNAL: %s\n",m);
  exit(1);
}

@<Process |argv[file]|@>= {
  int last_let = 0;
  f = fopen(argv[file],"r");
  if (f) {
    line = column = 1;
    while ((c = fgetc(f))!=EOF) {
      if (isalnum(c)||c=='_'||c=='\'') {
        word[word_sz++] = c;
        if (word_sz == max_word) fail("increase max_word");
      } else if (word_sz) @<Process |word|@>
      if (c != '\n') ++column; else { column = 1; ++line; }
    }
    if (word_sz) @<Process |word|@>
    fclose(f);
  } else {
    fprintf(stderr,"Cannot read %s. Skipping.\n",argv[file]);
  }
}

@ @<Process |word|@>= {
  word[word_sz]=0;
  if (!strcmp("let",word) || !strcmp("rec",word)) {
    last_let = 1;
  } else {
    int i, j;
    int *locs = last_let? defs : uses;
    for (i = j = 0; j < word_sz; ++j) {
      if (!trie[i][(int)word[j]]) {
        if (trie_sz == max_trie) fail("increase max_trie");
        trie[i][(int)word[j]] = trie_sz++;
      }
      i = trie[i][(int)word[j]];
    }
    if (positions_sz == max_positions) fail("increase max_positions");
    positions[positions_sz].file = file;
    positions[positions_sz].line = line;
    positions[positions_sz].column = column - word_sz;
    positions[positions_sz].next = locs[i];
    locs[i] = positions_sz++;
    last_let = 0;
  }
  word_sz = 0;
}
