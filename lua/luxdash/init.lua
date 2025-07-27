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
  options = { 'newfile', 'backtrack', 'fzf', 'closelux' },
  extras = {},
  bottom_sections = {'recent_files', 'git_status', 'empty'},
  section_configs = {
    recent_files = { 
      max_files = 10,
      alignment = { 
        horizontal = 'center', 
        vertical = 'center',
        title_horizontal = 'center',
        content_horizontal = 'center'
      },
      title = '󰋚 Recent Files',
      show_title = true
    },
    git_status = {
      alignment = { 
        horizontal = 'center', 
        vertical = 'center',
        title_horizontal = 'center',
        content_horizontal = 'center'
      },
      title = '󰊢 Git Status',
      show_title = true
    },
    empty = {
      alignment = { 
        horizontal = 'center', 
        vertical = 'center'
      }
    }
  },
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

function M.open()
  require('luxdash.core').open()
end

function M.toggle()
  require('luxdash.float').toggle()
end

return M
