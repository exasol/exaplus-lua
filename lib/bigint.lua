local bigint = {}

local BASE = 10000000 -- 1e7

local function trim(a)
  while #a > 0 and a[#a] == 0 do
    a[#a] = nil
  end
  return a
end

local function clone(a)
  local r = {}
  for i=1,#a do r[i]=a[i] end
  return r
end

function bigint.zero()
  return {}
end

function bigint.one()
  return {1}
end

function bigint.is_zero(a)
  return #a == 0
end

function bigint.is_odd(a)
  return (#a > 0) and (a[1] % 2 == 1)
end

function bigint.cmp(a, b)
  if #a ~= #b then
    return (#a < #b) and -1 or 1
  end
  for i = #a, 1, -1 do
    if a[i] ~= b[i] then
      return (a[i] < b[i]) and -1 or 1
    end
  end
  return 0
end

function bigint.add(a, b)
  local r = {}
  local carry = 0
  local n = (#a > #b) and #a or #b
  for i=1,n do
    local s = (a[i] or 0) + (b[i] or 0) + carry
    if s >= BASE then
      s = s - BASE
      carry = 1
    else
      carry = 0
    end
    r[i] = s
  end
  if carry > 0 then r[n+1] = carry end
  return r
end

function bigint.sub(a, b)
  -- assumes a >= b
  local r = {}
  local borrow = 0
  for i=1,#a do
    local s = a[i] - (b[i] or 0) - borrow
    if s < 0 then
      s = s + BASE
      borrow = 1
    else
      borrow = 0
    end
    r[i] = s
  end
  return trim(r)
end

local function add_small(a, m)
  local r = clone(a)
  local i = 1
  local carry = m
  while carry > 0 do
    local s = (r[i] or 0) + carry
    r[i] = s % BASE
    carry = math.floor(s / BASE)
    i = i + 1
  end
  return r
end

local function mul_small(a, m)
  if m == 0 or bigint.is_zero(a) then return {} end
  local r = {}
  local carry = 0
  for i=1,#a do
    local prod = a[i] * m + carry
    r[i] = prod % BASE
    carry = math.floor(prod / BASE)
  end
  while carry > 0 do
    r[#r+1] = carry % BASE
    carry = math.floor(carry / BASE)
  end
  return r
end

local function divmod_small(a, m)
  local r = {}
  local carry = 0
  for i = #a, 1, -1 do
    local cur = a[i] + carry * BASE
    local q = math.floor(cur / m)
    carry = cur % m
    r[i] = q
  end
  return trim(r), carry
end

function bigint.div2(a)
  local r = {}
  local carry = 0
  for i = #a, 1, -1 do
    local cur = a[i] + carry * BASE
    r[i] = math.floor(cur / 2)
    carry = cur % 2
  end
  return trim(r)
end

function bigint.from_hex(hex)
  local s = hex:gsub('^0x', ''):gsub('%s+', '')
  local r = {}
  for i=1,#s do
    local c = s:sub(i,i)
    local v = tonumber(c, 16)
    if not v then
      error('invalid hex digit')
    end
    r = mul_small(r, 16)
    r = add_small(r, v)
  end
  return r
end

function bigint.from_bytes(bytes)
  local r = {}
  for i=1,#bytes do
    local v = bytes:byte(i)
    r = mul_small(r, 256)
    r = add_small(r, v)
  end
  return r
end

function bigint.to_bytes(a, size)
  if bigint.is_zero(a) then
    if size then return string.rep('\0', size) end
    return ''
  end
  local t = clone(a)
  local bytes = {}
  while not bigint.is_zero(t) do
    local rem
    t, rem = divmod_small(t, 256)
    bytes[#bytes+1] = string.char(rem)
  end
  local s = string.reverse(table.concat(bytes))
  if size and #s < size then
    s = string.rep('\0', size - #s) .. s
  end
  return s
end

function bigint.modmul(a, b, m)
  local result = {}
  local x = clone(a)
  local y = clone(b)
  while not bigint.is_zero(y) do
    if bigint.is_odd(y) then
      result = bigint.add(result, x)
      if bigint.cmp(result, m) >= 0 then
        result = bigint.sub(result, m)
      end
    end
    y = bigint.div2(y)
    if bigint.is_zero(y) then
      break
    end
    x = bigint.add(x, x)
    if bigint.cmp(x, m) >= 0 then
      x = bigint.sub(x, m)
    end
  end
  return result
end

function bigint.modpow(base, exp, mod)
  local result = bigint.one()
  local b = clone(base)
  local e = clone(exp)
  while not bigint.is_zero(e) do
    if bigint.is_odd(e) then
      result = bigint.modmul(result, b, mod)
    end
    e = bigint.div2(e)
    if not bigint.is_zero(e) then
      b = bigint.modmul(b, b, mod)
    end
  end
  return result
end

return bigint
