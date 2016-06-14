@* Intro.  Imagine an election system in which the government coalition must
at least half of votes, after discarding votes for parties that do not meet a
minimum threshold.  What is the effect of the threshold on the likelihood that
a random coalition may govern?  This program investigates this effect under a
uniform distribution of voter preferences, using a Monte Carlo simulation.

Each output line lists three numbers `{\tt A B C}', where {\tt A} is the number
of parties that participate, {\tt B} is the threshold, and {\tt C} is the
fraction of coalitions that may govern.

@c
#include <stdio.h>
#include <stdlib.h>
int main() {
  srand(0);
  for (int parties = 1; parties <= max_parties; ++parties) {
    for (int threshold = 0; threshold <= 100; ++threshold) {
      int none_in_parliment = 0;
      int tries_left = tries;
      double fraction = 0.0;
      while (tries_left--) @<Add to |fraction|@>@;
      fraction /= (tries - none_in_parliment);
      printf("%2d %3d %.02f %.02f\n",parties,threshold,fraction,
        1.0*none_in_parliment/tries);
    }
  }
  return 0;
}

@
@d max_parties 10
@d tries 10000

@<Add to |fraction|@>= {
  int i, j, k;
  int votes[max_parties];
  int min_votes; // minimum number of votes to not be ignored
  int good_votes; // votes that count
  int coalition_votes;
  int ok_coalitions;
  for (i = 0; i < parties; ++i) votes[i] = 0;
  for (i = 0; i < population; ++i) ++votes[rand() % parties];
  min_votes = (threshold * population + 99) / 100;
  good_votes = 0;
  for (i = j = 0; j < parties; ++j) {
    if (votes[j] >= min_votes) {
      votes[i++] = votes[j];
      good_votes += votes[j];
    }
  }
  if (i == 0) ++none_in_parliment;
  else {
    ok_coalitions = 0;
    for (j = 1; j < (1 << i); ++j) {
      coalition_votes = 0;
      for (k = 0; k < parties; ++k) if ((j>>k)&1) coalition_votes += votes[k];
      if (coalition_votes >= good_votes / 2) ++ok_coalitions;
      if (0) printf("coalition_votes %d good_votes %d\n", coalition_votes,good_votes);
    }
    fraction += 1.0 * ok_coalitions / ((1 << i) - 1);
  }
}

@
@d population 100

@* TODO.


