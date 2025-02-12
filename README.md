# hypertext

A lightweight [crystal](https://crystal-lang.org) library for composing html.

Hypertext internally wraps around a `String::Builder and offers a DSL to emit HTML elements ([see Usage below](#usage)).
Hypertext attaches its current output context to the local fiber, so that one can call other
hypertext emitting code (AKA partials or components) for composition.

It does not create any kind of intermediate model or DOM representation, it is just a very lightweight serializer.


## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     hypertext:
       github: 396bit/hypertext
   ```

2. Run `shards install`

## Usage

```crystal
require "hypertext"

# compose html string ...
def create_html : String
  hypertext! do 
    html5 {
      head {
        meta_charset
        css_link("style.css")
        title { text("page title") }
      }
      body {
        section(class: "head") {
          h1 { text("Here is your form ...") }
        }
        section(class: "main") {
          # include partial content defined somewhere else
          my_form_component("/action/url", active: false)
        }
      }
    }
  end
end

# define arbitrary partials ...
# note the hypertext without exclamation mark reusing (emitting into) 
# an eventually already existing fiber local hypertext stream context
def my_form_component(url, active)
  hypertext do 
    form(method: "POST", action: url){
      input(type: "text", name: "name")
      input(type: "checkbox", checked: false)
      button(type: "submit", class: ["button", ("greyed" if !active)]) { text("send") }
    }
  end
end

puts create_html
```

## Contributing

1. Fork it (<https://github.com/396bit/hypertext/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Daniel](https://github.com/396bit) - creator and maintainer
