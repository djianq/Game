#ifndef serialize_h
#define serialize_h

//16M
#define TBUFSIZE 0x1600000 

#define SAVESTACKSIZE 256

#define MAX_DEPTH 20

#define RESERVED_TAG "@RESERVED"
#define RESERVED_TAG_LEN 9

typedef struct TinyBuffer
{
	char * cur;
	char buff[TBUFSIZE];

	unsigned int savenum;
	char* save[SAVESTACKSIZE];
} TinyBuffer;

#define bufflen(B) ((B)->cur - (B)->buff)

#define luai_numeq(a,b)		((a)==(b))

#ifndef cast
#define cast(t, exp)	((t)(exp))
#endif
#define cast_num(i)	cast(lua_Number, (i))

void object2string(lua_State *L, int index, int depth, TinyBuffer *B);
int get_reserved_tag(lua_State *L);
int serialize (lua_State *L);

#endif

