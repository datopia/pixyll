class QuoteTag < Liquid::Block
  def initialize(tag_name, input, tokens)
    super
    @input = input
    @tag_name = tag_name
  end

  def render(context)
    text = super
    cls = @tag_name == 'quote' ? '' : ' left'
    title, url = @input.split('|')
    return %{<blockquote class="literal quote-plugin #{cls}">
    &ldquo;#{text.strip}&rdquo;
    <div class="attrib">&mdash; <a href="#{url}">#{title}</a></div>
    </blockquote>
    }
  end
end

Liquid::Template.register_tag('quote',     QuoteTag)
Liquid::Template.register_tag('quote_left', QuoteTag)
