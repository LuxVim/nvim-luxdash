local M = {}

-- Configuration schema definition
local schema = {
  name = {
    type = 'string',
    default = 'LuxDash',
    description = 'Dashboard name'
  },
  logo = {
    type = 'table',
    required = true,
    description = 'Logo lines array'
  },
  logo_color = {
    type = 'table',
    description = 'Logo color configuration',
    schema = {
      preset = {
        type = 'string',
        enum = { 'blue', 'green', 'red', 'yellow', 'purple', 'orange', 'pink', 'cyan' },
        description = 'Preset color scheme'
      },
      row_gradient = {
        type = 'table',
        description = 'Row-based gradient',
        schema = {
          start = { type = 'string', pattern = '^#%x%x%x%x%x%x$', description = 'Start color (hex)' },
          bottom = { type = 'string', pattern = '^#%x%x%x%x%x%x$', description = 'Bottom color (hex)' }
        }
      },
      gradient = {
        type = 'table',
        description = 'Column-based gradient',
        schema = {
          top = { type = 'string', pattern = '^#%x%x%x%x%x%x$', description = 'Top color (hex)' },
          bottom = { type = 'string', pattern = '^#%x%x%x%x%x%x$', description = 'Bottom color (hex)' }
        }
      }
    }
  },
  sections = {
    type = 'table',
    required = true,
    description = 'Dashboard sections configuration',
    schema = {
      main = {
        type = 'table',
        description = 'Main section configuration'
      },
      bottom = {
        type = 'table',
        is_array = true,
        description = 'Bottom sections array'
      }
    }
  },
  layout_config = {
    type = 'table',
    description = 'Layout configuration',
    schema = {
      main_ratio = { type = 'number', min = 0, max = 1, description = 'Main section height ratio' },
      padding = {
        type = 'table',
        description = 'Padding configuration',
        schema = {
          top = { type = 'number', min = 0, description = 'Top padding' },
          bottom = { type = 'number', min = 0, description = 'Bottom padding' },
          left = { type = 'number', min = 0, description = 'Left padding' },
          right = { type = 'number', min = 0, description = 'Right padding' }
        }
      }
    }
  },
  hide_buffer = {
    type = 'boolean',
    default = false,
    description = 'Hide buffer when dashboard is closed'
  },
  padding = {
    type = 'table',
    description = 'Buffer padding configuration',
    schema = {
      top = { type = 'number', min = 0, description = 'Top padding' },
      bottom = { type = 'number', min = 0, description = 'Bottom padding' },
      left = { type = 'number', min = 0, description = 'Left padding' },
      right = { type = 'number', min = 0, description = 'Right padding' }
    }
  },
  float = {
    -- Can be table with config options
    description = 'Floating window configuration'
  },
  layout = {
    -- Can be string (legacy: 'horizontal') or table
    description = 'Layout configuration (legacy)'
  },
  performance = {
    -- Can be table with performance settings
    description = 'Performance optimization settings'
  }
}

---Validate a value against a schema specification
---@param value any Value to validate
---@param spec table Schema specification
---@param path string Path for error messages
---@param errors table Array to collect errors
local function validate_value(value, spec, path, errors)
  -- Check required fields
  if spec.required and value == nil then
    table.insert(errors, {
      path = path,
      message = string.format('%s is required', path),
      severity = 'error'
    })
    return
  end

  -- Skip validation if value is nil and not required
  if value == nil then
    return
  end

  -- Type validation
  if spec.type and type(value) ~= spec.type then
    table.insert(errors, {
      path = path,
      message = string.format('%s must be %s, got %s', path, spec.type, type(value)),
      severity = 'error'
    })
    return
  end

  -- Enum validation
  if spec.enum and type(value) == 'string' then
    local valid = false
    for _, allowed in ipairs(spec.enum) do
      if value == allowed then
        valid = true
        break
      end
    end
    if not valid then
      table.insert(errors, {
        path = path,
        message = string.format('%s must be one of: %s, got "%s"',
          path, table.concat(spec.enum, ', '), value),
        severity = 'error'
      })
    end
  end

  -- Pattern validation
  if spec.pattern and type(value) == 'string' then
    if not value:match(spec.pattern) then
      table.insert(errors, {
        path = path,
        message = string.format('%s does not match pattern %s', path, spec.pattern),
        severity = 'error'
      })
    end
  end

  -- Number range validation
  if type(value) == 'number' then
    if spec.min and value < spec.min then
      table.insert(errors, {
        path = path,
        message = string.format('%s must be >= %s, got %s', path, spec.min, value),
        severity = 'error'
      })
    end
    if spec.max and value > spec.max then
      table.insert(errors, {
        path = path,
        message = string.format('%s must be <= %s, got %s', path, spec.max, value),
        severity = 'error'
      })
    end
  end

  -- Nested schema validation
  if spec.schema and type(value) == 'table' then
    if spec.is_array then
      -- Validate array elements
      for i, item in ipairs(value) do
        local item_path = string.format('%s[%d]', path, i)
        -- Arrays can have mixed types, just validate they exist
        if type(item) ~= 'table' then
          table.insert(errors, {
            path = item_path,
            message = string.format('%s must be a table', item_path),
            severity = 'warning'
          })
        end
      end
    else
      -- Validate nested object
      for key, subspec in pairs(spec.schema) do
        local subpath = path .. '.' .. key
        validate_value(value[key], subspec, subpath, errors)
      end
    end
  end
end

---Validate configuration against schema
---@param config table Configuration to validate
---@return boolean valid True if configuration is valid
---@return table errors Array of error objects {path, message, severity}
function M.validate(config)
  local errors = {}

  if type(config) ~= 'table' then
    table.insert(errors, {
      path = 'config',
      message = 'Configuration must be a table',
      severity = 'error'
    })
    return false, errors
  end

  -- Validate against schema
  for key, spec in pairs(schema) do
    validate_value(config[key], spec, key, errors)
  end

  -- Check for unknown keys (warnings only)
  for key, _ in pairs(config) do
    if not schema[key] then
      table.insert(errors, {
        path = key,
        message = string.format('Unknown configuration key: %s', key),
        severity = 'warning'
      })
    end
  end

  -- Separate errors from warnings
  local has_errors = false
  for _, err in ipairs(errors) do
    if err.severity == 'error' then
      has_errors = true
      break
    end
  end

  return not has_errors, errors
end

---Format validation errors for display
---@param errors table Array of error objects
---@return string formatted Formatted error message
function M.format_errors(errors)
  if #errors == 0 then
    return 'No errors'
  end

  local parts = { 'LuxDash configuration validation failed:\n' }

  local error_count = 0
  local warning_count = 0

  for _, err in ipairs(errors) do
    local prefix = err.severity == 'error' and '  [ERROR]' or '  [WARNING]'
    table.insert(parts, string.format('%s %s: %s', prefix, err.path, err.message))

    if err.severity == 'error' then
      error_count = error_count + 1
    else
      warning_count = warning_count + 1
    end
  end

  table.insert(parts, 1, string.format('Found %d errors, %d warnings:', error_count, warning_count))

  return table.concat(parts, '\n')
end

---Apply defaults from schema to configuration
---@param config table Configuration to apply defaults to
---@return table config Configuration with defaults applied
function M.apply_defaults(config)
  config = config or {}

  for key, spec in pairs(schema) do
    if config[key] == nil and spec.default ~= nil then
      config[key] = spec.default
    end
  end

  return config
end

---Get schema for documentation/introspection
---@return table schema The configuration schema
function M.get_schema()
  return vim.deepcopy(schema)
end

return M
