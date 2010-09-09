\def\[#1,#2){[#1.\,.\>#2)}

\datethis
@* Intro. The call {\tt ./kd datafile} reads the content of
{\tt datafile} line-by-line and then waits for queries from
the command line. Each line in {\tt datafile} represents a
point whose coordinates are the whitespace separated strings on
that line. A query puts a minimum and a maximum limit on each
coordinate.

@ The function |sort(c,a,b)| arranges the subarray $\[a,b)$
such that the element in position $m=\lfloor(a+b)/2\rfloor$ is
a median with respect to coordinate~$c$ and then recursively
calls |sort(cc,a,m)| and |sort(cc,m+1,b)|, where |cc=(c+1)%d|.
Its running time is therefore given by the recurrence
$T(n)=2T(n/2)+f(n)$, where $f(n)$ is the number of operations
needed to put the median in its proper place. Note that
both $f(n)=\Theta(n)$ and $f(n)=\Theta(n\lg n)$ lead to
$T(n)=\Theta(n\lg n)$, so assymptotically it doesn't matter if we
use QuickSelect or QuickSort. The former should still be somewhat
quicker in practice.

@d dmax (1<<3) /* maximum dimension */
@d lmax (1<<7) /* maximum line length */
@d nmax (1<<24) /* maximum number of points */
@d blen (1<<29) /* maximum size of the whole input */

@c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <readline/readline.h>
#include <readline/history.h>

int d; /* the number of dimensions */
char *points[nmax][dmax]; /* the array of points */
int n; /* the number of points */
char buffer[blen]; /* holder of the actual data */
char range[2*dmax][lmax]; /* minimum and maximum for each coordinate */
int qcnt; /* performance counter */
int rcnt; /* results count */

@<Helper functions@>@;

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("usage: %s datafile\n",argv[0]);
    return 1;
  }
  srand(123);
  @<Read the content of file |argv[1]|@>;
  printf("sorting...\n");
  sort(0, 0, n);
  @<Answer queries one-by-one@>;
  return 0; 
}

@ QuickSelect needs to swap points while partitioning.

@<Helper functions@>=
void swap(int a, int b) {
  char *p[dmax]; /* temporary point */
  int size = d * sizeof(char*);
  memcpy(p,points[a],size);
  memcpy(points[a],points[b],size);
  memcpy(points[b],p,size);
}

@ QuickSelect is needed for sorting. On average, its complexity
is given by $T(n)=T(n/2)+\Theta(n)$ that has the solution
$T(n)=\Theta(n)$, but is quadratic in the worst case.

@<Helper functions@>=
void quickselect(int c, int a, int b, int k) {
  if (b - a <= 1) return;
  int i; /* elements in range $\[a+1,i)$ are |<=points[a]| */
  int j; /* elements in range $\[i,j)$ are |>=point[a]| */
  swap(a, a + rand() % (b - a));
  for (i = j = a + 1; j < b; ++j) {
    int cmp = strcmp(points[j][c],points[a][c]);
    if (cmp < 0 || (cmp == 0 && (rand()&1)))
       swap(i++, j);
  }
  swap(--i, a);
  if (k < i) quickselect(c, a, i, k);
  if (k > i) quickselect(c, i+1, b, k);
}

@ @<Helper functions@>=
void sort(int c, int a, int b) {
  if (b - a <= 1) return;
  int m = (a+b)/2;
  int cc = (c+1)%d;
  quickselect(c, a, b, m);
  sort(cc,a,m);
  sort(cc,m+1,b);
}

@ 
@s line normal
@<Read...@>= {
  char line[lmax]; /* buffer for reading one line */
  int o; /* offset in the line for reading one token */
  int len; /* length of one token */
  int offset; /* where we write in |buffer| */
  FILE *data = fopen(argv[1],"r");
  if (!data) return 1;
  for (n = offset = 0; fgets(line,lmax,data); ++n) {
    for (d = o = 0;
         sscanf(line+o,"%s%n",buffer+offset,&len) == 1;
         offset += len + 1, o += len)
      points[n][d++]=buffer+offset;
  }
  fclose(data);
}

@ @<Answer...@>=
while (1) {
  int i, o, len;
  char *line = readline("> ");
  if (!line) break;
  for (i = o = 0; i < 2 * d &&
     sscanf(line+o,"%s%n",range[i],&len) == 1; ++i, o+=len);
  if (i != 2 * d) continue;
  rcnt = qcnt = 0;
  struct timeval start; gettimeofday(&start, NULL);
  query(0, 0, n);
  struct timeval stop; gettimeofday(&stop, NULL);
  int delta =
      1e+3 * (stop.tv_sec - start.tv_sec) +
      1e-3 * (stop.tv_usec - start.tv_usec);
  printf("found %d results in %dms with %d calls\n",rcnt,delta,qcnt);
  free(line);
}

@ @<Helper functions@>=
void query(int c, int a, int b) {
  if (b == a) return;
  if (rcnt == 20000) return;
  ++qcnt;
  int m = (a+b)/2;
  int cc = (c+1)%d;
  int i;
  for (i = 0; i < d && strcmp(range[2*i],points[m][i])<=0
                    && strcmp(range[2*i+1],points[m][i])>=0; ++i);
  if (i == d) {
    ++rcnt;
    if (0) {
      for (i = 0; i < d; ++i) printf(" %s", points[m][i]);
      printf("\n");
    }
  }
  if (strcmp(range[2*c],points[m][c])<=0) query(cc,a,m);
  if (strcmp(range[2*c+1],points[m][c])>=0) query(cc,m+1,b);
}

