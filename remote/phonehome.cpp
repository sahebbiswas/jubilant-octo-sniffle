
#include <arpa/inet.h>  //inet_addr
#include <defines.h>
#include <stdio.h>       //printf
#include <string.h>      //strlen
#include <sys/socket.h>  //socket
#include <unistd.h>
#include <iostream>
using namespace std;

int main(int argc, char *argv[])
{
    int sock;
    struct sockaddr_in server;
    char message[1000], server_reply[2000];
    if (argc < 2)
    {
        printf("Enter destination IP Address\n");
        return -1;
    }

    // Create socket
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1)
    {
        printf("Could not create socket");
    }
    cout << "Socket created\n";
    cout << "Connecting to " << argv[1] << endl;

    server.sin_addr.s_addr = inet_addr(argv[1]);
    server.sin_family = AF_INET;
    server.sin_port = htons(LISTENER_PORT);

    // Connect to remote server
    if (connect(sock, (struct sockaddr *)&server, sizeof(server)) < 0)
    {
        perror("connect failed. Error");
        return 1;
    }

    puts("Connected\n");

    close(sock);
    return 0;
}