#include"min.h"
#include<stdlib.h>
#include<stdio.h>

int main(int argc, char** argv) {
	int seed=789;
	int array[1024];
	for(int i=0;i<1024;i++,seed+=789) {
		array[i]=seed%1024+12;
	}

#ifdef ARRAY256
	array[50]=10;
	if(arraymin256(array)!=10) {
		fprintf(stderr,"FAIL: Arraymin64 expected 10\n");
		exit(1);
	}

	array[38]=9;
	if(arraymin256(array)!=9) {
		fprintf(stderr,"FAIL: Arraymin64 expected 9\n");
		exit(1);
	}

	array[17]=-1;
	if(arraymin256(array)!=-1) {
		fprintf(stderr,"FAIL: Arraymin64 expected -1\n");
		exit(1);
	}
#else
	if(arraymin(array,1024)!=12) {
		fprintf(stderr,"FAIL: Arraymin expected 12\n");
		exit(1);
	}

	array[56]=2;
	if(arraymin(array,1024)!=2) {
		fprintf(stderr,"FAIL: Arraymin expected 2\n");
		exit(1);
	}
	
	array[908]=-5;
	if(arraymin(array,1024)!=-5) {
		fprintf(stderr,"FAIL: Arraymin expected -5\n");
		exit(1);
	}


	if(minindex(array,1024)!=908) {
		fprintf(stderr,"FAIL: Minindex expected 908\n");
		exit(1);
	}

	array[77]=-6;
	if(minindex(array,1024)!=77) {
		fprintf(stderr,"FAIL: Minindex expected 77\n");
		exit(1);
	}

	array[4]=-6;
	if(minindex(array,1024)!=4) {
		fprintf(stderr,"FAIL: Minindex expected 4\n");
		exit(1);
	} 
	
#endif
}
