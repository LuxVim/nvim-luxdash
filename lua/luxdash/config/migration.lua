local M = {}

function M.migrate_legacy_config(config)
  -- Handle legacy bottom_sections
  if config.bottom_sections then
    local new_bottom = {}
    for i, section_name in ipairs(config.bottom_sections) do
      local section_config = config.section_configs and config.section_configs[section_name] or {}
      
      -- Create new section format
      local new_section = {
        id = section_name,
        type = section_name,
        title = section_config.title or M.get_default_title(section_name),
        config = vim.tbl_deep_extend('force', {
          show_title = section_config.show_title ~= false,
          show_underline = section_config.show_underline ~= false,
          alignment = section_config.alignment or {
            horizontal = 'center',
            vertical = 'top',
            title_horizontal = 'center',
            content_horizontal = 'center'
          },
          padding = section_config.padding or { left = 2, right = 2 }
        }, section_config)
      }
      
      -- Add section-specific configs
      if section_name == 'menu' then
        new_section.config.menu_items = config.options
        new_section.config.extras = config.extras
      elseif section_name == 'recent_files' then
        new_section.config.max_files = section_config.max_files or 10
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
      if section.type == 'menu' and not section.config.menu_items then
        section.config.menu_items = config.options
        section.config.extras = config.extras
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