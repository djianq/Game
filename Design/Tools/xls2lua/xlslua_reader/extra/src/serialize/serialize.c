/* $Id: serialize.c 50164 2011-05-13 03:03:07Z shenglunan@NETEASE.COM $
** 
** lua table->string by AKara
** thread-NOT-safe version -_x
**
** arnan, 2011-05-12:
** add key-value array to sort table by key before serialize
** add lmemory
**
** BUGS:
**  - final string size will be truncated by TBUFSIZE!
**
*/
#include <string.h>
#include "lua.h"
#include "lauxlib.h"

#include "serialize.h"

//--------------------------------------------------------------------
// ʹ�� lmemory �������ڴ���俪���������ڴ���Ƭ
#include "LAllocator.h"
static int lmemory_inited = 0;

//--------------------------------------------------------------------
// �Զ���չ���飬���ڶ� key-value �Խ�������

typedef struct {
	const char* key;
	const char* value;
} sort_entry_t;

typedef struct {
	sort_entry_t* data;
	unsigned int size;
	unsigned int used;
} sort_array_t;

static sort_array_t s_key_value_array;

static void sort_array_init( sort_array_t* parray )
{
	parray->data = 0;
	parray->size = 0;
	parray->used = 0;
}

static void sort_array_free( sort_array_t* parray )
{
	size_t i;
	for(i=0; i<parray->used; ++i) {
		lmemory_free( parray->data[i].key );
		lmemory_free( parray->data[i].value );
	}

	if( parray->data ) {
		lmemory_free( parray->data );
	}
}

static void sort_array_expand( sort_array_t* parray, unsigned int newsize )
{
	unsigned int alloc_size;
	unsigned int alloc_bytes;
	void* newdata;

	if( parray->size >= newsize )
		return;

	alloc_size = (parray->size == 0 ? 1024 : parray->size << 1);
	alloc_bytes = alloc_size * sizeof( sort_entry_t );
	
	newdata = lmemory_malloc(alloc_bytes);
	if(!newdata) {
		fprintf(stderr, "sort_array_expand: malloc failed!\n");
		exit(1);
	}

	if( parray->data ) {
		memcpy(newdata, parray->data, parray->used * sizeof( sort_entry_t ));
		lmemory_free( parray->data );
	}

	parray->data = newdata;
	parray->size = alloc_size;
}

static void sort_array_add( sort_array_t* parray, sort_entry_t* pentry )
{
	sort_array_expand( parray, parray->used + 1 );

	parray->data[ parray->used ] = *pentry;
	parray->used++;
}

static int sort_array_compare( const void* lhs, const void* rhs )
{
	sort_entry_t* lentry = (sort_entry_t*)lhs;
	sort_entry_t* rentry = (sort_entry_t*)rhs;

	return strcmp( lentry->key, rentry->key );
}

static void sort_array_sort( sort_array_t* parray )
{
	qsort( parray->data, parray->used, sizeof(sort_entry_t), sort_array_compare );
}

//--------------------------------------------------------------------

// ��buffer�м�һ���ַ�
void addchar(TinyBuffer * B,char c)
{
  if ((B)->cur < ((B)->buff+TBUFSIZE))
	(*(B)->cur++ = (char)(c));
}

// ��buffer�м�һ���ַ���
void addstring(TinyBuffer * B, const char * s)
{
	while (*s && B->cur < B->buff + TBUFSIZE)
	{
		*B->cur++ = *s++ ;
	}
}

// ���� buffer ��ǰλ�õ���ջ
void buffer_save( TinyBuffer* B )
{
	if(B->savenum >= SAVESTACKSIZE) {
		fprintf(stderr, "buffer_save: stack overflow!\n");
		exit(1);
	}

	B->save[B->savenum++] = B->cur;
}

// �ָ���һ������ĵ�ǰλ�ã������֮����� buffer ���ַ����� output
// ע�� *output ��Ҫ�ֹ����� lmemory_free �ͷ�
void buffer_restore( TinyBuffer* B, char**output )
{
	char* ret;
	char* last = B->save[--B->savenum];
	size_t length;

	if( output ) {
		length = B->cur - last;
		ret = lmemory_malloc(length + 1);
		if(!ret) {
			fprintf(stderr, "sort_array_expand: malloc failed!\n");
			exit(1);
		}
		memcpy(ret, last, length);
		ret[length] = 0;
		*output = ret;
	}
	B->cur = last;
}

// ������
static void addquoted (TinyBuffer *B, const char * s)
{
  addchar(B, '"');
  while (*s) {
    switch (*s) {
      case '"': case '\\': case '\n': {
        addchar(B, '\\');
        addchar(B, *s);
        break;
      }
      case '\r': {
        addstring(B, "\\r");
        break;
      }
      case '\0': {
        addstring(B, "\\000");
        break;
      }
      default: {
        addchar(B, *s);
        break;
      }
    }
    s++;
  }
  addchar(B, '"');
}

// table -> string
void table2string(lua_State *L, int depth, TinyBuffer *B)
{
	int old_depth = depth;
	int i;
	int array_size = 0;
	int k;
	lua_Number n;
	size_t idx;
	int key_type;
	sort_array_t key_value_array;
	sort_entry_t key_value_entry;

	// ջ��������table����
	if (lua_type(L, -1) != LUA_TTABLE)
	{
		luaL_error(L, "must has table type!");
		return;
	}

	// -------��ʼ���л�----------
	addstring(B, "{\n");
	
	// ������ݹ����
	depth++;
	if (depth > MAX_DEPTH)
	{
		luaL_error(L, "serialize too deep!");
		return;
	}	
	
	// һ���Ƚ���Ч�����л��Ż���
	// ���ԭ��Ϊ��t = {1, 2, 3, nil, nil, nil, nil, 8, a=4, b=5}
	// ��ô�����л��� {[1]=1, [2]=2, [3]=3, [8]=8, ["a"]=4, ["b"]=5}�ǲ����ŵ�
	// ���ŵ����л�Ӧ����{1, 2, 3, [8]=8, a=4, b=5}
	// �����ж�key�Ƿ����������Ҫ�����ʧ���ܣ����ԣ�
	// ���ŵ����л�Ӧ����{1, 2, 3, [8]=8, ["a"]=4, ["b"]=5}
	
	// ��ʵ���Զ�array part��ʽ���л��ܼ򵥣�
	// ����ipairs��Ϊ���ɣ������ж� t->node == cast(Node *, dummynode) �������ǲ����ŵģ���Ϊ����nilԪ��̫�ࣩ
	for (k = 1; k < 0xFFFFFFFF; k++)
	{
		lua_rawgeti(L, -1, k);
		if (lua_isnil(L, -1))
		{
			// �������nil
			lua_pop(L, 1);
			// ��¼array part���ȣ�ע��Ҫ - 1
			array_size = k - 1;
			break;
		}
		else
		{
			// ��array part��ʽ���л���
			for (i=0; i < old_depth; i++) addchar(B, '\t');
			addchar(B, '\t');
			
			// ��ʱ-1λ��Ϊvalueֵ
			object2string(L, -1, depth, B);

			addstring(B, ",\n");

			// �����������
			lua_pop(L, 1);
		}
	}

	// ��ʼ�� key-value ����
	sort_array_init( &key_value_array );

	// pushһ��nil������һ��lua_next��key����ʶһ���µ���
	lua_pushnil(L);
	while(lua_next(L, -2) != 0)
	{
		// lua_next�ɹ��� -1��value, -2��key
		
		if (array_size > 0 && lua_type(L, -2) == LUA_TNUMBER)
		{
			// ����key�Ƿ�number? 
			n = luaL_checknumber(L, -2);
			// ������ж������ķ�ʽ�ǳ� ltable.c �е� arrayindex ������
			lua_number2int(k, n);
			// ֻ����(0, array_size]����Ĳſ�������
			if (k > 0 && k <= array_size)
			{
				// ȷ��Ϊ������������
				if (luai_numeq(cast_num(k), n))
				{
					// ��ջ������value������keyΪlua_next����һ�ε���
					lua_pop(L, 1); 
					continue;
				}
			}
		}
		
		key_type = lua_type(L, -2);
		// �ַ������������͵� KEY ��Ӧ�� key-value �������������
		if (   key_type == LUA_TSTRING
			|| key_type == LUA_TNUMBER
			|| key_type == LUA_TTABLE  )
		{
			// ��ȡ key
			buffer_save(B);
			object2string(L, -2, depth, B);
			buffer_restore(B, &key_value_entry.key);

			// ��ȡ value
			buffer_save(B);
			object2string(L, -1, depth, B);
			buffer_restore(B, &key_value_entry.value);

			// �� key-value �Է������������
			sort_array_add( &key_value_array, &key_value_entry );

			// ��ջ������value������keyΪlua_next����һ�ε���
			lua_pop(L, 1);
		}
		else
		{
			// ���������buff��
			for (i=0; i < old_depth; i++) addchar(B, '\t');
			addstring(B, "\t[");
			
			// ���л�key
			object2string(L, -2, depth, B);

			addstring(B, "] = ");

			// ���л�value
			object2string(L, -1, depth, B);

			addstring(B, ",\n");

			// ��ջ������value������keyΪlua_next����һ�ε���
			lua_pop(L, 1);
		}
	}

	// ����
	sort_array_sort( &key_value_array );

	// ��������� key-value ����
	for(idx = 0; idx < key_value_array.used; ++idx) {
		for (i=0; i < old_depth; i++) addchar(B, '\t');
		addstring(B, "\t[");
		addstring(B, key_value_array.data[idx].key);
		addstring(B, "] = ");
		addstring(B, key_value_array.data[idx].value);
		addstring(B, ",\n");
	}

	// ���������buff��
	for (i=0; i < old_depth; i++) addchar(B, '\t');
	addchar(B, '}');

	// �ͷ� key-value ����
	sort_array_free( &key_value_array );
}

// Ϊ�˸��죬ʹ��static����
static char static_number_buff[LUAI_MAXNUMBER2STR];
static char static_string_for_reserved_format[TBUFSIZE];
// obj -> string
void object2string(lua_State *L, int index, int depth, TinyBuffer *B)
{
	int type = lua_type(L, index);
	const char *tmp_string = NULL;
	int tmp_string_copy_len = 0;
	switch (type)
	{
	//������ܹ�ֱ��ʹ��lua_tostring����Ϊ���api���޸�ջ���ݣ�������array��lua_next�����쳣��
	//Ҳ���ܹ�ǿ�а�lua_Numberת��Ϊ%d�����
	case LUA_TNUMBER:
		lua_number2str(static_number_buff, luaL_checknumber(L, index));
		addstring(B, static_number_buff);
		break;
	case LUA_TSTRING:
		tmp_string = luaL_checkstring(L, index);
		if (strncmp(tmp_string, RESERVED_TAG, RESERVED_TAG_LEN) == 0)
		{
			if (strlen(tmp_string) > TBUFSIZE - 1){
				luaL_error(L, "too long string");
				return;
			}
			// ɾ��RESERVED_TAG
			tmp_string_copy_len = strlen(tmp_string) - RESERVED_TAG_LEN;
			strncpy(static_string_for_reserved_format, tmp_string+RESERVED_TAG_LEN, tmp_string_copy_len);
			static_string_for_reserved_format[tmp_string_copy_len] = '\0';
			// ����Ͳ�Ҫquoted��
			addstring(B, static_string_for_reserved_format);
		}
		else
		{
			addquoted(B, tmp_string);
		}
		break;
	case LUA_TBOOLEAN:
		addstring(B, (lua_toboolean(L, index) ? "true" : "false"));
		break;
	case LUA_TNIL:
		addstring(B, "nil");
		break;
	case LUA_TTABLE:
		table2string(L, depth, B);
		break;
	default:
		luaL_error(L, "type error:%d", type);
		break;
	}
}

//-------------------------------------------------------------------
//-- ������"/'���ŵ��ַ����־û�֧��(����־��������Զ����ɺ���ʱ��Ƚ�����)
//--
//-- ���磺
//-- ϣ��
//--    local Str = "function (A, B) return A> B end"
//-- ����ַ�����serializeʱ������ " ���ŵ�д���ļ���
//-- ����ʹ�� 
//--    Str = R(Str)
//-- ִ������һ�д����serialize���Զ�ɾ�� " ���ţ�
//-- ֻд�룺function (A, B) return A > B end
//-- 
//----------------------------------------------------------------------
int get_reserved_tag(lua_State *L)
{
	lua_pushlstring(L, RESERVED_TAG, RESERVED_TAG_LEN);
	return 1;
}


// Ϊ�˸��죬ʹ��static����
static TinyBuffer lb;
int serialize(lua_State *L)
{
	if( !lmemory_inited ) {
		lmemory_inited = 1;
		lmemory_init();
	}

	lb.cur  = lb.buff;
	lb.savenum = 0;
	table2string(L, 0, &lb);	
	lua_pushlstring(L, lb.buff, bufflen(&lb));
	return 1;
}

