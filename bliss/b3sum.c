/*** Lua wrapper for the C blake3 library.
 * @module bliss.b3sum
 * @copyright 2023 phoebos
 * @usage
 * local data = "some text"
 * local ctx = bliss.b3sum.init()
 * bliss.b3sum.update(ctx, data)
 * local hash = bliss.b3sum.finalize(ctx)
 */
#include <blake3.h>
#include <errno.h>
#include <lauxlib.h>
#include <lua.h>
#include <stdlib.h>
#include <string.h>

/***
 * Initialise the hasher context.
 * @function init
 * @treturn ctx blake3 hasher context userdata
 */
int
l_init(lua_State *L) {
    blake3_hasher *ctx = lua_newuserdata(L, sizeof(blake3_hasher));
    blake3_hasher_init(ctx);
    return 1;
}

/***
 * Add string input to the hasher
 * @function update
 * @tparam ctx ctx hasher context
 * @tparam string s data to hash
 */
int
l_update(lua_State *L) {
    blake3_hasher *ctx = lua_touserdata(L, 1);
    luaL_argcheck(L, ctx != NULL, 1, "hasher context expected");

    size_t n;
    const char *s = luaL_checklstring(L, 2, &n);
    blake3_hasher_update(ctx, s, n);
    return 0;
}

/***
 * Finalize the hasher
 * @function finalize
 * @tparam ctx ctx hasher context
 * @tparam[opt=32] int n length of output string
 * @treturn string hex-encoded hash
 */
int
l_finalize(lua_State *L) {
    blake3_hasher *ctx = lua_touserdata(L, 1);
    luaL_argcheck(L, ctx != NULL, 1, "hasher context expected");

    /* default size is 32 if no second argument */
    int n = luaL_optinteger(L, 2, 32);
    luaL_Buffer b;
    luaL_buffinit(L, &b);

    unsigned char *out = malloc(n);
    if (out == NULL)
        return luaL_error(L, "malloc failed: %s", strerror(errno));

    blake3_hasher_finalize(ctx, out, n);

    /* format raw data to a hex string */
    unsigned char *hexes = (unsigned char *)"0123456789abcdef";
    for (int i = 0; i < n; i++) {
        unsigned char high = (out[i] & 0xf0) >> 0x04;
        unsigned char low  = (out[i] & 0x0f);
        luaL_addchar(&b, hexes[high]);
        luaL_addchar(&b, hexes[low]);
    }
    free(out);

    luaL_pushresult(&b);

    return 1;
}

const struct luaL_Reg fns[] = {
    {"init", l_init},
    {"update", l_update},
    {"finalize", l_finalize},
    {NULL, NULL},
};

int
luaopen_bliss_b3sum(lua_State *L) {
#if LUA_VERSION_NUM > 501
    luaL_newlib(L, fns);
#else
	luaL_openlib(L, "bliss.b3sum", fns, 0);
#endif
    return 1;
}
