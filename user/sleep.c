#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

char buf[512];

int main(int argc,char *argv[]){
    if(argc != 2){
        fprintf(2,"Usage: sleep ticks...\n");
    }
    int clock = atoi(argv[2]);
    sleep(clock);
}