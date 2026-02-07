local sha1 = {}

local function u32(x)
  return x % 4294967296
end

local function band(a, b)
  local res = 0
  local bit = 1
  for _ = 0, 31 do
    local aa = a % 2
    local bb = b % 2
    if aa == 1 and bb == 1 then
      res = res + bit
    end
    a = (a - aa) / 2
    b = (b - bb) / 2
    bit = bit * 2
  end
  return res
end

local function bor(a, b)
  local res = 0
  local bit = 1
  for _ = 0, 31 do
    local aa = a % 2
    local bb = b % 2
    if aa == 1 or bb == 1 then
      res = res + bit
    end
    a = (a - aa) / 2
    b = (b - bb) / 2
    bit = bit * 2
  end
  return res
end

local function bxor(a, b)
  local res = 0
  local bit = 1
  for _ = 0, 31 do
    local aa = a % 2
    local bb = b % 2
    if aa ~= bb then
      res = res + bit
    end
    a = (a - aa) / 2
    b = (b - bb) / 2
    bit = bit * 2
  end
  return res
end

local function bnot(a)
  return u32(4294967295 - a)
end

local function lshift(a, n)
  return u32(a * 2^n)
end

local function rshift(a, n)
  return math.floor(a / 2^n)
end

local function rol(a, n)
  return u32(lshift(a, n) + rshift(a, 32 - n))
end

function sha1.sum(data)
  local bytes = {data:byte(1, #data)}
  local bitlen = #bytes * 8

  -- append 0x80, then pad with zeros
  bytes[#bytes+1] = 0x80
  while (#bytes % 64) ~= 56 do
    bytes[#bytes+1] = 0
  end
  -- append length (big-endian 64-bit)
  for i = 7, 0, -1 do
    bytes[#bytes+1] = math.floor(bitlen / 2^(i*8)) % 256
  end

  local h0 = 0x67452301
  local h1 = 0xEFCDAB89
  local h2 = 0x98BADCFE
  local h3 = 0x10325476
  local h4 = 0xC3D2E1F0

  local w = {}

  for chunk = 1, #bytes, 64 do
    for i = 0, 15 do
      local b1 = bytes[chunk + i*4]
      local b2 = bytes[chunk + i*4 + 1]
      local b3 = bytes[chunk + i*4 + 2]
      local b4 = bytes[chunk + i*4 + 3]
      w[i] = lshift(b1, 24) + lshift(b2, 16) + lshift(b3, 8) + b4
    end
    for i = 16, 79 do
      w[i] = rol(bxor(bxor(bxor(w[i-3], w[i-8]), w[i-14]), w[i-16]), 1)
    end

    local a = h0
    local b = h1
    local c = h2
    local d = h3
    local e = h4

    for i = 0, 79 do
      local f, k
      if i <= 19 then
        f = bor(band(b, c), band(bnot(b), d))
        k = 0x5A827999
      elseif i <= 39 then
        f = bxor(b, bxor(c, d))
        k = 0x6ED9EBA1
      elseif i <= 59 then
        f = bor(bor(band(b, c), band(b, d)), band(c, d))
        k = 0x8F1BBCDC
      else
        f = bxor(b, bxor(c, d))
        k = 0xCA62C1D6
      end
      local temp = u32(rol(a, 5) + f + e + k + w[i])
      e = d
      d = c
      c = rol(b, 30)
      b = a
      a = temp
    end

    h0 = u32(h0 + a)
    h1 = u32(h1 + b)
    h2 = u32(h2 + c)
    h3 = u32(h3 + d)
    h4 = u32(h4 + e)
  end

  local function to_bytes(x)
    return string.char(rshift(x,24) % 256, rshift(x,16) % 256, rshift(x,8) % 256, x % 256)
  end

  return table.concat({to_bytes(h0), to_bytes(h1), to_bytes(h2), to_bytes(h3), to_bytes(h4)})
end

return sha1
