--- @module particles
--- @license MIT
--- Quarto shortcode entrypoint for particles.js backgrounds.

local defaults = require(quarto.utils.resolve_path("_modules/defaults.lua"):gsub("%.lua$", ""))
local codec = require(quarto.utils.resolve_path("_modules/codec.lua"):gsub("%.lua$", ""))
local cfg = require(quarto.utils.resolve_path("_modules/config.lua"):gsub("%.lua$", ""))
local render = require(quarto.utils.resolve_path("_modules/render.lua"):gsub("%.lua$", ""))

local instance_counter = 0

--- Register extension HTML dependencies.
local function add_html_dependencies()
  quarto.doc.add_html_dependency({
    name = "particles",
    scripts = { "assets/js/particles.min.js" },
    stylesheets = { "particles.css" }
  })
end

--- Parse optional inline style keyword value.
--- @param kwargs table
--- @return string|nil
local function get_style(kwargs)
  local style = codec.get_kwarg(kwargs, "style")
  if style == "" then
    return nil
  end
  return style
end

--- Render one particles shortcode instance.
--- @param args table|nil
--- @param kwargs table|nil
--- @return pandoc.RawBlock
local function particles(args, kwargs)
  kwargs = kwargs or {}
  instance_counter = instance_counter + 1

  local is_revealjs_format = quarto.doc.is_format("revealjs")
  if quarto.doc.is_format("html") or is_revealjs_format then
    add_html_dependencies()
  end

  local id = codec.get_kwarg(kwargs, "id") or ("quarto-particles-js-" .. instance_counter)
  local class_attr = codec.get_kwarg(kwargs, "class")
  local config = cfg.build(defaults.DEFAULT_CONFIG, kwargs, args, defaults.RESERVED_KEYS)

  local class_value = "quarto-particles-js"
  if is_revealjs_format then
    class_value = class_value .. " quarto-particles-revealjs"
  end
  if class_attr and class_attr ~= "" then
    class_value = class_value .. " " .. class_attr
  end
  class_value = class_value .. " " .. id

  local html = render.build_html({
    id = id,
    class_value = class_value,
    style = get_style(kwargs),
    config = config,
    is_revealjs = is_revealjs_format
  })

  return pandoc.RawBlock("html", html)
end

return {
  particles = particles
}
