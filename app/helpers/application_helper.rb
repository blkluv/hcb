module ApplicationHelper
  include ActionView::Helpers
  def render_money(amount, unit = '$')
    number_to_currency(BigDecimal.new(amount || 0) / 100, unit: unit)
  end

  def render_money_short(amount, unit = '$')
    render_money(amount, unit).remove('.00')
  end

  def render_percentage(decimal, params={})
    precision = params[:precision] || 2
    number_to_percentage(decimal * 100, precision: precision)
  end

  def blankslate(text, options = {})
    content_tag :p, text, class: "center mt0 mb0 pt2 pb2 slate bold h3 mx-auto max-width-2 #{options[:class]}"
  end

  def badge_for(count, options = {})
    content_tag :span, count, class: "badge #{options[:class]} #{'bg-muted' if count == 0}"
  end

  def status_badge(type = :pending)
    content_tag :span, '', class: "status bg-#{type}"
  end

  def status_if(type, condition)
    status_badge(type) if condition
  end

  def pop_icon_to(icon, url, options = {})
    link_to url, options.merge({ class: "pop #{options[:class]}" }) do
      inline_icon icon, size: 32
    end
  end

  def relative_timestamp(time, options = {})
    content_tag :span, "#{time_ago_in_words time} ago", options.merge({ title: time })
  end

  def auto_link_new_tab(text)
    auto_link(text, html: { target: '_blank' })
  end

  def inline_icon(filename, options = {})
    file = File.read(Rails.root.join('app', 'assets', 'images', 'icons', "#{filename}.svg"))
    doc = Nokogiri::HTML::DocumentFragment.parse file
    svg = doc.at_css 'svg'
    options[:style] ||= ''
    if options[:size]
      options[:width] = options[:size]
      options[:height] = options[:size]
      options.delete :size
    end
    options.each { |key, value| svg[key.to_s] = value }
    doc.to_html.html_safe
  end

  def page_hide_home
    @hide_home = true
  end

  def page_snow
    content_for(:page_class) { 'bg-snow' }
  end

  def page_md
    content_for(:container_class) { 'container--md' }
  end

  def page_sm
    content_for(:container_class) { 'container--sm' }
  end
  alias_method :page_narrow, :page_sm

  def page_xs
    content_for(:container_class) { 'container--xs' }
  end
  alias_method :page_extranarrow, :page_xs
end
