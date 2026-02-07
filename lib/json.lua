local json = {}

local function escape_str(s)
  local repl = {
    ['\\'] = '\\\\',
    ['"'] = '\\"',
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t',
  }
  return s:gsub('[\\"%z\1-\31]', function(c)
    return repl[c] or string.format('\\u%04x', c:byte())
  end)
end

local function is_array(t)
  local n = 0
  for k,_ in pairs(t) do
    if type(k) ~= 'number' then return false end
    if k > n then n = k end
  end
  for i=1,n do
    if t[i] == nil then return false end
  end
  return true
end

local function encode_value(v)
  local tv = type(v)
  if tv == 'nil' then
    return 'null'
  elseif tv == 'string' then
    return '"' .. escape_str(v) .. '"'
  elseif tv == 'number' then
    if v ~= v or v == math.huge or v == -math.huge then
      return 'null'
    end
    return tostring(v)
  elseif tv == 'boolean' then
    return v and 'true' or 'false'
  elseif tv == 'table' then
    local parts = {}
    if is_array(v) then
      for i=1,#v do
        parts[#parts+1] = encode_value(v[i])
      end
      return '[' .. table.concat(parts, ',') .. ']'
    else
      for k,val in pairs(v) do
        parts[#parts+1] = '"' .. escape_str(k) .. '":' .. encode_value(val)
      end
      return '{' .. table.concat(parts, ',') .. '}'
    end
  else
    return 'null'
  end
end

function json.encode(v)
  return encode_value(v)
end

-- Decoder
local function decode_error(str, idx, msg)
  error(string.format('json decode error at %d: %s', idx, msg))
end

local function skip_ws(str, idx)
  local len = #str
  while idx <= len do
    local c = str:byte(idx)
    if c ~= 32 and c ~= 9 and c ~= 10 and c ~= 13 then
      break
    end
    idx = idx + 1
  end
  return idx
end

local function parse_string(str, idx)
  idx = idx + 1 -- skip opening quote
  local res = {}
  local len = #str
  while idx <= len do
    local c = str:byte(idx)
    if c == 34 then
      return table.concat(res), idx + 1
    elseif c == 92 then
      local n = str:byte(idx+1)
      if n == 34 then res[#res+1] = '"'
      elseif n == 92 then res[#res+1] = '\\'
      elseif n == 47 then res[#res+1] = '/'
      elseif n == 98 then res[#res+1] = '\b'
      elseif n == 102 then res[#res+1] = '\f'
      elseif n == 110 then res[#res+1] = '\n'
      elseif n == 114 then res[#res+1] = '\r'
      elseif n == 116 then res[#res+1] = '\t'
      elseif n == 117 then
        local hex = str:sub(idx+2, idx+5)
        if not hex:match('%x%x%x%x') then
          decode_error(str, idx, 'invalid unicode escape')
        end
        local code = tonumber(hex, 16)
        if code < 0x80 then
          res[#res+1] = string.char(code)
        elseif code < 0x800 then
          res[#res+1] = string.char(0xC0 + math.floor(code/0x40), 0x80 + (code % 0x40))
        else
          res[#res+1] = string.char(0xE0 + math.floor(code/0x1000), 0x80 + (math.floor(code/0x40) % 0x40), 0x80 + (code % 0x40))
        end
      else
        decode_error(str, idx, 'invalid escape')
      end
      idx = idx + 2
    else
      res[#res+1] = string.char(c)
      idx = idx + 1
    end
  end
  decode_error(str, idx, 'unterminated string')
end

local function parse_number(str, idx)
  local start = idx
  local len = #str
  while idx <= len do
    local c = str:byte(idx)
    if (c >= 48 and c <= 57) or c == 45 or c == 43 or c == 46 or c == 69 or c == 101 then
      idx = idx + 1
    else
      break
    end
  end
  local num = tonumber(str:sub(start, idx-1))
  if not num then
    decode_error(str, start, 'invalid number')
  end
  return num, idx
end

local parse_value

local function parse_array(str, idx)
  idx = idx + 1 -- skip [
  local res = {}
  idx = skip_ws(str, idx)
  if str:byte(idx) == 93 then
    return res, idx + 1
  end
  while true do
    local val
    val, idx = parse_value(str, idx)
    res[#res+1] = val
    idx = skip_ws(str, idx)
    local c = str:byte(idx)
    if c == 93 then
      return res, idx + 1
    elseif c ~= 44 then
      decode_error(str, idx, 'expected , or ]')
    end
    idx = skip_ws(str, idx + 1)
  end
end

local function parse_object(str, idx)
  idx = idx + 1 -- skip {
  local res = {}
  idx = skip_ws(str, idx)
  if str:byte(idx) == 125 then
    return res, idx + 1
  end
  while true do
    if str:byte(idx) ~= 34 then
      decode_error(str, idx, 'expected string key')
    end
    local key
    key, idx = parse_string(str, idx)
    idx = skip_ws(str, idx)
    if str:byte(idx) ~= 58 then
      decode_error(str, idx, 'expected :')
    end
    idx = skip_ws(str, idx + 1)
    local val
    val, idx = parse_value(str, idx)
    res[key] = val
    idx = skip_ws(str, idx)
    local c = str:byte(idx)
    if c == 125 then
      return res, idx + 1
    elseif c ~= 44 then
      decode_error(str, idx, 'expected , or }')
    end
    idx = skip_ws(str, idx + 1)
  end
end

parse_value = function(str, idx)
  idx = skip_ws(str, idx)
  local c = str:byte(idx)
  if c == 34 then
    return parse_string(str, idx)
  elseif c == 123 then
    return parse_object(str, idx)
  elseif c == 91 then
    return parse_array(str, idx)
  elseif c == 116 and str:sub(idx, idx+3) == 'true' then
    return true, idx + 4
  elseif c == 102 and str:sub(idx, idx+4) == 'false' then
    return false, idx + 5
  elseif c == 110 and str:sub(idx, idx+3) == 'null' then
    return nil, idx + 4
  else
    return parse_number(str, idx)
  end
end

function json.decode(str)
  local val, idx = parse_value(str, 1)
  idx = skip_ws(str, idx)
  if idx <= #str then
    decode_error(str, idx, 'trailing garbage')
  end
  return val
end

return json
