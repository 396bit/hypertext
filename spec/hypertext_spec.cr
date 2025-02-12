require "spec"
require "../src/hypertext"

describe "Hypertext" do
  it "generates valid html" do
    doc = hypertext! do
      html5 {
        head {
          meta_charset
          meta_viewport
          css_link("style.css")
          inline_style(%{
            body { font-family:sans-serif; }
            .main-section { background: grey; }
          })
          inline_script(%{
            console.log("hallo Welt!");
            alert("WTF");
          })
        }
        body {
          section class: "main-section" {
            h1 { text "HALLO" }
          }
          footer {
            raw "<span>RAW HTML</span>"
          }
        }
      }
    end
    # puts doc
    doc.should eq(%{<!DOCTYPE html><html><head><meta charset="utf8"><meta name="viewport" content="width=device-width, initial-scale=1"><link href="style.css" rel="stylesheet" type="text/css"><style>
            body { font-family:sans-serif; }
            .main-section { background: grey; }
          </style><script>
            console.log("hallo Welt!");
            alert("WTF");
          </script></head><body><section class="main-section"><h1>HALLO</h1></section><footer><span>RAW HTML</span></footer></body></html>})
  end

  it "provides attributes without value" do
    doc = hypertext! do
      div this_is_emitted: true, this_not: false
    end
    # puts doc
    doc.should eq(%{<div this-is-emitted></div>})
  end

  it "supports commponents" do
    doc = hypertext! do
      div class: "wrapper" {
        component
      }
    end
    # puts doc
    doc.should eq(%{<div class="wrapper"><div class="component" hx-get="/some/url">I am a component<br><div class="nested-component">(nested)</div></div></div>})
  end

  it "compacts and joins array attribute values" do
    doc = hypertext! do
      div class: [
        "first",
        ("visible" if true),
        ("invisible" if false),
        "last",
      ]
    end
    # puts doc
    doc.should eq(%{<div class="first visible last"></div>})
  end

  it "omitts nil attributes" do
    doc = hypertext! do
      div omitted: nil
    end
    # puts doc
    doc.should eq(%{<div></div>})
  end

  it "supports select tag" do
    doc = hypertext! do
      div {
        select_tag
      }
    end
    # puts doc
    doc.should eq(%{<div><select></select></div>})
  end
end

def component
  hypertext do
    div(
      class: "component",
      hx_get: "/some/url"
    ) {
      text "I am a component"
      br
      nested_component
    }
  end
end

def nested_component
  hypertext do
    div(
      class: "nested-component",
    ) {
      text "(nested)"
    }
  end
end
