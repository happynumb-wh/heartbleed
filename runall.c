#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <assert.h>

void _halt(int code)
{
    __asm__ volatile ("mv a0, %0\n\r.word 0x0005006b"::"r"(code));

    // should not reach here during simulation
    printf("Exit with code = %d\n", code);

    // should not reach here on FPGA
    while(1);
}

int main(char * argc, char * argv[], char * envp[])
{
    // char * argv_ifconfig[] = 
    // {
    //     "/bin/ifconfig",
    //     "lo",
    //     "127.0.0.1",
    //     NULL
    // };

    // // excute ifconfig
    // pid_t ifconfig_pid = fork();
    // int ifconfig_status;

    // assert(ifconfig_pid != -1);

    // if (ifconfig_pid)
    // {
    //     printf("[Log]: Wait ifconfig finished\n");

    //     wait(&ifconfig_status);
    // } else 
    // {
    //     printf("[Log]: execve ifconfig\n");

    //     int execve_ifconfig = execve(argv_ifconfig[0], argv_ifconfig, envp);

    //     // should not print
    //     printf("[ERROR] ifconfig failed\n");

    //     return 0;
    // }

    // char * argv_route[] = 
    // {
    //     "/bin/route",
    //     "add",
    //     "-net",
    //     "127.0.0.0",
    //     "netmask",
    //     "255.255.255.0",
    //     "lo",
    //     NULL
    // };
    
    // // excute route 
    // pid_t route_pid = fork();
    // int route_status;

    // assert(route_pid != -1);

    // if (route_pid)
    // {
    //     printf("[Log]: Wait route finished\n");

    //     wait(&route_status);
    // } else 
    // {
    //     printf("[Log]: execve route\n");

    //     int execve_route = execve(argv_route[0], argv_route, envp);

    //     // should not print
    //     printf("[ERROR] route failed\n");

    //     return 0;
    // }

    char * argv_heartbleed[] = {
        "/root/heartbleed",
        "9878",
        "/root/cert.crt",
        "/root/rsa_private.key",
        "-dasics",
        NULL
    };


    // excute  
    pid_t heartbleed_pid = fork();
    int heartbleed_status;

    assert(heartbleed_pid != -1);

    if (heartbleed_pid)
    {
        printf("[Log]: Wait heartbleed server initialization\n");
        sleep(20);
    } else 
    {
        printf("[Log]: execve heartbleed\n");

        int execve_heartbleed = execve(argv_heartbleed[0], argv_heartbleed, envp);

        // should not print
        printf("[ERROR] heartbleed failed\n");

        return 0;
    }

    // char * argv_ping[] = {
    //     "/bin/ping",
    //     "127.0.0.1",
    //     "-c",
    //     "8",
    //     NULL
    // };
    
    // // excute ping 
    // pid_t ping_pid = fork();
    // int ping_status;

    // assert(ping_pid != -1);

    // if (ping_pid)
    // {
    //     printf("[Log]: Wait ping finished\n");

    //     wait(&ping_status);
    // } else 
    // {
    //     printf("[Log]: execve ping\n");

    //     int execve_ping = execve(argv_ping[0], argv_ping, envp);

    //     // should not print
    //     printf("[ERROR] ping failed\n");

    //     return 0;
    // }

    char * argv_attack[] = {
        "/root/attack",
        "127.0.0.1",
        "-p",
        "9878",
        NULL
    };
    
    // excute attack 
    pid_t attack_pid = fork();
    int attack_status;

    assert(attack_pid != -1);

    if (attack_pid)
    {
        printf("[Log]: Wait attack finished\n");

        wait(&attack_status);
    } else 
    {
        printf("[Log]: execve attack\n");

        int execve_attack = execve(argv_attack[0], argv_attack, envp);

        // should not print
        printf("[ERROR] attack failed\n");

        return 0;
    }


    _halt(0);
}