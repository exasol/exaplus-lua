local base64 = {}

local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function base64.encode(data)
  if data == nil or data == '' then return '' end
  local bytes = {data:byte(1, #data)}
  local out = {}
  local i = 1
  while i <= #bytes do
    local a = bytes[i] or 0
    local c = bytes[i+1] or 0
    local d = bytes[i+2] or 0
    local n = a * 65536 + c * 256 + d
    local s1 = math.floor(n / 262144) % 64
    local s2 = math.floor(n / 4096) % 64
    local s3 = math.floor(n / 64) % 64
    local s4 = n % 64
    out[#out+1] = b:sub(s1+1, s1+1)
    out[#out+1] = b:sub(s2+1, s2+1)
    if i+1 <= #bytes then
      out[#out+1] = b:sub(s3+1, s3+1)
    else
      out[#out+1] = '='
    end
    if i+2 <= #bytes then
      out[#out+1] = b:sub(s4+1, s4+1)
    else
      out[#out+1] = '='
    end
    i = i + 3
  end
  return table.concat(out)
end

return base64
