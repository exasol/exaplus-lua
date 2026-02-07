local lineedit = {}
lineedit.CANCEL = {}

local function is_tty()
  local ok = os.execute('test -t 0 >/dev/null 2>&1')
  return ok == true or ok == 0
end

local function set_raw(enable)
  if enable then
    os.execute('stty -echo -icanon -isig min 1 time 0 2>/dev/null')
  else
    os.execute('stty echo icanon isig 2>/dev/null')
  end
end

local function get_cols()
  local cols = tonumber(os.getenv('COLUMNS') or '')
  if cols and cols > 0 then return cols end
  local p = io.popen('stty size 2>/dev/null')
  if p then
    local out = p:read('*a') or ''
    p:close()
    local _, c = out:match('^(%d+)%s+(%d+)')
    cols = tonumber(c or '')
    if cols and cols > 0 then return cols end
  end
  return 80
end

local function visible_len(s)
  local plain = s:gsub('\27%[[0-9;]*m', '')
  return #plain
end

local function pad_status(s)
  if not s or s == '' then return s end
  local cols = get_cols()
  local len = visible_len(s)
  if len >= cols then return s end
  local pad = string.rep(' ', cols - len)
  local rs, re = s:find('\27%[0m')
  if rs then
    return s:sub(1, rs-1) .. pad .. s:sub(rs)
  end
  return s .. pad
end

local function redraw(prompt, line, cursor, status)
  io.write('\27[?25l')
  io.write('\r' .. prompt .. line .. '\27[K')
  if status and status ~= '' then
    io.write('\n' .. pad_status(status) .. '\27[K')
    io.write('\27[1A\r')
  else
    io.write('\r')
  end
  local move = #prompt + cursor
  if move > 0 then
    io.write(string.format('\27[%dC', move))
  end
  io.write('\27[?25h')
  io.flush()
end

local function read_char()
  local ch = io.read(1)
  return ch
end

local function is_word_char(c)
  return c:match('[%w_]') ~= nil
end

local function move_word_left(buf, cursor)
  if cursor == 0 then return cursor end
  local i = cursor
  while i > 0 and not is_word_char(buf:sub(i,i)) do i = i - 1 end
  while i > 0 and is_word_char(buf:sub(i,i)) do i = i - 1 end
  return i
end

local function move_word_right(buf, cursor)
  local i = cursor + 1
  local len = #buf
  while i <= len and not is_word_char(buf:sub(i,i)) do i = i + 1 end
  while i <= len and is_word_char(buf:sub(i,i)) do i = i + 1 end
  return i - 1
end

function lineedit.new_history()
  return {list = {}}
end

function lineedit.add_history(hist, line)
  if not line or line == '' then return end
  local list = hist.list
  if #list == 0 or list[#list] ~= line then
    list[#list+1] = line
  end
end

function lineedit.load_history(hist, path, max_lines)
  if not path then return end
  local f = io.open(path, 'r')
  if not f then return end
  for line in f:lines() do
    lineedit.add_history(hist, line)
  end
  f:close()
  if max_lines and #hist.list > max_lines then
    local start = #hist.list - max_lines + 1
    local trimmed = {}
    for i=start,#hist.list do trimmed[#trimmed+1] = hist.list[i] end
    hist.list = trimmed
  end
end

function lineedit.save_history(hist, path, max_lines)
  if not path then return end
  local list = hist.list
  local start = 1
  if max_lines and #list > max_lines then
    start = #list - max_lines + 1
  end
  local dir = path:match('^(.+)/[^/]+$')
  if dir and dir ~= '' then
    os.execute(string.format('mkdir -p %q 2>/dev/null', dir))
  end
  local f = io.open(path, 'w')
  if not f then return end
  for i=start,#list do
    f:write(list[i], '\n')
  end
  f:close()
end

local function reverse_search(prompt, hist, current_line, status)
  local list = hist.list
  local query = ''
  local idx = #list + 1
  local found = ''
  while true do
    local label = "(reverse-i-search)`" .. query .. "': " .. found
    redraw(label, '', 0, status)
    local ch = read_char()
    if not ch then return current_line end
    local b = ch:byte()
    if b == 13 or b == 10 then
      return found ~= '' and found or current_line
    elseif b == 27 then
      return current_line
    elseif b == 7 then
      return current_line
    elseif b == 127 or b == 8 then
      if #query > 0 then
        query = query:sub(1, #query-1)
      end
      idx = #list + 1
    elseif b == 18 then
      -- continue search
    elseif b >= 32 and b <= 126 then
      query = query .. ch
      idx = #list + 1
    else
      -- ignore other controls
    end

    found = ''
    local i = idx - 1
    while i >= 1 do
      if list[i]:find(query, 1, true) then
        found = list[i]
        idx = i
        break
      end
      i = i - 1
    end
  end
end

function lineedit.readline(prompt, hist, status)
  if not is_tty() then
    io.write(prompt)
    io.flush()
    return io.read('*l')
  end

  set_raw(true)
  local ok, line = pcall(function()
    local buf = ''
    local cursor = 0
    local hist_index = nil
    local hist_orig = ''
    redraw(prompt, buf, cursor, status)
    while true do
      local ch = read_char()
      if not ch then return nil end
      local b = ch:byte()
      if b == 13 or b == 10 then
        io.write('\r' .. prompt .. buf .. '\27[K')
        if status and status ~= '' then
          io.write('\n\27[K')
        else
          io.write('\n')
        end
        io.flush()
        return buf
      elseif b == 127 or b == 8 then
        if cursor > 0 then
          buf = buf:sub(1, cursor-1) .. buf:sub(cursor+1)
          cursor = cursor - 1
        end
      elseif b == 3 then
        io.write('\r\27[K\n')
        io.flush()
        return lineedit.CANCEL
      elseif b == 1 then
        cursor = 0
      elseif b == 5 then
        cursor = #buf
      elseif b == 11 then
        buf = buf:sub(1, cursor)
      elseif b == 21 then
        buf = buf:sub(cursor+1)
        cursor = 0
      elseif b == 23 then
        if cursor > 0 then
          local new_cursor = move_word_left(buf, cursor)
          buf = buf:sub(1, new_cursor) .. buf:sub(cursor+1)
          cursor = new_cursor
        end
      elseif b == 4 then
        if #buf == 0 then
          io.write('\r' .. prompt .. buf .. '\27[K')
          if status and status ~= '' then
            io.write('\n\27[K')
          else
            io.write('\n')
          end
          io.flush()
          return nil
        else
          if cursor < #buf then
            buf = buf:sub(1, cursor) .. buf:sub(cursor+2)
          end
        end
      elseif b == 18 then
        local searched = reverse_search(prompt, hist, buf, status)
        buf = searched or buf
        cursor = #buf
      elseif b == 27 then
        local next1 = read_char()
        local next2 = read_char()
        if next1 == '[' then
          if next2 == 'A' then
            -- up
            if #hist.list > 0 then
              if not hist_index then
                hist_index = #hist.list
                hist_orig = buf
              elseif hist_index > 1 then
                hist_index = hist_index - 1
              end
              buf = hist.list[hist_index] or ''
              cursor = #buf
            end
          elseif next2 == 'B' then
            -- down
            if hist_index then
              if hist_index < #hist.list then
                hist_index = hist_index + 1
                buf = hist.list[hist_index] or ''
              else
                hist_index = nil
                buf = hist_orig or ''
              end
              cursor = #buf
            end
          elseif next2 == 'C' then
            -- right
            if cursor < #buf then cursor = cursor + 1 end
          elseif next2 == 'D' then
            -- left
            if cursor > 0 then cursor = cursor - 1 end
          end
        elseif next1 == 'O' then
          -- ignore
        end
        if next1 == '[' and next2 == '1' then
          local next3 = read_char()
          local next4 = read_char()
          if next3 == ';' and next4 == '5' then
            local dir = read_char()
            if dir == 'C' then
              cursor = move_word_right(buf, cursor)
            elseif dir == 'D' then
              cursor = move_word_left(buf, cursor)
            end
          end
        end
      elseif b >= 32 and b <= 126 then
        buf = buf:sub(1, cursor) .. ch .. buf:sub(cursor+1)
        cursor = cursor + 1
      end
      redraw(prompt, buf, cursor, status)
    end
  end)
  set_raw(false)
  if not ok then
    set_raw(false)
    error(line)
  end
  return line
end

return lineedit
