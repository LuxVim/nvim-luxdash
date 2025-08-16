local M = {}
local dashboard_data = require('luxdash.core.dashboard')
local layout = require('luxdash.layout')
local section_renderer = require('luxdash.rendering.section_renderer')
local line_utils = require('luxdash.rendering.line_utils')

function M.build()
  local config = require('luxdash').config
  local winheight = vim.api.nvim_win_get_height(0)
  local winwidth = vim.api.nvim_win_get_width(0)
  
  -- Apply buffer padding
  local padding = config.padding or { left = 2, right = 2, top = 1, bottom = 1 }
  local content_width = winwidth - padding.left - padding.right
  local content_height = winheight - padding.top - padding.bottom
  
  local layout_data = layout.calculate_layout(content_height, content_width, config.layout_config)
  
  dashboard_data.clear_dashboard()
  
  -- Render main section
  M.render_main_section(config, layout_data)
  
  -- Render bottom sections dynamically
  M.render_bottom_sections(config, layout_data)
end

function M.render_main_section(config, layout_data)
  local main_section_config = config.sections.main
  local section_module = layout.load_section(main_section_config.type)
  
  if not section_module then
    section_module = layout.load_section('logo')
  end
  
  -- Prepare section config with flattened structure
  local render_config = vim.tbl_deep_extend('force', {
    logo = config.logo,
    logo_color = config.logo_color,
    section_type = 'main',
    title_alignment = 'center',
    content_alignment = 'center',
    vertical_alignment = 'center',
    show_title = false,
    show_underline = false
  }, main_section_config)
  
  local main_content = section_renderer.render_section(
    section_module, 
    layout_data.main.width, 
    layout_data.main.height, 
    render_config
  )
  
  -- Add main section lines - ensure we get all the content, not just the calculated height
  local actual_main_lines = #main_content
  local allocated_height = layout_data.main.height
  
  -- For logo sections, prioritize showing the complete logo over layout constraints
  local lines_to_add = math.max(actual_main_lines, allocated_height)
  
  -- If the main content (logo) is longer than allocated space, adjust the layout
  if actual_main_lines > allocated_height then
    -- Reduce bottom section height to accommodate the full logo
    layout_data.bottom.height = math.max(1, layout_data.bottom.height - (actual_main_lines - allocated_height))
    layout_data.main.height = actual_main_lines
  end
  
  for i = 1, lines_to_add do
    local main_line = main_content[i] or require('luxdash.utils.width').get_padding(layout_data.main.width)
    dashboard_data.add_line(main_line)
  end
end

-- Extract section creation logic
function M.create_section_content(section_def, section_layout, index, total_sections)
  local section_module = layout.load_section(section_def.type)
  
  if not section_module then
    return M.create_empty_section(section_layout)
  end
  
  local render_config = M.prepare_section_config(section_def)
  local section_content = section_renderer.render_section(
    section_module,
    section_layout.width,
    section_layout.height,
    render_config
  )
  
  return {
    content = section_content,
    width = section_layout.width
  }
end

function M.prepare_section_config(section_def)
  local render_config = {
    section_type = 'sub',
    section_id = section_def.id,
    title = section_def.title,
    show_title = true,
    show_underline = true,
    title_alignment = 'center',
    content_alignment = section_def.content_align or 'center',
    vertical_alignment = 'top',
    padding = { left = 2, right = 2 },
    -- Copy important properties from section_def (check both flat and nested)
    menu_items = section_def.menu_items or (section_def.config and section_def.config.menu_items),
    max_files = section_def.max_files or (section_def.config and section_def.config.max_files)
  }
  
  -- Handle menu-specific config
  if section_def.type == 'menu' and render_config.menu_items then
    local menu = require('luxdash.utils.menu')
    if type(render_config.menu_items) == 'table' and #render_config.menu_items > 0 then
      if type(render_config.menu_items[1]) == 'string' then
        local processed_items = menu.options(render_config.menu_items)
        render_config.menu_items = processed_items
      end
    end
  end
  
  return render_config
end

function M.create_empty_section(section_layout)
  local empty_content = {}
  for j = 1, section_layout.height do
    table.insert(empty_content, require('luxdash.utils.width').get_padding(section_layout.width))
  end
  return {
    content = empty_content,
    width = section_layout.width
  }
end

function M.render_bottom_sections(config, layout_data)
  local bottom_sections = config.sections.bottom or {}
  local sections_content = {}
  
  -- Render each bottom section using extracted functions
  for i, section_def in ipairs(bottom_sections) do
    local section_layout = M.get_section_layout(i, #bottom_sections, layout_data)
    local section_content = M.create_section_content(section_def, section_layout, i, #bottom_sections)
    table.insert(sections_content, section_content)
  end
  
  -- Combine sections horizontally
  M.combine_sections_horizontally(sections_content, layout_data.bottom.height)
end

function M.get_section_layout(section_index, total_sections, layout_data)
  if total_sections == 1 then
    return {
      width = layout_data.bottom.width or layout_data.bottom.left.width + layout_data.bottom.center.width + layout_data.bottom.right.width,
      height = layout_data.bottom.height
    }
  elseif total_sections == 2 then
    if section_index == 1 then
      return {
        width = layout_data.bottom.left.width + math.floor((layout_data.bottom.center.width + layout_data.bottom.right.width) / 2),
        height = layout_data.bottom.height
      }
    else
      return {
        width = math.ceil((layout_data.bottom.center.width + layout_data.bottom.right.width) / 2),
        height = layout_data.bottom.height
      }
    end
  else
    -- Three or more sections - use the existing layout
    if section_index == 1 then
      return {
        width = layout_data.bottom.left.width,
        height = layout_data.bottom.height
      }
    elseif section_index == 2 then
      return {
        width = layout_data.bottom.center.width,
        height = layout_data.bottom.height
      }
    else
      return {
        width = layout_data.bottom.right.width,
        height = layout_data.bottom.height
      }
    end
  end
end

-- Extract width processing into separate function
local function ensure_exact_width(line, target_width)
  local width_utils = require('luxdash.utils.width')
  
  if type(line) == 'table' and #line > 0 and type(line[1]) == 'table' then
    -- Complex format: {{highlight, text}, {highlight, text}, ...}
    local text_width = 0
    for _, part in ipairs(line) do
      if type(part) == 'table' and #part >= 2 then
        text_width = text_width + vim.fn.strwidth(tostring(part[2] or ''))
      end
    end
    
    if text_width < target_width then
      local padded_line = vim.list_extend({}, line)
      table.insert(padded_line, {'Normal', width_utils.get_padding(target_width - text_width)})
      return padded_line
    elseif text_width > target_width then
      return M.truncate_complex_line(line, target_width)
    end
    return line
  elseif type(line) == 'table' and line[2] then
    -- Simple format: {highlight, text}
    local text = tostring(line[2])
    local text_width = vim.fn.strwidth(text)
    if text_width < target_width then
      return {line[1], text .. width_utils.get_padding(target_width - text_width)}
    elseif text_width > target_width then
      return {line[1], vim.fn.strpart(text, 0, target_width)}
    end
    return line
  else
    -- Plain text
    return width_utils.ensure_exact_width(tostring(line), target_width)
  end
end

-- Extract complex line truncation logic
function M.truncate_complex_line(line, target_width)
  local truncated_line = {}
  local accumulated_width = 0
  
  -- Handle recent files format with preserved key
  local has_key_part = false
  local key_part = nil
  local key_width = 0
  
  if #line > 0 and type(line[#line]) == 'table' and #line[#line] >= 2 then
    local last_text = tostring(line[#line][2] or '')
    if string.match(last_text, '^%[%d+%]$') then
      has_key_part = true
      key_part = line[#line]
      key_width = vim.fn.strwidth(last_text)
    end
  end
  
  local available_width = has_key_part and (target_width - key_width) or target_width
  local parts_to_process = has_key_part and (#line - 1) or #line
  
  for i = 1, parts_to_process do
    local part = line[i]
    if type(part) == 'table' and #part >= 2 then
      local part_text = tostring(part[2] or '')
      local part_width = vim.fn.strwidth(part_text)
      
      if accumulated_width + part_width <= available_width then
        table.insert(truncated_line, part)
        accumulated_width = accumulated_width + part_width
      elseif accumulated_width < available_width then
        local chars_to_take = available_width - accumulated_width
        if chars_to_take > 0 then
          local truncated_text = vim.fn.strpart(part_text, 0, chars_to_take)
          table.insert(truncated_line, {part[1], truncated_text})
        end
        break
      else
        break
      end
    end
  end
  
  if has_key_part then
    table.insert(truncated_line, key_part)
  end
  
  return truncated_line
end

function M.combine_sections_horizontally(sections_content, height)

  for i = 1, height do
    local line_parts = {}
    
    for j, section in ipairs(sections_content) do
      local section_line = section.content[i] or require('luxdash.utils.width').get_padding(section.width)
      section_line = ensure_exact_width(section_line, section.width)
      table.insert(line_parts, section_line)
      
      -- Add spacer between sections (except after the last one)
      if j < #sections_content then
        -- Check if this is an underline row
        local function contains_underline(line)
          if type(line) == 'table' then
            if line[2] and type(line[2]) == 'string' then
              -- Simple format: {highlight, text}
              return string.find(line[2], '─') ~= nil
            elseif #line > 0 and type(line[1]) == 'table' then
              -- Complex format: {{highlight, text}, {highlight, text}, ...}
              for _, part in ipairs(line) do
                if type(part) == 'table' and part[2] and type(part[2]) == 'string' and string.find(part[2], '─') then
                  return true
                end
              end
            end
          elseif type(line) == 'string' then
            return string.find(line, '─') ~= nil
          end
          return false
        end
        
        if contains_underline(section_line) then
          -- Add vertical separator on underline rows
          table.insert(line_parts, {'LuxDashSubSeparator', '│'})
        else
          -- Add spacing on regular content rows
          table.insert(line_parts, require('luxdash.utils.width').get_padding(2))
        end
      end
    end
    
    -- Combine line parts while preserving section boundaries for proper highlighting
    local combined_line = line_utils.combine_line_parts(line_parts)
    dashboard_data.add_line(combined_line)
  end
end

return M