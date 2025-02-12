require "./hypertext"

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
