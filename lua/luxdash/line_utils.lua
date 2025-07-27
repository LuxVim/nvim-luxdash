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
            table.insert(processed_highlights, {
              start_col = pad_left + hl.start_col,
              end_col = pad_left + hl.end_col,
              hl_group = hl.hl_group
            })
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
              table.insert(processed_highlights, {
                start_col = pad_left + hl.start_col,
                end_col = pad_left + hl.end_col,
                hl_group = hl.hl_group
              })
            end
          end
        end
      end
      
      local padded_text = string.rep(' ', pad_left) .. tostring(text)
      
      if highlight_group and type(highlight_group) == 'string' then
        -- Simple highlight for the entire line
        processed_highlights = {{
          start_col = pad_left,
          end_col = pad_left + vim.fn.strwidth(tostring(text)),
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
  for _, hl in ipairs(highlights) do
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