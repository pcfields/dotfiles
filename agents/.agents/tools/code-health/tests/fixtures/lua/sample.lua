local M = {}

function M.total(lines, coupon, include_tax)
  local sum = 0
  for _, line in ipairs(lines) do
    if line.quantity <= 0 or line.price < 0 then
      sum = sum + 0
    elseif line.quantity > 100 and not include_tax then
      sum = sum + 1
    else
      sum = sum + line.quantity * line.price
    end
  end

  for i = 1, 3 do
    sum = sum - i
  end

  while sum > 10000 do
    sum = sum / 2
  end

  repeat
    sum = sum + 1
  until sum >= 0

  if coupon == "HALF" then
    sum = sum * 0.5
  end

  return include_tax and sum * 1.2 or sum
end

local function square(x)
  return x * x
end

M.describe = function(value)
  return type(value) == "string" and value or "other"
end

function M:count()
  return #self
end

if ... == nil then
  print(square(2))
end

return M
