local util = {}

function util.random_bytes(n)
  local f = io.open('/dev/urandom', 'rb')
  if f then
    local data = f:read(n)
    f:close()
    if data and #data == n then
      return data
    end
  end
  local addr = tostring({}):match('0x(.*)')
  local extra = tonumber(addr, 16) or 0
  math.randomseed(os.time() + extra)
  local t = {}
  for i=1,n do
    t[i] = string.char(math.random(0, 255))
  end
  return table.concat(t)
end

function util.random_nonzero_bytes(n)
  local out = {}
  while #out < n do
    local b = util.random_bytes(1):byte(1)
    if b ~= 0 then
      out[#out+1] = string.char(b)
    end
  end
  return table.concat(out)
end

function util.hex_normalize(s)
  return (s or ''):gsub(':',''):gsub('%s+',''):lower()
end

function util.read_password(prompt)
  io.write(prompt)
  io.flush()
  local ok = os.execute('stty -echo 2>/dev/null')
  local line = io.read('*l')
  os.execute('stty echo 2>/dev/null')
  io.write('\n')
  return line or ''
end

return util
