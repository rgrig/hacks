CFLAGS=-Wall -W -pedantic -std=c99 -g -O3
LDFLAGS=
#CFLAGS=-std=c99 -g --coverage
#LDFLAGS=--coverage

EXE=sat minmodels zdd square
PDF=$(patsubst %,%.pdf,$(EXE))

all: exe pdf

exe: $(EXE)

pdf: $(PDF)

sat: sat.o

minmodels: minmodels.o

%.pdf: %.tex
	pdftex $* 

clean:
	rm -f *.o *.log *.idx *.scn *.toc
	rm -f $(EXE) $(PDF)
	rm -f *.gcov *.gcno *.gcda gmon.out
