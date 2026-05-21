local M = {}

local function trim(value)
  return value:match("^%s*(.-)%s*$")
end

local function parse_heading(line)
  local markers, text = line:match("^%s*(#+)%s+(.+)%s*$")
  if not markers then
    return nil
  end

  return {
    type = "heading",
    level = math.min(#markers, 6),
    text = text:gsub("%s+#+%s*$", ""),
  }
end

local function flush_paragraph(slide, paragraph)
  if #paragraph == 0 then
    return
  end

  table.insert(slide.elements, {
    type = "paragraph",
    text = table.concat(paragraph, "\n"),
  })
  for i = #paragraph, 1, -1 do
    paragraph[i] = nil
  end
end

local function add_slide(slides, slide)
  if #slide.elements > 0 then
    table.insert(slides, slide)
  end
end

local function split_table_row(line)
  local content = trim(line)
  content = content:gsub("^|", ""):gsub("|$", "")

  local cells = {}
  for cell in (content .. "|"):gmatch("(.-)|") do
    table.insert(cells, trim(cell))
  end

  return cells
end

local function is_table_separator(line)
  local cells = split_table_row(line)
  if #cells == 0 then
    return false
  end

  for _, cell in ipairs(cells) do
    if not cell:match("^:?-+:?$") then
      return false
    end
  end

  return true
end

local function is_table_start(line, next_line)
  return line:find("|", 1, true) and next_line and is_table_separator(next_line)
end

local function table_alignments(separator)
  local alignments = {}

  for _, cell in ipairs(split_table_row(separator)) do
    if cell:match("^:.*:$") then
      table.insert(alignments, "center")
    elseif cell:match(":$") then
      table.insert(alignments, "right")
    else
      table.insert(alignments, "left")
    end
  end

  return alignments
end

local function table_rows(table_lines)
  local rows = {}

  for index, line in ipairs(table_lines) do
    if index ~= 2 then
      table.insert(rows, split_table_row(line))
    end
  end

  return rows
end

local function pad_cell(text, width, alignment)
  local display_width = vim.fn.strdisplaywidth(text)
  local padding = math.max(width - display_width, 0)

  if alignment == "right" then
    return string.rep(" ", padding) .. text
  elseif alignment == "center" then
    local left = math.floor(padding / 2)
    local right = padding - left
    return string.rep(" ", left) .. text .. string.rep(" ", right)
  end

  return text .. string.rep(" ", padding)
end

local function render_table(element)
  local column_widths = {}

  for _, row in ipairs(element.rows) do
    for index, cell in ipairs(row) do
      column_widths[index] = math.max(column_widths[index] or 0, vim.fn.strdisplaywidth(cell))
    end
  end

  local lines = {}
  for row_index, row in ipairs(element.rows) do
    local rendered_cells = {}
    for index = 1, #column_widths do
      table.insert(rendered_cells, " " .. pad_cell(row[index] or "", column_widths[index], element.alignments[index]) .. " ")
    end

    table.insert(lines, "|" .. table.concat(rendered_cells, "|") .. "|")

    if row_index == 1 then
      local separator_cells = {}
      for _, width in ipairs(column_widths) do
        table.insert(separator_cells, " " .. string.rep("-", width) .. " ")
      end
      table.insert(lines, "|" .. table.concat(separator_cells, "|") .. "|")
    end
  end

  return lines, {}
end

function M.setup(opts)
  require("vimdeck").setup(opts)

  local renderer = require("vimdeck.renderer")
  local render_element = renderer.render_element
  renderer.render_element = function(element, render_opts)
    if element.type == "table" then
      return render_table(element)
    end

    return render_element(element, render_opts)
  end

  local frontmatter = require("vimdeck.frontmatter")
  frontmatter.extract_frontmatter = function(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    if lines[1] ~= "---" then
      return {}, 0
    end

    local frontmatter_lines = {}
    for i = 2, #lines do
      if lines[i] == "---" then
        return frontmatter.parse_yaml(table.concat(frontmatter_lines, "\n")), i
      end
      table.insert(frontmatter_lines, lines[i])
    end

    return {}, 0
  end

  local parser = require("vimdeck.parser")
  parser.parse_slides = function(bufnr, start_line)
    start_line = start_line or 0

    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, -1, false)
    local slides = {}
    local slide = { start_row = start_line, elements = {} }
    local paragraph = {}
    local in_code = false
    local code_lang = "text"
    local code_lines = {}
    local skip_until = 0

    for offset, line in ipairs(lines) do
      local row = start_line + offset - 1

      if offset <= skip_until then
        goto continue
      elseif in_code then
        if line:match("^%s*```") then
          table.insert(slide.elements, {
            type = "code",
            lang = code_lang,
            text = table.concat(code_lines, "\n"),
          })
          in_code = false
          code_lang = "text"
          code_lines = {}
        else
          table.insert(code_lines, line)
        end
      elseif line:match("^%s*[-*_][-_*%s]*$") and line:match("[-*_].*[-*_].*[-*_]") then
        flush_paragraph(slide, paragraph)
        slide.end_row = row - 1
        add_slide(slides, slide)
        slide = { start_row = row + 1, elements = {} }
      elseif line:match("^%s*```") then
        flush_paragraph(slide, paragraph)
        code_lang = line:match("^%s*```%s*([^%s`]*)") or "text"
        if code_lang == "" then
          code_lang = "text"
        end
        in_code = true
      elseif is_table_start(line, lines[offset + 1]) then
        flush_paragraph(slide, paragraph)

        local table_lines = { line, lines[offset + 1] }
        local next_offset = offset + 2
        while lines[next_offset] and lines[next_offset]:find("|", 1, true) and not lines[next_offset]:match("^%s*$") do
          table.insert(table_lines, lines[next_offset])
          next_offset = next_offset + 1
        end

        table.insert(slide.elements, {
          type = "table",
          rows = table_rows(table_lines),
          alignments = table_alignments(table_lines[2]),
          start_row = row,
          end_row = start_line + next_offset - 2,
        })
        skip_until = next_offset - 1
      elseif line:match("^%s*$") then
        flush_paragraph(slide, paragraph)
      else
        local heading = parse_heading(line)
        if heading then
          flush_paragraph(slide, paragraph)
          heading.start_row = row
          heading.end_row = row
          table.insert(slide.elements, heading)
        elseif line:match("^%s*[%-%*%+]%s+") then
          flush_paragraph(slide, paragraph)
          table.insert(slide.elements, {
            type = "list_item",
            text = line:gsub("^%s*[%-%*%+]%s+", ""),
            start_row = row,
            end_row = row,
          })
        elseif line:match("^%s*>%s?") then
          flush_paragraph(slide, paragraph)
          table.insert(slide.elements, {
            type = "quote",
            text = line:gsub("^%s*>%s?", ""),
            start_row = row,
            end_row = row,
          })
        else
          table.insert(paragraph, line)
        end
      end

      ::continue::
    end

    if in_code then
      table.insert(slide.elements, {
        type = "code",
        lang = code_lang,
        text = table.concat(code_lines, "\n"),
      })
    end

    flush_paragraph(slide, paragraph)
    slide.end_row = vim.api.nvim_buf_line_count(bufnr) - 1
    add_slide(slides, slide)

    return slides
  end
end

return M
