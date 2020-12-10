#include <arpa/inet.h>  //inet_addr
#include <defines.h>
#include <stdio.h>
#include <string.h>  //strlen
#include <sys/socket.h>
#include <unistd.h>  //write
#include <condition_variable>
#include <iostream>
#include <mutex>
#include <sstream>
#include <thread>

using namespace std;

condition_variable t_waitcondition;
mutex t_stopmutex;
bool thread_stop = false;

mutex state_lock;
bool remote_connected = false;

void fc_monitor_thread()
{
    bool is_up = false;
    while (1)
    {
        {
            lock_guard<mutex> guard(state_lock);
            is_up = remote_connected;
            remote_connected = false;
        }
        time_t rawtime;
        struct tm *info;
        char buffer[80];

        time(&rawtime);

        info = localtime(&rawtime);

        strftime(buffer, 80, "%H:%M:%S : ", info);
        stringstream ss;
        ss << buffer;
        ss << ((is_up) ? "ON" : "OFF");
        cout << ss.str() << endl;
        {
            std::unique_lock<std::mutex> _lock(t_stopmutex);
            auto now = std::chrono::system_clock::now();
            if (t_waitcondition.wait_until(
                    _lock, now + 30s, []() { return thread_stop == true; }))
            {
                // stop requested
                break;
            }
        }
    }
}

int main(int argc, char *argv[])
{
    int socket_desc, client_sock, c, read_size;
    struct sockaddr_in server, client;
    char client_message[2000];

    // Create socket
    socket_desc = socket(AF_INET, SOCK_STREAM, 0);
    if (socket_desc == -1)
    {
        printf("Could not create socket");
    }
    puts("Socket created");

    // Prepare the sockaddr_in structure
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = INADDR_ANY;
    server.sin_port = htons(LISTENER_PORT);

    // Bind
    if (bind(socket_desc, (struct sockaddr *)&server, sizeof(server)) < 0)
    {
        // print the error message
        perror("bind failed. Error");
        return 1;
    }
    puts("bind done");
    std::thread *fc_monitor = new thread(fc_monitor_thread);

    // Listen
    listen(socket_desc, 3);

    // Accept and incoming connection
    puts("Waiting for incoming connections...");
    c = sizeof(struct sockaddr_in);

    // accept connection from an incoming client
    while ((client_sock = accept(
                socket_desc, (struct sockaddr *)&client, (socklen_t *)&c)))
    {
        puts("Connection accepted");
        char *client_ip = inet_ntoa(client.sin_addr);
        int client_port = ntohs(client.sin_port);
        printf("From %s:%d\n", client_ip, client_port);
        {
            lock_guard<mutex> guard(state_lock);
            remote_connected = true;
        }
    }
    if (client_sock < 0)
    {
        perror("accept failed");
        return 1;
    }
    fc_monitor->join();

    return 0;
}