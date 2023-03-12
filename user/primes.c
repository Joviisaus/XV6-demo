#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

void main(int args,char *argv[])
{
    int p[2];

    if(pipe(p)<0)
    {
        fprintf(2,"error:unable to build pipes \n");
    }
    int num = 35
    int pid = fork();

    while (1)
    {
        if(pid > 0)
        {
            write(p[1],num - 1);
            wait((int*)0);
            printf("prime %d \n",num);
            break;
        }else if (pid == 0)
        {
            read(p[0],num);
            if(num >= 2)
            {
                num --;
                pid = fork();
            }
            else{
                break;
            }

        }
        else{
           fprintf(2,"error:fork failed \n"); 
        }
    }
    exit(0);
}