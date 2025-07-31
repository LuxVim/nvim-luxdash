local M = {}

function M.clamp(value, min_val, max_val)
  return math.max(min_val, math.min(max_val, value))
end

function M.round(number)
  return math.floor(number + 0.5)
end

function M.percentage_of(value, total)
  if total == 0 then return 0 end
  return (value / total) * 100
end

function M.lerp(a, b, t)
  return a + (b - a) * t
end

function M.map_range(value, in_min, in_max, out_min, out_max)
  local t = (value - in_min) / (in_max - in_min)
  return M.lerp(out_min, out_max, t)
end

return M