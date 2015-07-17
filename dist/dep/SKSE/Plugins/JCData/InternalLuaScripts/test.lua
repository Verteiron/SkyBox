
local ffi = require("ffi")


ffi.cdef [[
  typedef void * vod_ptr;
  typedef struct _Form {uint32_t id;} Form;

  typedef struct _Form * FormPtr;
  
  typedef struct _CString { const char *str; } CString;
  
  CString CString_new();
  CString* CString_new2(const char *);
  
  void acceptVoid(void *v);
]]

local lib = ffi.load [[I:\Games\Elder Scrolls Skyrim\src\Debug\ffi_test.dll]]



assert(ffi.typeof('Form') == ffi.typeof('Form'))
assert(ffi.typeof('uint32_t') ~= ffi.typeof('Form'))

local FormPtr = ffi.typeof('FormPtr')

local function expectEq(a, b)
  if a ~= b then print('mistake: '..a..'~='..b) end
end

do
  local CArray = ffi.metatype('struct { void* ___id; }', {
      __index = function(t,k) return nil end
    })
  
  local vval = ffi.cast('void*', 0xfff);
  
  local a = CArray()
  a.___id = vval
  expectEq(a.___id, vval)
end

do
  local CArrayOld = ffi.typeof('struct { void* ___id; }')
  local CArray = ffi.metatype(CArrayOld, {
      __index = function(t,k)
        return t.___id
      end,
      __newindex = function(t,k,v)
        print(t.___id, t, k, v)
      end
    })
  
  local vval = ffi.cast('void*', 0xfff);
  
  local a = CArray()
  a.___id = vval
  expectEq(a.___id, vval)
  
  a.b = 10
end


do
  local CStringO = ffi.typeof('CString')
  local CString_mt = { __gc = function(_) print('GC works on CString ' .. ffi.string(_.str)) end }
  local CString = ffi.metatype(CStringO, CString_mt)
  -- ffi.metatype does not creates new type!!!
  assert(CStringO == CString)
  
  local s0 = CString('456');
  
  local str = lib.CString_new()
  assert(ffi.typeof(str) == CString)
  
  
  -- getmetatable does not work on cdata - returns 'ffi' string
  --assert(getmetatable(s0) == CString_mt)
end
collectgarbage('collect')
collectgarbage('collect')

do
  local CString = ffi.typeof('CString')
  local f = FormPtr()
  local s0 = CString('111');
  -- Form* != void*
  --assert(ffi.istype('void*', f))
  lib.acceptVoid(f)
  lib.acceptVoid(s0)
end


  
print('FIN')
