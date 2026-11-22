-- One function per smell, for the end-to-end smell test.
local M = {}

function M.describe(code)
  if code == 0 then
    return "0"
  elseif code == 1 then
    return "1"
  elseif code == 2 then
    return "2"
  elseif code == 3 then
    return "3"
  elseif code == 4 then
    return "4"
  elseif code == 5 then
    return "5"
  elseif code == 6 then
    return "6"
  elseif code == 7 then
    return "7"
  elseif code == 8 then
    return "8"
  elseif code == 9 then
    return "9"
  end
  return "unknown"
end

function M.deep(a, b)
  if a > 0 then
    if b > 0 then
      if a > b then
        if a > 100 then
          return 1
        end
      end
    end
  end
  return 0
end

function M.bumpy(xs, ys)
  local total = 0
  for _, x in ipairs(xs) do
    if x > 0 then total = total + x end
  end
  for _, y in ipairs(ys) do
    if y > 0 then total = total + y end
  end
  return total
end

function M.eligible(c)
  if c.active and c.age > 17 or c.override then
    return true
  end
  return false
end

function M.large()
  local total = 0
  total = total + 0
  total = total + 1
  total = total + 2
  total = total + 3
  total = total + 4
  total = total + 5
  total = total + 6
  total = total + 7
  total = total + 8
  total = total + 9
  total = total + 10
  total = total + 11
  total = total + 12
  total = total + 13
  total = total + 14
  total = total + 15
  total = total + 16
  total = total + 17
  total = total + 18
  total = total + 19
  total = total + 20
  total = total + 21
  total = total + 22
  total = total + 23
  total = total + 24
  total = total + 25
  total = total + 26
  total = total + 27
  total = total + 28
  total = total + 29
  total = total + 30
  total = total + 31
  total = total + 32
  total = total + 33
  total = total + 34
  total = total + 35
  total = total + 36
  total = total + 37
  total = total + 38
  total = total + 39
  total = total + 40
  total = total + 41
  total = total + 42
  total = total + 43
  total = total + 44
  total = total + 45
  total = total + 46
  total = total + 47
  total = total + 48
  total = total + 49
  total = total + 50
  total = total + 51
  total = total + 52
  total = total + 53
  total = total + 54
  total = total + 55
  total = total + 56
  total = total + 57
  total = total + 58
  total = total + 59
  total = total + 60
  total = total + 61
  total = total + 62
  total = total + 63
  total = total + 64
  total = total + 65
  total = total + 66
  total = total + 67
  return total
end

function M.ship(order, to, from, carrier, at)
  return order
end

return M
