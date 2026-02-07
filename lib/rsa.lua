local bigint = require('bigint')
local base64 = require('base64')
local util = require('util')

local rsa = {}

local function pkcs1pad2(data, keysize)
  if #data > keysize - 11 then
    error('message too long for RSA')
  end
  local ps_len = keysize - #data - 3
  local ps = util.random_nonzero_bytes(ps_len)
  return string.char(0) .. string.char(2) .. ps .. string.char(0) .. data
end

function rsa.encrypt_pkcs1_v15(message, exp_hex, mod_hex)
  local mhex = mod_hex:gsub('^0x','')
  if (#mhex % 2) == 1 then mhex = '0' .. mhex end
  local keysize = #mhex / 2
  local padded = pkcs1pad2(message, keysize)
  local m = bigint.from_bytes(padded)
  local e = bigint.from_hex(exp_hex)
  local n = bigint.from_hex(mod_hex)
  local c = bigint.modpow(m, e, n)
  local c_bytes = bigint.to_bytes(c, keysize)
  return base64.encode(c_bytes)
end

return rsa
