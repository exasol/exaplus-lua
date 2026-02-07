local socket = require('socket')
local ssl = require('ssl')
local base64 = require('base64')
local sha1 = require('sha1')
local util = require('util')

local websocket = {}

local function read_n(sock, n)
  local chunks = {}
  local got = 0
  while got < n do
    local part, err, partial = sock:receive(n - got)
    if not part then
      if partial and #partial > 0 then
        chunks[#chunks+1] = partial
        got = got + #partial
      end
      if err then return nil, err end
    else
      chunks[#chunks+1] = part
      got = got + #part
    end
  end
  return table.concat(chunks)
end

-- Lua 5.1 doesn't have bit32 or bitwise ops; use arithmetic xor
local function bxor(a, b)
  local res = 0
  local bit = 1
  for _ = 0, 31 do
    local aa = a % 2
    local bb = b % 2
    if aa ~= bb then res = res + bit end
    a = (a - aa) / 2
    b = (b - bb) / 2
    bit = bit * 2
  end
  return res
end

local function mask_payload_arith(data, mask)
  local out = {}
  for i=1,#data do
    local m = mask:byte(((i-1) % 4) + 1)
    out[i] = string.char(bxor(data:byte(i), m))
  end
  return table.concat(out)
end

local function build_frame(payload, opcode)
  local fin = 0x80
  local b1 = fin + (opcode or 1)
  local len = #payload
  local mask = util.random_bytes(4)
  local b2
  local ext = ''
  if len < 126 then
    b2 = 0x80 + len
  elseif len < 65536 then
    b2 = 0x80 + 126
    ext = string.char(math.floor(len / 256) % 256, len % 256)
  else
    b2 = 0x80 + 127
    -- 64-bit length (we only support up to 2^53 safely)
    local l = len
    local bytes = {}
    for i=7,0,-1 do
      bytes[#bytes+1] = string.char(math.floor(l / 2^(i*8)) % 256)
    end
    ext = table.concat(bytes)
  end
  local masked = mask_payload_arith(payload, mask)
  return string.char(b1, b2) .. ext .. mask .. masked
end

local function read_http_response(sock)
  local status = sock:receive('*l')
  if not status then return nil, 'no response' end
  local headers = {}
  while true do
    local line = sock:receive('*l')
    if not line or line == '' then break end
    local k, v = line:match('^([^:]+):%s*(.*)')
    if k then headers[k:lower()] = v end
  end
  return status, headers
end

function websocket.connect(opts)
  local tcp = assert(socket.tcp())
  assert(tcp:connect(opts.host, opts.port))
  local params = {
    mode = 'client',
    protocol = 'tlsv1_2',
    verify = 'none',
    options = 'all',
  }
  local conn = assert(ssl.wrap(tcp, params))
  assert(conn:dohandshake())

  local cert = conn:getpeercertificate()
  if not cert then
    conn:close()
    return nil, 'no peer certificate'
  end
  local fp = util.hex_normalize(cert:digest('sha256'))

  local key = base64.encode(util.random_bytes(16))
  local request = table.concat({
    'GET ' .. (opts.path or '/') .. ' HTTP/1.1',
    'Host: ' .. opts.host .. ':' .. opts.port,
    'Upgrade: websocket',
    'Connection: Upgrade',
    'Sec-WebSocket-Key: ' .. key,
    'Sec-WebSocket-Version: 13',
    '',
    ''
  }, '\r\n')
  assert(conn:send(request))

  local status, headers = read_http_response(conn)
  if not status then return nil, 'handshake failed' end
  if not status:find('101') then
    return nil, 'handshake error: ' .. status
  end
  local accept = headers['sec-websocket-accept']
  local expected = base64.encode(sha1.sum(key .. '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'))
  if accept ~= expected then
    return nil, 'handshake accept mismatch'
  end

  local ws = {}
  ws._sock = conn

  function ws:send_text(text)
    local frame = build_frame(text, 1)
    return self._sock:send(frame)
  end

  function ws:send_pong(payload)
    local frame = build_frame(payload or '', 0xA)
    return self._sock:send(frame)
  end

  function ws:close()
    local frame = build_frame('', 0x8)
    pcall(function() self._sock:send(frame) end)
    pcall(function() self._sock:close() end)
  end

  function ws:recv()
    local message = {}
    while true do
      local hdr = read_n(self._sock, 2)
      if not hdr then return nil, 'connection closed' end
      local b1, b2 = hdr:byte(1,2)
      local fin = b1 >= 0x80
      local opcode = b1 % 16
      local masked = b2 >= 0x80
      local len = b2 % 128
      if len == 126 then
        local ext = read_n(self._sock, 2)
        len = ext:byte(1) * 256 + ext:byte(2)
      elseif len == 127 then
        local ext = read_n(self._sock, 8)
        len = 0
        for i=1,8 do
          len = len * 256 + ext:byte(i)
        end
      end
      local mask
      if masked then mask = read_n(self._sock, 4) end
      local payload = ''
      if len > 0 then
        payload = read_n(self._sock, len)
        if masked then
          payload = mask_payload_arith(payload, mask)
        end
      end

      if opcode == 0x8 then
        return nil, 'closed'
      elseif opcode == 0x9 then
        self:send_pong(payload)
      elseif opcode == 0xA then
        -- pong ignore
      elseif opcode == 0x1 or opcode == 0x2 or opcode == 0x0 then
        message[#message+1] = payload
        if fin then
          return table.concat(message)
        end
      end
    end
  end

  ws.fingerprint = fp
  return ws, nil, fp
end

return websocket
