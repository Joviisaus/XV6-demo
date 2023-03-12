#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int prime(int num)
{
    int i;
    if(num == 2) return 1;
    if(num == 3) return 1;
    for(i = 2;i<num;i++)
    {
        if(num %i == 0) break;
    }
    if(i == num) return(1);
    return(0);
}

void main(int args, char* argv[])
{
    int p[2];
    int num;
    int pid;

    if(pipe(p)<0)
    {
        fprintf(2,"error:unable to build pipes \n");
    }

    for(int i = 2;i <= 35;i ++)
    {
        write(p[1],&i,sizeof(i));
    }

    pid = fork();

    while (1)
    {
        if(pid > 0)
        {
            wait((int*)0);
            exit(0);
        }
        else if (pid == 0)
        {
            while(1)
            {
                read(p[0],&num,sizeof(num));
                if(num == 35)
                {
                   exit(0);
                }
                if(prime(num)==1)
                {
                    fprintf(1,"prime %d \n",num);
                    pid = fork();
                    break;
                }
            }


        }
        else{
            fprintf(2,"error:fork failed \n");
            exit(1);
        }
    }
    exit(0);

}