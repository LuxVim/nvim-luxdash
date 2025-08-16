local M = {}

function M.migrate_legacy_config(config)
  -- Handle legacy bottom_sections
  if config.bottom_sections then
    local new_bottom = {}
    for i, section_name in ipairs(config.bottom_sections) do
      local section_config = config.section_configs and config.section_configs[section_name] or {}
      
      -- Create new section format with flat structure
      local new_section = {
        id = section_name,
        type = section_name,
        title = section_config.title or M.get_default_title(section_name),
        show_title = section_config.show_title ~= false,
        show_underline = section_config.show_underline ~= false,
        content_align = section_config.content_align or (section_config.alignment and section_config.alignment.content_horizontal) or 'center',
        padding = section_config.padding or { left = 2, right = 2 }
      }
      
      -- Add section-specific configs to flat structure
      if section_name == 'menu' then
        new_section.menu_items = config.options
        new_section.extras = config.extras
      elseif section_name == 'recent_files' then
        new_section.max_files = section_config.max_files or 10
      end
      
      table.insert(new_bottom, new_section)
    end
    
    config.sections.bottom = new_bottom
    -- Clear legacy config
    config.bottom_sections = nil
  end
  
  -- Handle legacy menu config for actions section
  if config.sections.bottom then
    for _, section in ipairs(config.sections.bottom) do
      if section.type == 'menu' and not section.menu_items then
        section.menu_items = config.options
        section.extras = config.extras
      end
    end
  end
  
  return config
end

function M.get_default_title(section_name)
  local titles = {
    menu = 'Actions',
    recent_files = '󰋚 Recent Files',
    git_status = '󰊢 Git Status',
    empty = ''
  }
  return titles[section_name] or section_name:gsub('_', ' '):gsub('%w+', function(w) 
    return w:sub(1,1):upper()..w:sub(2) 
  end)
end

return M