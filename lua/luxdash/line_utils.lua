local M = {}

function M.combine_line_parts(parts)
  local combined_text = ''
  local highlights = {}
  local col_offset = 0
  
  for _, part in ipairs(parts) do
    if type(part) == 'table' then
      if #part >= 2 and type(part[1]) == 'string' then
        -- Simple format: {highlight, text}
        local part_text = tostring(part[2] or '')
        local part_hl = part[1]
        
        combined_text = combined_text .. part_text
        
        if part_hl and type(part_hl) == 'string' then
          table.insert(highlights, {
            hl_group = part_hl,
            start_col = col_offset,
            end_col = col_offset + vim.fn.strwidth(part_text)
          })
        end
        
        col_offset = col_offset + vim.fn.strwidth(part_text)
      elseif #part > 0 and type(part[1]) == 'table' then
        -- Complex format: {{highlight, text}, {highlight, text}, ...}
        for _, subpart in ipairs(part) do
          if type(subpart) == 'table' and #subpart >= 2 then
            local subpart_text = tostring(subpart[2] or '')
            local subpart_hl = subpart[1]
            
            combined_text = combined_text .. subpart_text
            
            if subpart_hl and type(subpart_hl) == 'string' then
              table.insert(highlights, {
                hl_group = subpart_hl,
                start_col = col_offset,
                end_col = col_offset + vim.fn.strwidth(subpart_text)
              })
            end
            
            col_offset = col_offset + vim.fn.strwidth(subpart_text)
          end
        end
      end
    else
      -- Plain text
      local part_text = tostring(part)
      combined_text = combined_text .. part_text
      col_offset = col_offset + vim.fn.strwidth(part_text)
    end
  end
  
  if #highlights > 0 then
    return {combined_text, highlights}
  else
    return combined_text
  end
end

function M.process_line_for_rendering(line, pad_left)
  if type(line) == 'table' then
    -- Check if it's a complex multi-highlight structure
    if #line > 0 and type(line[1]) == 'table' then
      -- Complex format: {{highlight, text}, {highlight, text}, ...}
      local combined = M.combine_line_parts({line})
      local text = combined[1] or combined
      local highlights = type(combined) == 'table' and combined[2] or {}
      local padded_text = string.rep(' ', pad_left) .. text
      
      local processed_highlights = {}
      if type(highlights) == 'table' then
        for _, hl in ipairs(highlights) do
          if hl.hl_group and type(hl.hl_group) == 'string' then
            local adjusted_end_col = pad_left + hl.end_col
            table.insert(processed_highlights, {
              start_col = pad_left + hl.start_col,
              end_col = adjusted_end_col,
              hl_group = hl.hl_group
            })
            
            -- For logo highlights, ensure buffer line supports the highlight width
            if hl.hl_group:match('^LuxDashLogo') then
              local current_padded_width = vim.fn.strwidth(padded_text)
              if current_padded_width < adjusted_end_col then
                local extra_spaces = adjusted_end_col - current_padded_width
                padded_text = padded_text .. string.rep(' ', extra_spaces)
              end
            end
          end
        end
      end
      
      return padded_text, processed_highlights
    elseif line[2] then
      -- Detect format: {highlight, text} vs {text, highlights}
      local text, highlight_group, processed_highlights
      if type(line[1]) == 'string' and type(line[2]) == 'string' then
        -- Format: {highlight, text}
        highlight_group = line[1]
        text = line[2]
      else
        -- Format: {text, highlights}
        text = line[1]
        local highlights = line[2]
        if type(highlights) == 'table' then
          processed_highlights = {}
          for _, hl in ipairs(highlights) do
            if hl.hl_group and type(hl.hl_group) == 'string' then
              local adjusted_end_col = pad_left + hl.end_col
              table.insert(processed_highlights, {
                start_col = pad_left + hl.start_col,
                end_col = adjusted_end_col,
                hl_group = hl.hl_group
              })
            end
          end
        end
      end
      
      local padded_text = string.rep(' ', pad_left) .. tostring(text)
      
      -- For logo highlights in processed_highlights, ensure buffer line supports full width
      if processed_highlights then
        for _, hl in ipairs(processed_highlights) do
          if hl.hl_group and hl.hl_group:match('^LuxDashLogo') then
            local current_padded_width = vim.fn.strwidth(padded_text)
            if current_padded_width < hl.end_col then
              local extra_spaces = hl.end_col - current_padded_width
              padded_text = padded_text .. string.rep(' ', extra_spaces)
            end
          end
        end
      end
      
      if highlight_group and type(highlight_group) == 'string' then
        local text_width = vim.fn.strwidth(tostring(text))
        local end_col = pad_left + text_width
        
        -- For logo highlights, make sure the buffer line supports the full highlight width
        if highlight_group:match('^LuxDashLogo') then
          -- Ensure the padded text is at least as long as the highlight end column
          local current_padded_width = vim.fn.strwidth(padded_text)
          if current_padded_width < end_col then
            local extra_spaces = end_col - current_padded_width
            padded_text = padded_text .. string.rep(' ', extra_spaces)
          end
        end
        
        processed_highlights = {{
          start_col = pad_left,
          end_col = end_col,
          hl_group = highlight_group
        }}
      end
      
      return padded_text, processed_highlights or {}
    else
      -- Fallback to string representation
      local line_text = tostring(line)
      return string.rep(' ', pad_left) .. line_text, {}
    end
  else
    local line_text = tostring(line or '')
    return string.rep(' ', pad_left) .. line_text, {}
  end
end

function M.apply_highlights(highlights, lines)
  -- Sort highlights by priority (logo highlights first to ensure they're not overridden)
  local sorted_highlights = {}
  for _, hl in ipairs(highlights) do
    table.insert(sorted_highlights, hl)
  end
  
  table.sort(sorted_highlights, function(a, b)
    -- Logo highlights get priority over menu highlights
    local a_is_logo = a.hl_group and a.hl_group:match('^LuxDashLogo') ~= nil
    local b_is_logo = b.hl_group and b.hl_group:match('^LuxDashLogo') ~= nil
    
    if a_is_logo and not b_is_logo then
      return false  -- Apply logo highlights after menu highlights so they take precedence
    elseif not a_is_logo and b_is_logo then
      return true   -- Apply menu highlights first
    else
      return false  -- Same priority, maintain order
    end
  end)
  
  for _, hl in ipairs(sorted_highlights) do
    -- Validate highlight bounds
    local line_idx = hl.line_num - 1
    if line_idx >= 0 and line_idx < #lines then
      local line_text = lines[line_idx + 1] or ''
      local line_length = vim.fn.strwidth(line_text)
      local start_col = math.max(0, math.min(hl.start_col, line_length))
      local end_col = math.max(start_col, math.min(hl.end_col, line_length))
      
      if start_col < end_col then
        vim.api.nvim_buf_add_highlight(0, -1, hl.hl_group, line_idx, start_col, end_col)
      end
    end
  end
end

return M