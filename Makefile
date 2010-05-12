CC=gcc
CWEAVE=cweave
CTANGLE=ctangle
TEX=tex
CFLAGS=-Wall -W -pedantic -std=c99 -g
LDFLAGS=

EXE=sat minmodels
PDF=$(patsubst %,%.pdf,$(EXE))

all :exe pdf

exe: $(EXE)

pdf: $(PDF)

sat: sat.o

minmodels: minmodels.o

%.pdf: %.tex
	pdftex $* 

clean:
	rm -f *.o *.log *.idx *.scn *.toc
	rm -f $(EXE) $(PDF)
