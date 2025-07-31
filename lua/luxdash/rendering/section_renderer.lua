local M = {}
local alignment = require('luxdash.rendering.alignment')

-- Standardized section renderer that handles title, underline, and content with proper alignment
function M.render_section(section_module, width, height, config)
  config = config or {}
  
  -- Section type determines highlight groups
  local section_type = config.section_type or 'sub' -- 'main' or 'sub'
  
  -- Default alignment settings
  local title_alignment = config.title_alignment or 'center'
  local content_alignment = config.content_alignment or 'center'
  local vertical_alignment = config.vertical_alignment or 'center'
  
  -- Padding settings for subsections
  local padding = nil
  if section_type == 'sub' and config.padding then
    padding = config.padding
  end
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
    local title_line = alignment.align_text(config.title, width, title_alignment, padding)
    table.insert(content, {title_hl, title_line})
    
    -- Add underline if configured
    if config.show_underline ~= false then
      local underline_width = width
      local underline = string.rep('─', underline_width)
      
      table.insert(content, {separator_hl, underline})
    end
    
    -- Add spacing after title/underline
    if config.title_spacing ~= false then
      table.insert(content, '')
    end
  end
  
  -- Process and add section content
  for _, line in ipairs(raw_content) do
    if type(line) == 'table' then
      if #line >= 2 and type(line[1]) == 'string' and type(line[2]) == 'string' then
        -- Simple format: {highlight, text}
        local text = line[2]
        local highlight_group = line[1]
        local aligned_text = alignment.align_text_with_highlight(text, width, content_alignment, padding, highlight_group)
        table.insert(content, {highlight_group, aligned_text})
      elseif #line > 0 and type(line[1]) == 'table' then
        -- Complex format: {{highlight, text}, {highlight, text}, ...}
        -- For now, pass through as-is since alignment is handled at render time
        table.insert(content, line)
      else
        -- Unknown table format - convert to string
        local text = tostring(line)
        local aligned_text = alignment.align_text(text, width, content_alignment, padding)
        table.insert(content, aligned_text)
      end
    else
      -- Plain text line
      local text = tostring(line or '')
      local aligned_text = alignment.align_text(text, width, content_alignment, padding)
      table.insert(content, aligned_text)
    end
  end
  
  -- For main sections (logo), allow content to exceed allocated height
  -- For sub-sections, ensure content doesn't exceed allocated height by truncating if necessary
  if section_type ~= 'main' then
    local max_content_height = height
    if #content > max_content_height then
      local truncated_content = {}
      for i = 1, max_content_height do
        table.insert(truncated_content, content[i])
      end
      content = truncated_content
    end
  end
  
  -- Apply vertical alignment
  return alignment.apply_vertical_alignment(content, width, height, vertical_alignment, section_type)
end

return M