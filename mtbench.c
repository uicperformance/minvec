#include"min.h"
#include<stdio.h>
#include<stdlib.h>
#include<x86intrin.h>
#include<pthread.h>
#include<unistd.h>

#define THREADS 16
#define MAX (1024*1024)
#define HZ 3000000000
#define DURATION HZ*1
int array[MAX];
pthread_mutex_t lock;
pthread_barrier_t barrier;
int arrsize;

void* mutator_thread(void* voidrate) {
    pthread_barrier_wait(&barrier);
    long rate=(long)voidrate;
    long interval=HZ/rate; // figuring 3 GHz
    unsigned dummy;    
    long start_time=__rdtscp(&dummy);
    long deadline=start_time+interval;
    long after=0;
    while(deadline<(start_time+DURATION)) { // 1 second experiment        
        pthread_mutex_lock(&lock);
        array[after%arrsize]--;
        array[(after+1)%arrsize]++;
        pthread_mutex_unlock(&lock); 
        after=__rdtscp(&dummy);
        if(after>deadline) {
            printf("Mutator missed deadline for rate %ld.\n",rate);
            return (void*)-1;
        }
        else { // wait until next time     
            do{ 
                __pause();
                after=__rdtscp(&dummy);
            } while(after<deadline);
        }
        deadline+=interval;    
    }
    return (void*)0;
}

void* scanner_thread(void* void_tid) {
//    long tid = (long)void_tid;
    pthread_mutex_lock(&lock);
    long index=minindex(array,arrsize);
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
            pthread_join(thread[t],(void**)&index);
            if(array[minindex] > array[index]) {
                minindex=index;
            }
        }
//        scanner_thread(0);
        scans++;
    }
    return 0;
}
int main(int argc, char** argv) {
	int seed=789;
    pthread_mutex_init(&lock,0);
    #ifndef NOMUT
    pthread_barrier_init(&barrier,0,3);
    #else
    pthread_barrier_init(&barrier,0,2);
    #endif

	for(int i=0;i<MAX;i++,seed+=789) {
		array[i]=seed%MAX+12;
	}
    array[77]=-2;
	for(long size=1024;size<=MAX;size*=2) {
        arrsize=size;
		for(long i=100;i<100000000;i*=2) {
            #ifndef NOMUT
            pthread_t mutator;
            #endif


            pthread_t scanner;

            #ifndef NOMUT
            pthread_create(&mutator,0,mutator_thread,(void*)i);
            #endif

            pthread_create(&scanner,0,scanner_main,(void*)0);
            pthread_barrier_wait(&barrier);
            void* mutator_return=(void*)0;

            #ifndef NOMUT
            pthread_join(mutator,&mutator_return);
            #else 
            sleep(2);
            #endif

            stop=1;           
            pthread_join(scanner,0);

            if(mutator_return != 0) {
                break;
            }
            printf("size %ld rate %ld scans %d score %.1lf\n",size,i,scans,(double)size*(double)i*(double)scans/1000000.0);
            #ifdef NOMUT
            break;
            #endif
		}
	}
}
