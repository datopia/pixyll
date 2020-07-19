class NotParaTag < Liquid::Block
  def render(context)
    site = context.registers[:site]
    conv = site.find_converter_instance(::Jekyll::Converters::Markdown)
    text = conv.convert(super)
    return "<div class=\"notpara\">#{text}</div>"
  end
end

Liquid::Template.register_tag('notpara', NotParaTag)
