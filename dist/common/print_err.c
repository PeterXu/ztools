#include <stdlib.h>
#include <stdio.h>
#include <string.h>

void print_err(int err)
{
    char * str = strerror(err);
    printf("[err] %d - %s\n", err, str);
}

int main(int argc, char *argv[])
{
    if (argc != 2) {
        printf("usage: %s err\n", argv[0]);
        return -1;
    }

    int err = atoi(argv[1]);
    if (err >=0 && err <= 255) {
        print_err(err);
    } else if (err == -1) {
        for (int n=0; n <= 110; n++)
        {
            print_err(n);
        }
    } else {
        printf("invalid err - %d\n", err);
    }

    return 0;
}
