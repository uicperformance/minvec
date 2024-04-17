#include"min.h"
#include<stdio.h>
#include<stdlib.h>
#include<x86intrin.h>

volatile int scratch=0;
#define MAX 1024*1024

int array[MAX] __attribute__((aligned(64)));

int main(int argc, char** argv) {
	int seed=789;

	for(int i=0;i<MAX;i++,seed+=789) {
		array[i]=seed%MAX+12;
	}

	unsigned dummy = 0;
	long long before, after;

	for(int size=8;size<=MAX;size*=2) {
		before = __rdtscp(&dummy);
		for(int i=0;i<1000;i++) {
			scratch=arraymin(array,size);
		}
		after = __rdtscp(&dummy);
		printf("Arraymin %d took %lld cycles/op %.2f cycles/element.\n",size,(after-before)/1000,(after-before)/(1000.0*size));
	}


	for(int size=8;size<=MAX;size*=2) {
		before = __rdtscp(&dummy);
		for(int i=0;i<1000;i++) {
			scratch=minindex(array,size);
		}
		after = __rdtscp(&dummy);
		printf("Minindex %d took %lld cycles/op %.2f cycles/element.\n",size,(after-before)/1000,(after-before)/(1000.0*size));
	}

}
