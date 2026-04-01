--- @module render
--- HTML and script rendering for particles shortcode output.

local codec = require(quarto.utils.resolve_path("_modules/codec.lua"):gsub("%.lua$", ""))

--- Build the initialization JavaScript for particles.js.
--- @param is_revealjs boolean
--- @return string
local function build_init_js(is_revealjs)
  if is_revealjs then
    return [[
  var initialized = false;
  function tryInit() {
    if (initialized) return;
    var el = document.getElementById(targetId);
    if (!el) return;
    var slide = el.closest('section');
    if (!slide || !slide.classList.contains('present')) return;
    initialized = true;
    window.particlesJS(targetId, config);
  }
  function bindReveal() {
    Reveal.on('ready', tryInit);
    Reveal.on('slidechanged', tryInit);
  }
  if (typeof Reveal !== "undefined") {
    bindReveal();
    if (Reveal.isReady()) { tryInit(); }
  } else {
    document.addEventListener("DOMContentLoaded", function() {
      if (typeof Reveal !== "undefined") { bindReveal(); }
    });
  }]]
  end

  return [[
  function initParticles() {
    window.particlesJS(targetId, config);
  }
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initParticles);
  } else {
    initParticles();
  }]]
end

--- Build full HTML markup for one shortcode instance.
--- @param opts table
--- @param opts.id string
--- @param opts.class_value string
--- @param opts.style string|nil
--- @param opts.config table
--- @param opts.is_revealjs boolean
--- @return string
local function build_html(opts)
  local class_attribute = ' class="' .. codec.escape_attr(opts.class_value) .. '"'

  local style_attribute = ""
  if opts.style and opts.style ~= "" then
    style_attribute = ' style="' .. codec.escape_attr(opts.style) .. '"'
  end

  local config_json = codec.json_encode(opts.config)
  local init_js = build_init_js(opts.is_revealjs)

  return string.format([[<div id="%s"%s%s></div>
<script>
(function(){
  var targetId = %s;
  var config = %s;
%s
})();
</script>]],
    codec.escape_attr(opts.id),
    class_attribute,
    style_attribute,
    codec.json_encode(opts.id),
    config_json,
    init_js
  )
end

return {
  build_html = build_html
}
