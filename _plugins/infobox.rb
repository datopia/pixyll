class InfoboxTag < Liquid::Block
  def initialize(tag_name, input, tokens)
    super
    @input = input
  end

  def render(context)
    site = context.registers[:site]
    conv = site.find_converter_instance(::Jekyll::Converters::Markdown)
    text = conv.convert(super)
    return %{<div class="infobox">
      <div class="infobox-title">#{@input.strip}</div>
      <p>#{text}</p>
      </div>
    }
  end
end

Liquid::Template.register_tag('infobox', InfoboxTag)
