#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


void main(int argc,char* argv[])
{
    char* msg;

    if(argc < 2){
    fprintf(2, "Usage: pingpong files...\n");
    exit(1);}

    int p[2];
    int pid = fork();

    if(pipe(p)<0){
        fprintf(2,"error:unable to build pipes \n");
    }

    if(pid > 0)
    {
        write(p[1],"pong",5);
        read(p[0],msg,15);
        printf("%d:received %s \n",getpid(),msg);
        exit(1)
    }
    else if (pid == 0)
    {
        write(p[1],"ping",5);
        read(p[0],msg,15);
        printf("%d:received %s \n",getpid(),msg);
        exit(1);
    }
    else{
        fprintf(2,"error:fork fialed\n");
        exit(0);
    }
    exit(0);

}