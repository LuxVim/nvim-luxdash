local M = {}

function M.calculate_layout(winheight, winwidth)
  local top_height = math.floor(winheight * 0.8)
  local bottom_height = winheight - top_height
  
  local top_left_width = math.floor(winwidth * 0.5)
  local top_right_width = winwidth - top_left_width
  
  local bottom_section_width = math.floor(winwidth / 3)
  local bottom_left_width = bottom_section_width
  local bottom_center_width = bottom_section_width
  local bottom_right_width = winwidth - bottom_left_width - bottom_center_width
  
  return {
    top = {
      height = top_height,
      left = { width = top_left_width, height = top_height },
      right = { width = top_right_width, height = top_height }
    },
    bottom = {
      height = bottom_height,
      left = { width = bottom_left_width, height = bottom_height },
      center = { width = bottom_center_width, height = bottom_height },
      right = { width = bottom_right_width, height = bottom_height }
    }
  }
end

function M.load_section(section_name)
  local ok, section_module = pcall(require, 'luxdash.sections.' .. section_name)
  if ok and section_module and type(section_module.render) == 'function' then
    return section_module
  end
  return nil
end

return M