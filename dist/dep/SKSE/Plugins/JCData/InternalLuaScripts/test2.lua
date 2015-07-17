local function average(summ, n)
  return summ / n
end

local summ = 0
local testCount = 1000000

local side = 2

math.randomseed(os.time())

local random = math.random

local function fitsToCircle()
  local x, y = 2 * random() - 1, 2 * random() - 1
  local res = (x*x + y*y) < 1 and 1 or 0
  return res
end

for i = 1, testCount do
  summ = summ + fitsToCircle() / testCount
end

print('my pi is', summ * 4)


