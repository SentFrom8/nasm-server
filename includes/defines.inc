%define MAX_METHOD_LEN 10
%define MAX_PATH_LEN 1024
%define MAX_HTTPV_LEN 10

%define MAX_NUM_LEN 20

%define PATH_MAX 4096

%define LISTEN_BACKLOG 4096

; Client defines
%define MAX_CLIENTS 4096
%define MAX_REQUEST_LEN 4096                    ; must be a power of 2
%define MAX_RESPONSE_HEADERS 128                ; must be a power of 2

; Client flags
%define READY_FOR_RES 1
%define SENDING_HEADERS 2
%define SENDING_FILE 4
%define REQUESTING_INDEX 8
%define DATA_SENT 16
%define SOCKET_CLOSED 128

; Errors
%define RESOURCE_NOT_FOUND 65536
