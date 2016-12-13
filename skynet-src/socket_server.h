#ifndef skynet_socket_server_h
#define skynet_socket_server_h

#include <stdint.h>

// socket_server_poll返回的socket消息类型

#define SOCKET_DATA 0	// data 到来
#define SOCKET_CLOSE 1	// close conn
#define SOCKET_OPEN 2	// conn ok
#define SOCKET_ACCEPT 3	// 被动连接建立 (Accept返回了连接的fd 但是未加入epoll来管理)
#define SOCKET_ERROR 4	// error
#define SOCKET_EXIT 5	// exit
#define SOCKET_UDP 6

struct socket_server;

// socket_server对应的msg
struct socket_message 
{
	int id;					// 应用层的socket fd
	uintptr_t opaque;		// 在skynet中对应一个actor实体的handler
	int ud;	// for accept, ud is new connection id ; for data, ud is size of data 	对于accept连接来说是新连接的fd 对于数据到来是数据的大小
	char * data;
};

struct socket_server *socket_server_create();
void socket_server_release(struct socket_server *);
int socket_server_poll(struct socket_server *, struct socket_message *result, int *more);

void socket_server_exit(struct socket_server *);
void socket_server_close(struct socket_server *, uintptr_t opaque, int id);
void socket_server_shutdown(struct socket_server *, uintptr_t opaque, int id);
void socket_server_start(struct socket_server *, uintptr_t opaque, int id);

// return -1 when error
int64_t socket_server_send(struct socket_server *, int id, const void *buffer, int sz);
void socket_server_send_lowpriority(struct socket_server *, int id, const void *buffer, int sz);

// ctrl command below returns id
int socket_server_listen(struct socket_server *, uintptr_t opaque, const char *addr, int port, int backlog);
int socket_server_connect(struct socket_server *, uintptr_t opaque, const char *addr, int port);
int socket_server_bind(struct socket_server *, uintptr_t opaque, int fd);

// for tcp
void socket_server_nodelay(struct socket_server *, int id);

struct socket_udp_address;

// create an udp socket handle, attach opaque with it . udp socket don't need call socket_server_start to recv message
// if port != 0, bind the socket . if addr == NULL, bind ipv4 0.0.0.0 . If you want to use ipv6, addr can be "::" and port 0.
int socket_server_udp(struct socket_server *, uintptr_t opaque, const char *addr, int port);
// set default dest address, return 0 when success
int socket_server_udp_connect(struct socket_server *, int id, const char *addr, int port);
// If the socket_udp_address is NULL, use last call socket_server_udp_connect address instead
// You can also use socket_server_send 
int64_t socket_server_udp_send(struct socket_server *, int id, const struct socket_udp_address *, const void *buffer, int sz);
// extract the address of the message, struct socket_message * should be SOCKET_UDP
const struct socket_udp_address *socket_server_udp_address(struct socket_server *, struct socket_message *, int *addrsz);

struct socket_object_interface 
{
	void *(*buffer)(void *);
	int (*size)(void *);
	void (*free)(void *);
};

// if you send package sz == -1, use soi.
void socket_server_userobject(struct socket_server *, struct socket_object_interface *soi);

#endif