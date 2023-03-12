#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int prime(int num)
{
    int i;
    for(i = 3;i<num;i++)
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
            exit(1);
        }
        else if (pid == 0)
        {
            while(1)
            {
                if(read(p[0],&num,sizeof(num))==0)
                {
                    num = -1;
                    break;
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
            break;
        }
        if (num < 0) break;
    }
    exit(0);
    
}