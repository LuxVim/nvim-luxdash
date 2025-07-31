local M = {}

-- Track window dimensions globally
local win_dimensions = {}

M.config = {
  name = 'LuxDash',
  layout = 'horizontal',
  logo = {
    '',
    '⢠⣤⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣤⣤⣤⣤⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠛⠛⠛⠻⢿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⣿⣿⠀⠀⠀⠀⠀⠀⠀',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠈⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⣿⣿⠀⠀⠀⠀⠀⠀⠀',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠈⣿⣿⡀⠀⠀⠀⣰⣿⡿⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠈⣿⣿⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣤⠀⠀⠀⠀⣿⣿⣴⣿⣿⣿⣿⣶⠀',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠈⣿⣿⡀⠀⣰⣿⡟⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⣾⣿⠋⠀⠀⠀⠙⣿⣷⠀⠀⠀⣿⣿⠁⠀⠀⠀⠻⣿⣧⠀⠀⠀⣿⣿⠋⠀⠀⠀⠙⣿⣷',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⢿⣿⣴⣿⠟⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⣏⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⢀⣴⣿⣿⠿⠿⠿⣿⣿⠀⠀⠀⠀⠛⠿⣿⣿⣷⣦⣀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣾⣿⠻⣿⣆⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⣸⣿⡟⠀⠀⠀⣿⣿⠁⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣧⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡀⠀⠀⠀⢀⣿⣿⠀⠀⠀⠀⣾⣿⠃⠀⠻⣿⣦⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⣀⣴⣿⡟⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⣠⣿⣿⠀⠀⠘⣿⣷⠀⠀⠀⠀⢀⣿⣿⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠈⣿⣿⣷⣶⣿⣿⢿⣿⠀⠀⢀⣿⣿⠃⠀⠀⠀⠹⣿⣧⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠹⣿⣿⣶⣶⣿⠿⣿⣿⠀⠀⠀⠙⣿⣿⣶⣶⣾⣿⡿⠁⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⣿⣿',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '',
  },
  logo_color = {
    preset = nil,
    gradient = nil
  },
  -- Legacy options for menu section - kept for backward compatibility
  options = { 'newfile', 'backtrack', 'fzf', 'closelux' },
  extras = {},
  
  -- New modular section configuration
  sections = {
    -- Main section (logo area)
    main = {
      type = 'logo',
      config = {
        title = nil,
        show_title = false,
        show_underline = false,
        alignment = {
          horizontal = 'center',
          vertical = 'center'
        }
      }
    },
    -- Dynamic bottom sections
    bottom = {
      {
        id = 'actions',
        type = 'menu',
        title = 'Actions',
        config = {
          show_title = true,
          show_underline = true,
          alignment = {
            horizontal = 'center',
            vertical = 'top',
            title_horizontal = 'center',
            content_horizontal = 'center'
          },
          padding = { left = 2, right = 2 },
          -- Menu-specific config
          menu_items = nil, -- Will use options/extras for backward compatibility
          extras = nil
        }
      },
      {
        id = 'recent_files',
        type = 'recent_files',
        title = '󰋚 Recent Files',
        config = {
          show_title = true,
          show_underline = true,
          alignment = {
            horizontal = 'center',
            vertical = 'top',
            title_horizontal = 'center',
            content_horizontal = 'left'
          },
          padding = { left = 2, right = 2 },
          -- Recent files specific config
          max_files = 10
        }
      },
      {
        id = 'git_status',
        type = 'git_status',
        title = '󰊢 Git Status',
        config = {
          show_title = true,
          show_underline = true,
          alignment = {
            horizontal = 'center',
            vertical = 'top',
            title_horizontal = 'center',
            content_horizontal = 'left'
          },
          padding = { left = 2, right = 2 }
        }
      }
    }
  },
  
  -- Layout configuration
  layout_config = {
    main_height_ratio = 0.8, -- Main section takes 80% of height
    bottom_sections_equal_width = true, -- Equal width for bottom sections
    section_spacing = 4 -- Total spacing between sections
  },
  
  -- Legacy configs - kept for backward compatibility
  section_configs = {},
  alignment = {
    logo = { horizontal = 'center', vertical = 'center' },
    menu = { horizontal = 'center', vertical = 'center' }
  },
  float = {
    width = 0.9,
    height = 0.9,
    border = 'rounded',
    title = ' LuxDash ',
    title_pos = 'center',
    hide_buffer = false
  },
  padding = {
    left = 2,
    right = 2,
    top = 1,
    bottom = 1
  }
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  -- Migrate legacy configuration to new format if needed
  M.migrate_legacy_config()
  
  -- Setup highlights
  local highlights = require('luxdash.highlights')
  highlights.setup()
  
  local float = require('luxdash.float')
  float.setup(M.config.float or {})
  
  vim.api.nvim_create_user_command('LuxDash', function()
    float.toggle()
  end, { desc = 'Toggle LuxDash floating window' })
  
  local group = vim.api.nvim_create_augroup('LuxDash', { clear = true })
  
    vim.api.nvim_create_autocmd('VimEnter', {
        group = group,
        callback = function()
            if vim.fn.argc() == 0 then
                M.open()
            end
        end
    })
  
    vim.api.nvim_create_autocmd('VimResized', {
        group = group,
        callback = function()
            require('luxdash.core').resize()
        end
    })
  
  -- Track window size changes for luxdash buffers
  local function check_and_resize_luxdash()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'luxdash' then
      local winnr = vim.api.nvim_get_current_win()
      local width = vim.api.nvim_win_get_width(winnr)
      local height = vim.api.nvim_win_get_height(winnr)
      local key = winnr .. '_' .. bufnr
      
      if not win_dimensions[key] or 
         win_dimensions[key].width ~= width or 
         win_dimensions[key].height ~= height then
        
        win_dimensions[key] = {width = width, height = height}
        require('luxdash.core').resize()
      end
    end
  end
  
  vim.api.nvim_create_autocmd({'WinEnter', 'BufWinEnter'}, {
    group = group,
    callback = check_and_resize_luxdash
  })
  
  -- Also check on window leave to catch nvim-tree toggles
  vim.api.nvim_create_autocmd('WinLeave', {
    group = group,
    callback = function()
      -- Delay check to allow window operations to complete
      vim.defer_fn(function()
        for _, winnr in ipairs(vim.api.nvim_list_wins()) do
          local bufnr = vim.api.nvim_win_get_buf(winnr)
          if vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'luxdash' then
            local width = vim.api.nvim_win_get_width(winnr)
            local height = vim.api.nvim_win_get_height(winnr)
            local key = winnr .. '_' .. bufnr
            
            if not win_dimensions[key] or 
               win_dimensions[key].width ~= width or 
               win_dimensions[key].height ~= height then
              
              win_dimensions[key] = {width = width, height = height}
              local current_win = vim.api.nvim_get_current_win()
              vim.api.nvim_set_current_win(winnr)
              require('luxdash.core').resize()
              vim.api.nvim_set_current_win(current_win)
            end
          end
        end
      end, 10)
    end
  })
end

-- Migrate legacy configuration to new modular format
function M.migrate_legacy_config()
  -- Handle legacy bottom_sections
  if M.config.bottom_sections then
    local new_bottom = {}
    for i, section_name in ipairs(M.config.bottom_sections) do
      local section_config = M.config.section_configs and M.config.section_configs[section_name] or {}
      
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
        new_section.config.menu_items = M.config.options
        new_section.config.extras = M.config.extras
      elseif section_name == 'recent_files' then
        new_section.config.max_files = section_config.max_files or 10
      end
      
      table.insert(new_bottom, new_section)
    end
    
    M.config.sections.bottom = new_bottom
    -- Clear legacy config
    M.config.bottom_sections = nil
  end
  
  -- Handle legacy menu config for actions section
  if M.config.sections.bottom then
    for _, section in ipairs(M.config.sections.bottom) do
      if section.type == 'menu' and not section.config.menu_items then
        section.config.menu_items = M.config.options
        section.config.extras = M.config.extras
      end
    end
  end
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

function M.open()
    require('luxdash.core').open()
end

function M.toggle()
    require('luxdash.float').toggle()
end

return M