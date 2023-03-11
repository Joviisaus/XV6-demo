#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

char buf[512];

void main(int argc,char *argv[]){
    if(argc != 2){
        fprintf(2,"Usage: sleep ticks...\n");
	exit(1);
    }
    int clock = atoi(argv[1]);
    sleep(clock);
    exit(0);
}