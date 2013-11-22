#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[])
{
    if (argc != 2) {
        printf("usage: %s errno\n", argv[0]);
        return -1;
    }

    int errno = atoi(argv[1]);
    if (errno >=0 && errno <= 255) {
        char * str = strerror(errno);
        printf("[errno] %d - %s\n", errno, str);
    }
    else
        printf("invalid errno - %d\n", errno);

    return 0;
}
