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
// 使用 lmemory 来降低内存分配开销、减少内存碎片
#include "LAllocator.h"
static int lmemory_inited = 0;

//--------------------------------------------------------------------
// 自动扩展数组，用于对 key-value 对进行排序

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

// 往buffer中加一个字符
void addchar(TinyBuffer * B,char c)
{
  if ((B)->cur < ((B)->buff+TBUFSIZE))
	(*(B)->cur++ = (char)(c));
}

// 往buffer中加一个字符串
void addstring(TinyBuffer * B, const char * s)
{
	while (*s && B->cur < B->buff + TBUFSIZE)
	{
		*B->cur++ = *s++ ;
	}
}

// 保存 buffer 当前位置到堆栈
void buffer_save( TinyBuffer* B )
{
	if(B->savenum >= SAVESTACKSIZE) {
		fprintf(stderr, "buffer_save: stack overflow!\n");
		exit(1);
	}

	B->save[B->savenum++] = B->cur;
}

// 恢复上一个保存的当前位置，并输出之后放入 buffer 的字符串到 output
// 注意 *output 需要手工调用 lmemory_free 释放
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

// 加引用
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

	// 栈顶必须是table类型
	if (lua_type(L, -1) != LUA_TTABLE)
	{
		luaL_error(L, "must has table type!");
		return;
	}

	// -------开始序列化----------
	addstring(B, "{\n");
	
	// 检测最大递归深度
	depth++;
	if (depth > MAX_DEPTH)
	{
		luaL_error(L, "serialize too deep!");
		return;
	}	
	
	// 一个比较有效的序列化优化：
	// 如果原表为：t = {1, 2, 3, nil, nil, nil, nil, 8, a=4, b=5}
	// 那么，序列化成 {[1]=1, [2]=2, [3]=3, [8]=8, ["a"]=4, ["b"]=5}是不够优的
	// 最优的序列化应该是{1, 2, 3, [8]=8, a=4, b=5}
	// 但是判断key是否满足变量名要求会损失性能，所以，
	// 次优的序列化应该是{1, 2, 3, [8]=8, ["a"]=4, ["b"]=5}
	
	// 而实现自动array part形式序列化很简单，
	// 仿照ipairs行为即可（仅仅判断 t->node == cast(Node *, dummynode) 的做法是不够优的，因为可能nil元素太多）
	for (k = 1; k < 0xFFFFFFFF; k++)
	{
		lua_rawgeti(L, -1, k);
		if (lua_isnil(L, -1))
		{
			// 弹出这个nil
			lua_pop(L, 1);
			// 记录array part长度；注意要 - 1
			array_size = k - 1;
			break;
		}
		else
		{
			// 用array part形式序列化它
			for (i=0; i < old_depth; i++) addchar(B, '\t');
			addchar(B, '\t');
			
			// 此时-1位置为value值
			object2string(L, -1, depth, B);

			addstring(B, ",\n");

			// 弹出这个对象
			lua_pop(L, 1);
		}
	}

	// 初始化 key-value 数组
	sort_array_init( &key_value_array );

	// push一个nil当作第一次lua_next的key，标识一个新迭代
	lua_pushnil(L);
	while(lua_next(L, -2) != 0)
	{
		// lua_next成功后： -1是value, -2是key
		
		if (array_size > 0 && lua_type(L, -2) == LUA_TNUMBER)
		{
			// 看看key是否number? 
			n = luaL_checknumber(L, -2);
			// 下面的判断整数的方式是抄 ltable.c 中的 arrayindex 方法的
			lua_number2int(k, n);
			// 只有在(0, array_size]区间的才可能跳过
			if (k > 0 && k <= array_size)
			{
				// 确定为整数才能跳过
				if (luai_numeq(cast_num(k), n))
				{
					// 从栈顶弹出value，保持key为lua_next做下一次迭代
					lua_pop(L, 1); 
					continue;
				}
			}
		}
		
		key_type = lua_type(L, -2);
		// 字符串和数字类型的 KEY 对应的 key-value 放入待排序数组
		if (   key_type == LUA_TSTRING
			|| key_type == LUA_TNUMBER
			|| key_type == LUA_TTABLE  )
		{
			// 获取 key
			buffer_save(B);
			object2string(L, -2, depth, B);
			buffer_restore(B, &key_value_entry.key);

			// 获取 value
			buffer_save(B);
			object2string(L, -1, depth, B);
			buffer_restore(B, &key_value_entry.value);

			// 将 key-value 对放入待排序数组
			sort_array_add( &key_value_array, &key_value_entry );

			// 从栈顶弹出value，保持key为lua_next做下一次迭代
			lua_pop(L, 1);
		}
		else
		{
			// 算出缩进到buff中
			for (i=0; i < old_depth; i++) addchar(B, '\t');
			addstring(B, "\t[");
			
			// 序列化key
			object2string(L, -2, depth, B);

			addstring(B, "] = ");

			// 序列化value
			object2string(L, -1, depth, B);

			addstring(B, ",\n");

			// 从栈顶弹出value，保持key为lua_next做下一次迭代
			lua_pop(L, 1);
		}
	}

	// 排序
	sort_array_sort( &key_value_array );

	// 输出排序后的 key-value 数组
	for(idx = 0; idx < key_value_array.used; ++idx) {
		for (i=0; i < old_depth; i++) addchar(B, '\t');
		addstring(B, "\t[");
		addstring(B, key_value_array.data[idx].key);
		addstring(B, "] = ");
		addstring(B, key_value_array.data[idx].value);
		addstring(B, ",\n");
	}

	// 算出缩进到buff中
	for (i=0; i < old_depth; i++) addchar(B, '\t');
	addchar(B, '}');

	// 释放 key-value 数组
	sort_array_free( &key_value_array );
}

// 为了更快，使用static变量
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
	//这儿不能够直接使用lua_tostring，因为这个api会修改栈内容，将导致array的lua_next访问异常。
	//也不能够强行把lua_Number转换为%d输出。
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
			// 删除RESERVED_TAG
			tmp_string_copy_len = strlen(tmp_string) - RESERVED_TAG_LEN;
			strncpy(static_string_for_reserved_format, tmp_string+RESERVED_TAG_LEN, tmp_string_copy_len);
			static_string_for_reserved_format[tmp_string_copy_len] = '\0';
			// 这个就不要quoted啦
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
//-- 不包含"/'符号的字符串持久化支持(这个持久特性在自动生成函数时候比较有用)
//--
//-- 比如：
//-- 希望
//--    local Str = "function (A, B) return A> B end"
//-- 这个字符串在serialize时不包含 " 符号地写入文件，
//-- 可以使用 
//--    Str = R(Str)
//-- 执行上面一行代码后，serialize将自动删除 " 符号，
//-- 只写入：function (A, B) return A > B end
//-- 
//----------------------------------------------------------------------
int get_reserved_tag(lua_State *L)
{
	lua_pushlstring(L, RESERVED_TAG, RESERVED_TAG_LEN);
	return 1;
}


// 为了更快，使用static变量
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

