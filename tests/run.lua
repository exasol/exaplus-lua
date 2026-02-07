local function run(cmd)
  local p = io.popen(cmd .. " 2>&1 ; echo __RC__:$?")
  local out = p:read('*a')
  p:close()
  local rc = tonumber(out:match('__RC__:(%d+)')) or 1
  out = out:gsub('__RC__:%d+%s*$','')
  return rc, out
end

local exaplus = './exaplus'
local default_fp = '9aefaa1987a5a191d6e23c714a480b461c5e3462e0a98ffb6683edb10fa99400'
local fp = os.getenv('EXAPLUS_TEST_FINGERPRINT') or default_fp
local conn = 'localhost/' .. fp .. ':8563'
local kh = '/tmp/exaplus_known_hosts_test_' .. tostring(os.time())

local function assert_true(cond, msg)
  if not cond then error(msg or 'assertion failed') end
end

-- Test 1: basic query
local cmd = string.format('EXAPLUS_KNOWN_HOSTS=%q %q -q -u sys -P exasol -c %q -sql %q', kh, exaplus, conn, 'SELECT 1;')
local rc, out = run(cmd)
assert_true(rc == 0, 'basic query failed: ' .. out)
assert_true(out:find('1') ~= nil, 'unexpected output: ' .. out)

-- Test 2: known_hosts saved
local f = io.open(kh, 'r')
assert_true(f ~= nil, 'known_hosts file not created')
local contents = f:read('*a')
f:close()
assert_true(contents:match('localhost:8563%s+%x+'), 'known_hosts entry missing')

-- Test 3: mismatch detection
local bad = io.open(kh, 'w')
bad:write('localhost:8563 deadbeef\n')
bad:close()
rc, out = run(cmd)
assert_true(rc ~= 0, 'expected failure on mismatched fingerprint')
assert_true(out:find('REMOTE CERTIFICATE HAS CHANGED'), 'expected certificate changed warning')

if not os.getenv('EXAPLUS_TEST_QUIET') then
  print('OK')
end
