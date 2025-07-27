local M = {}

-- Standardized section renderer that handles title, underline, and content with proper alignment
function M.render_section(section_module, width, height, config)
  config = config or {}
  
  -- Default alignment settings
  local title_alignment = config.title_alignment or 'center'
  local content_alignment = config.content_alignment or 'center'
  local vertical_alignment = config.vertical_alignment or 'center'
  
  -- Section type determines highlight groups
  local section_type = config.section_type or 'sub' -- 'main' or 'sub'
  local title_hl = section_type == 'main' and 'LuxDashMainTitle' or 'LuxDashSubTitle'
  local separator_hl = section_type == 'main' and 'LuxDashMainSeparator' or 'LuxDashSubSeparator'
  
  -- Allow custom highlight groups
  if config.title_highlight then
    title_hl = config.title_highlight
  end
  if config.separator_highlight then
    separator_hl = config.separator_highlight
  end
  
  -- Get content from the section module
  local raw_content = {}
  if section_module and section_module.render then
    raw_content = section_module.render(width, height, config) or {}
  end
  
  -- Build structured content
  local content = {}
  
  -- Add title if configured
  if config.title and config.show_title ~= false then
    local title_line = M.align_text(config.title, width, title_alignment)
    table.insert(content, {title_hl, title_line})
    
    -- Add underline if configured
    if config.show_underline ~= false then
      -- For horizontal sections, create visual separation by using shorter underlines
      local underline_width = width
      if config.section_type == 'sub' then
        -- Reduce underline width significantly for sub-sections to create visual gaps
        underline_width = math.max(1, width - 4)
      end
      
      local underline = string.rep('─', underline_width)
      -- Create the full-width line with gaps on the sides
      local gap_size = math.floor((width - underline_width) / 2)
      local left_gap = string.rep(' ', gap_size)
      local right_gap = string.rep(' ', width - underline_width - gap_size)
      local spaced_underline = left_gap .. underline .. right_gap
      
      table.insert(content, {separator_hl, spaced_underline})
    end
    
    -- Add spacing after title/underline
    if config.title_spacing ~= false then
      table.insert(content, '')
    end
  end
  
  -- Process and add section content
  for _, line in ipairs(raw_content) do
    if type(line) == 'table' and #line >= 2 then
      -- Line with highlight: {highlight, text}
      local aligned_text = M.align_text(line[2], width, content_alignment)
      table.insert(content, {line[1], aligned_text})
    else
      -- Plain text line
      local text = tostring(line or '')
      local aligned_text = M.align_text(text, width, content_alignment)
      table.insert(content, aligned_text)
    end
  end
  
  -- Apply vertical alignment
  return M.apply_vertical_alignment(content, width, height, vertical_alignment)
end

-- Align text horizontally within given width
function M.align_text(text, width, alignment)
  local text_width = vim.fn.strwidth(text)
  
  if alignment == 'left' then
    local pad_right = math.max(0, width - text_width)
    return text .. string.rep(' ', pad_right)
  elseif alignment == 'right' then
    local pad_left = math.max(0, width - text_width)
    return string.rep(' ', pad_left) .. text
  else -- center
    local pad_left = math.max(0, math.floor((width - text_width) / 2))
    local pad_right = math.max(0, width - pad_left - text_width)
    return string.rep(' ', pad_left) .. text .. string.rep(' ', pad_right)
  end
end

-- Apply vertical alignment to content
function M.apply_vertical_alignment(content, width, height, alignment)
  local content_height = #content
  local pad_top = 0
  
  -- Calculate vertical padding
  if alignment == 'top' then
    pad_top = 0
  elseif alignment == 'bottom' then
    pad_top = math.max(0, height - content_height)
  else -- center
    pad_top = math.max(0, math.floor((height - content_height) / 2))
  end
  
  local aligned = {}
  
  -- Add top padding
  for _ = 1, pad_top do
    table.insert(aligned, string.rep(' ', width))
  end
  
  -- Add content
  for _, line in ipairs(content) do
    table.insert(aligned, line)
  end
  
  -- Add bottom padding
  local remaining_lines = height - #aligned
  for _ = 1, remaining_lines do
    table.insert(aligned, string.rep(' ', width))
  end
  
  return aligned
end

return M