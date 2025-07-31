local M = {}

function M.pad_left(str, width, char)
  char = char or ' '
  local str_width = vim.fn.strwidth(tostring(str))
  if str_width >= width then
    return tostring(str)
  end
  local padding = string.rep(char, width - str_width)
  return padding .. tostring(str)
end

function M.pad_right(str, width, char)
  char = char or ' '
  local str_width = vim.fn.strwidth(tostring(str))
  if str_width >= width then
    return tostring(str)
  end
  local padding = string.rep(char, width - str_width)
  return tostring(str) .. padding
end

function M.pad_center(str, width, char)
  char = char or ' '
  local str_width = vim.fn.strwidth(tostring(str))
  if str_width >= width then
    return tostring(str)
  end
  local total_padding = width - str_width
  local left_padding = math.floor(total_padding / 2)
  local right_padding = total_padding - left_padding
  return string.rep(char, left_padding) .. tostring(str) .. string.rep(char, right_padding)
end

function M.truncate(str, width, suffix)
  suffix = suffix or '...'
  local str_width = vim.fn.strwidth(tostring(str))
  if str_width <= width then
    return tostring(str)
  end
  local truncated = vim.fn.strpart(tostring(str), 0, width - vim.fn.strwidth(suffix))
  return truncated .. suffix
end

function M.title_case(str)
  return tostring(str):gsub('%w+', function(w) 
    return w:sub(1,1):upper()..w:sub(2):lower() 
  end)
end

return M