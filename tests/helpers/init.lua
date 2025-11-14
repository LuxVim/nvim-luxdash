-- Test helpers for nvim-luxdash
local M = {}

-- Add the plugin to runtimepath for testing
function M.setup_plugin()
  local plugin_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ':p:h:h:h')
  vim.opt.runtimepath:append(plugin_path)
end

-- Create a minimal test configuration
function M.get_test_config()
  return {
    name = 'TestDash',
    logo = {
      '',
      'Test Logo',
      '',
    },
    sections = {
      main = {
        type = 'logo',
      },
      bottom = {}
    },
    float = {
      width = 0.8,
      height = 0.8,
      border = 'rounded',
    }
  }
end

-- Assert helpers
function M.assert_equals(actual, expected, message)
  if actual ~= expected then
    error(string.format(
      '%s\nExpected: %s\nActual: %s',
      message or 'Assertion failed',
      vim.inspect(expected),
      vim.inspect(actual)
    ))
  end
end

function M.assert_not_nil(value, message)
  if value == nil then
    error(message or 'Expected non-nil value')
  end
end

function M.assert_nil(value, message)
  if value ~= nil then
    error(message or 'Expected nil value, got: ' .. vim.inspect(value))
  end
end

function M.assert_true(value, message)
  if not value then
    error(message or 'Expected true, got false')
  end
end

function M.assert_false(value, message)
  if value then
    error(message or 'Expected false, got true')
  end
end

return M
