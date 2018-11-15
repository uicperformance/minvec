CC := gcc
LD := gcc

ROOT ?= ../..

MAKE := make

CFLAGS += -g -O3 -mavx2 -Wall -Winline 

.PHONY: all clean

BINS = test_vec test_novec test_iterative test_fixed benchmark_vec benchmark_novec benchmark_iterative benchmark_fixed

all: $(BINS)

benchmark_vec: benchmark.c cmin.c
	$(CC) $(CFLAGS) -o $@ $^
benchmark_novec: benchmark.c cmin.c
	$(CC) $(CFLAGS) -fno-tree-vectorize -o $@ $^
benchmark_iterative: benchmark.c iterative.c
	$(CC) $(CFLAGS) -o $@ $^
benchmark_fixed: benchmark.c fixed.c
	$(CC) $(CFLAGS) -DARRAY64 -o $@ $^


test_vec: test.c cmin.c
	$(CC) $(CFLAGS) -o $@ $^
test_novec: test.c cmin.c
	$(CC) $(CFLAGS) -fno-tree-vectorize -o $@ $^
test_iterative: test.c iterative.c
	$(CC) $(CFLAGS) -o $@ $^
test_fixed: test.c fixed.c
	$(CC) $(CFLAGS) -DARRAY64 -o $@ $^


report.pdf: report.tex
	pdflatex report.tex
	pdflatex report.tex

clean:
	rm -f $(BINS) *.o *.so
