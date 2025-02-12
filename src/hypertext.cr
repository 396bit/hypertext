require "html"
require "./ext/fiber"

# Enter a DSL context for generating a HTML string.
# The given block is yielded with a `Hypertext` instance (`with Hypertext.new() yield`)
# wrapped around a `String::Builder` and returns the generated HTML.
# The Hypertext instance is attached to the current `Fiber`, so that calling code
# from within the block can call `hypertext` as well and hence add to the generated HTML.
# Returns the generated HTML String.
def hypertext!(&) : String
  String.build do |io|
    hyper = Hypertext.new(io)
    begin
      Fiber.current.hypertext.push hyper
      with hyper yield
    ensure
      Fiber.current.hypertext.pop
    end
  end
end

# See `hypertext!` but instead of always creating a new Hypertext context, it reuses
# an eventually alreading existing `::Fiber` local one.
# It only returs the generated HTML if it started a fresh Hypertext context. It returns
# nil if it contributed to an already established one (like when used for a partial or component).
def hypertext(&) : String?
  if hyper = Fiber.current.hypertext.last?
    with hyper yield
    nil
  else
    String.build do |io|
      hyper = Hypertext.new(io)
      begin
        Fiber.current.hypertext.push hyper
        with hyper yield
      ensure
        Fiber.current.hypertext.pop
      end
    end
  end
end

# Hypertext is a wrapper around an output stream
# providing a DSL (methods) to generate html.
class Hypertext
  # Dont use this class directly, use the global `::hypertext!` and `.hypertext` methods instead.
  def initialize(@io : IO)
  end

  # call block in the context of this hypertext
  # def render(&)
  #   with self yield
  # end

  # emit (escaped!) text
  def text(s)
    HTML.escape(s.to_s, @io)
  end

  # emit raw text (unescaped as it is)
  def raw(s)
    s.to_s @io
  end

  # generic helper for emitting a markup element / tag.
  protected def create_tag(name : String, attrs : NamedTuple, selfclosing = false, &)
    @io << "<" << name
    if !attrs.empty?
      attrs.each do |name, value|
        # attribute names get underscores translated into hyphens
        name = name.to_s.gsub('_', "-")
        case value
        when Bool
          # a boolean attribute is an empty attribute
          # which only appears if value is true
          # like in <input disabled>
          if value
            @io << " " << name
          end
        when Array
          # an array attribute value
          # gets compacted (nil values removed) then the remaining
          # items are turned into strings and concatenated by whitespace
          @io << " " << name << "=\""
          HTML.escape(value.compact.join(" "), @io)
          @io << "\""
        when Nil
          # an attribute with nil value is silently omitted
        else
          # all other attribute values are turned into strings
          @io << " " << name << "=\""
          HTML.escape(value.to_s, @io)
          @io << "\""
        end
      end
    end
    @io << ">"
    unless selfclosing
      with self yield
      @io << "</" << name << ">"
    end
    nil
  end

  # :ditto:
  protected def create_tag(tag_name : String, attrs : NamedTuple, selfclosing = false)
    create_tag(tag_name, attrs, selfclosing) { }
  end

  # MACRO code for generating all non self closing standard HTML tags ...
  {% for tag in %w(a abbr address article aside b bdi body button code
                  details dialog div dd dl dt em fieldset figcaption figure footer form
                  h1 h2 h3 h4 h5 h6 head header html i iframe label li
                  main mark menuitem meter nav ol option p pre progress rp rt ruby
                  s script section select small span strong style summary
                  table tbody td textarea th thead time title tr u ul video wbr) %}
    {% method_name = tag.id %}
    {% if method_name == "select" %}
      {% method_name = "select_tag" %}
    {% end %}

    # emits `<{{tag.id}}>` element 
    def {{method_name.id}}(**attrs)
      create_tag({{tag}}, attrs)
    end
    # :ditto:
    def {{method_name.id}}(**attrs, &block)
      create_tag({{tag}}, attrs) do
        with self yield 
      end
    end
  {% end %}

  # MACRO code for generating all self closing standard HTML tags ...
  {% for tag in %w(area base br col embed hr img input keygen link menuitem meta
                  param source track wbr) %}
    # emits `<{{tag.id}}>` elment 
    def {{tag.id}}(**attrs)
      create_tag({{tag}}, attrs, true)
    end
  {% end %}

  # like `html` but prefixed with `<!DOCTYPE html>`
  def html5(**attrs, &block)
    @io << "<!DOCTYPE html>"
    html(**attrs) do
      with self yield
    end
  end

  # sugar for: `<meta charset="utf8">`
  def meta_charset(charset = "utf8")
    meta charset: charset
  end

  # sugar for: `<meta name="viewport" content="...">`
  def meta_viewport(content = "width=device-width, initial-scale=1")
    meta name: "viewport", content: content
  end

  # sugar for: `<link href="..." rel="stylesheet" type="text/css">`
  def css_link(href)
    link(href: href.to_s, rel: "stylesheet", type: "text/css")
  end

  # sugar for: `<style>...</style>`
  def inline_style(css)
    style { raw css.to_s }
  end

  # sugar for: `<script>...</script>`
  def inline_script(js)
    script { raw js.to_s }
  end
end
