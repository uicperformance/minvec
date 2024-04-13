#include"min.h"
#include<stdio.h>
#include<stdlib.h>
//#include<x86intrin.h>
#include<pthread.h>

#define THREADS 16
#define MAX 1024*1024
int array[MAX];
pthread_mutex_t lock;
pthread_barrier_t barrier;
int arrsize;

void* mutator_thread(void* voidrate) {
    pthread_barrier_wait(&barrier);
    long rate=(long)voidrate;
}

void* scanner_thread(void* void_tid) {
    long tid = (long)void_tid;
    pthread_mutex_lock(&lock);
    int index=minindex(array,arrsize);
    pthread_mutex_unlock(&lock);
    return (void*)index;
}

pthread_mutex_t lock;
volatile int stop;
int scans;
void* scanner_main(void* unused) {
    pthread_barrier_wait(&barrier);
    stop=0;
    scans=0;
    while(!stop) {
        pthread_t thread[THREADS];
        for(long t=0;t<16;t++) {
            pthread_create(&thread[t],0,scanner_thread,(void*)t);
        }
        int minindex = 0;            
        for(long t=0;t<16;t++) {
            long index;                
            pthread_join(thread[t],&index);
            if(array[minindex] > array[index]) {
                minindex=index;
            }
        }
        scans++;
    }
}
int main(int argc, char** argv) {
	int seed=789;
    pthread_mutex_init(&lock,0);
    pthread_barrier_init(&barrier,0,3);
	for(int i=0;i<MAX;i++,seed+=789) {
		array[i]=seed%MAX+12;
	}
    array[77]=-2;
	unsigned scratch = 0;
	for(int size=1024;size<=MAX;size*=2) {
        arrsize=size;
		for(int i=0;i<1000;i+=10) {
            pthread_t mutator, scanner;
            pthread_create(&mutator,0,mutator_thread,(void*)i);
            pthread_create(&scanner,0,scanner_main,(void*)0);
            pthread_barrier_wait(&barrier);
            pthread_join(mutator,0);
            stop=1;            
            pthread_join(scanner,0);
            printf("size %d rate %d scans %d score %.1lf\n",size,i,scans,size*i*scans/1000000.0);
		}
	}
}
