CFLAGS=-Wall -W -pedantic -std=c99 -g -O3
LDLIBS=-lreadline
#CFLAGS=-std=c99 -g -pg --coverage
#LDFLAGS=--coverage

EXE=kd minmodels sat square zdd ocid pos trieoops
PDF=$(patsubst %,%.pdf,$(EXE))

all: exe pdf

exe: $(EXE)

pdf: $(PDF)

%.pdf: %.tex
	pdftex $*

clean:
	rm -f *.o *.log *.idx *.scn *.toc
	rm -f $(EXE) $(PDF)
	rm -f *.gcov *.gcno *.gcda gmon.out
