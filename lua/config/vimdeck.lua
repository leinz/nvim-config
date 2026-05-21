local M = {}

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

function M.setup(opts)
  require("vimdeck").setup(opts)

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

    for offset, line in ipairs(lines) do
      local row = start_line + offset - 1

      if in_code then
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
