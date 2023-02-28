# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include LinkToFunctionHelper

  def _(x, y = nil)
    x
  end

  def tz(time_at)
    TzTime.zone.utc_to_local(time_at.utc)
  end

  def title(text)
    @title = text
    "<h1>#{@title}</h1>".html_safe
  end

  def obj_title(obj)
    %w(title full_name name subject login).each do |a|
      if obj.respond_to?(a)
        return obj.send(a) || 'no title'
      end
    end
    "#{obj.class}: #{obj.id}".html_safe
  end

  def error_messages_for(obj)
    o = self.instance_variable_get('@' + obj.to_s)
    return unless o.respond_to?(:errors)
    errors = []
    lc_g = o.lc_group if o.respond_to?(:lc_group)
    lc_g ||= o.class.to_s.underscore
    label_ids = []
    o.errors.each do |k, v|
      v = _(v.to_s, lc_g) if v.is_a?(Symbol)
      v = (eval(v) rescue v) if v[0..0] == '('
      k = k.to_s
      label_ids << (label_id = "#{lc_g}_#{k}")
      v = "Поле <b id=\"name_of_#{label_id}\">" + k.camelize + '</b> ' + v unless k == ''
      errors << content_tag('li', v.html_safe)
    end
    if errors.blank?
      ""
    else
      (@run_on_load ||= "") << label_ids.map { |l_id|
        "
          labels = $$('form label[for=\"#{l_id}\"]');
          if ( labels.length > 0 ) {
            $('name_of_#{l_id}').update( labels[0].innerHTML.strip() );
          }
        "
      }.join("\n")
      content_tag('div',
                  content_tag('div',
                              content_tag('div', link_to_function(
                                icon_close, "$('errors').hide();"), :class => 'right') +
                                content_tag('h2', "Ошибки при заполнении формы") +
                                content_tag('ul', errors.join("\n").html_safe), class: 'form_error',
                              class: 'error_msg2'
                  ),
                  class: 'error_msg',
                  id: 'errors'
      )
    end
  end

  def error_wrapper(object, field_name, &block)
    html = capture(&block)
    if object &&
      object.respond_to?(:errors) &&
      object.errors.respond_to?(:on) &&
      object.errors.on(field_name)
    then
      concat(
        '<div class="fieldWithErrors">' + html + '</div>'
      ).html_safe
    else
      concat(html).html_safe
    end
  end

  def flash_messages
    return '' if @flash_messages_done
    @flash_messages_done = true
    res = ''
    @info ||= ''
    @info += (flash[:info] || '')
    res << '<div id="info1" class="msg"><div class="msg2"><div class="right">' <<
      link_to_function(icon_close, "$('info1').hide();") << '</div>' <<
      @info << '</div></div>' unless @info.blank?
    @error ||= ''
    @error += (flash[:error] || '')
    res << '<div id="error1" class="msg"><div class="msg2"><div class="right">' <<
      link_to_function(icon_close, "$('error1').hide();") << '</div>' <<
      @error << '</div></div>' unless @error.blank?
    res.html_safe
  end

  def image_item(fitem, options = {})
    if fitem
      thumb_options = options.project(:width, :height, :dims, :max_width, :max_height)
      options.delete(:dims)
      options[:alt] ||= h(fitem.comment)

      img = image_tag(
        thumb_options.empty? ? fitem.url : fitem.ensure_thumb_url(thumb_options),
        options
      )

      unless options[:no_link]
        window_name = 'fitem_' + fitem.id.to_s
        sb = ((fitem.width || 0) > 1000 || (fitem.height || 0) > 700) ? 'yes' : 'no'
        link_to_function(img,
                         "window.open('#{image_fitem_path(fitem)}', '#{window_name}', 'scrollbars=#{sb},toolbar=no,status=no,resizable=yes,width=808,height=603')",
                         title: 'Открыть в отдельном окне'
        )
      else
        img
      end
    else
      image_tag('nopicture.png')
    end
  end

  def link_to_file(text, options, html_options = {})
    if n = options[:name]
      content_tag('a', text,
                  { :href => Fitem.url_by_name(n) }.merge!(html_options)
      )
    elsif f = options[:fitem]
      content_tag('a', text, { :href => f.url }.merge!(html_options))
    elsif i = options[:id]
      if fitem = Fitem.find_by_id(i)
        options[:name] = fitem.name
        link_to_file(text, options, html_options)
      else
        text
      end
    else
      if text =~ /^[\w\d\-\.]+$/
        options[:name] = text
        link_to_file(text, options, html_options)
      else
        text
      end
    end
  end

  def link_to_remote_with_spin(text, *args)
    options = extract_options(args)
    spin_id = options.delete(:spin_id) || 'spin' + rand(10000).to_s + '_' + (@_s_id ||= 0; @_s_id += 1;).to_s
    options[:before] ||= ''
    options[:complete] ||= ''
    options[:before] << ";$('#{spin_id}').show();"
    options[:complete] << ";$('#{spin_id}').hide();"
    text << icon_spinning(id: spin_id, style: 'display:none;')
    args << options if options
    # link_to_remote(text, *args)
    link_to(text, *args, remote: true)
  end

  def help_tip(text)
    text = h(text)
    content_tag('a',
                image_tag('icon-question.gif', :align => 'middle', :alt => '?'),
                :title => h(text),
                :onclick => 'alert(this.title)',
                :class => 'help_tip'
    )
  end

  # Usage: <%= rus_plural(n, "объект", "объекта", "объектов" %>
  def rus_plural(count, one, two, five)
    i = count.to_i % 100
    i %= 10 if i >= 20
    count.to_s + ' ' +
      case i
      when 1
        one.to_s
      when (2..4)
        two.to_s
      else
        # (5..20), 0
        five.to_s
      end
  end

  # Creates div element which can be expanded and shrinked/closed.
  # The first argument is the text for expand link (when block is shrinked).
  # Content between <% do %> and <% end %> is contents for expanded div.
  #
  # Use option :noshrink => true for popups (messages) to make block closable
  # (not shrinkable)
  #
  # Privide block arguments if you want to be responsible for shrink/close link.
  #
  # The first argument is shrink(close) link which you can place anywhere inside
  # your block.
  #
  # The second argument is javascript to close/shrink block (you can use it
  # as second argument for link_to_function method).
  # Max number of block arguments is 4:
  #  * close_link - link to close buttom
  #  * close_js - only java script that shrinks(closes) block
  #  * open_id - id of HTML 'div' element for opened state  block
  #  * close_id - id of HTML 'div' element for shrinked state block
  #
  # Use the first if standard shrink(close)-button is ok for you.
  # Use the second if you want to use your own disign of shrink(close)-button.
  #
  # If ruby-block has no arguments then shrink(close)-link is result of icon_close or "<<",
  # which is placed at the right top corner.
  #
  # Example 1:
  # <% expandable_block('expand_me&gt;&gt;') do |close_link,js_close,open_id,close_id|  -%>
  #   <div class="my_frame_box">
  #     <div align="right"><%= link_to_function(image_tag('close.png'), js_close) %></div>
  #     Content of block
  #   </div>
  # <% end -%>
  #
  # Example 2:
  # <% expandable_block('expand_me&gt;&gt;', :noshrink => true) do |close_link| -%>
  #   <div class="bottom"><%= close_link %></div>
  #    Message text
  # <% end -%>
  #
  def expandable_block(text = '&gt;&gt;'.html_safe, options = {}, &block)
    raise ArgumentError, "Missing block" unless block_given?
    add_class = options.delete(:class) || ''
    @block_id ||= 0
    @block_id += 1
    o_id = "_o_#{@block_id}"
    c_id = "_c_#{@block_id}"
    close_link_class = options[:close_link_class]

    expanded = options[:expanded] || options[:noshrink]

    closing_javascript = "$('#{o_id}').hide();$('#{c_id}').show()".html_safe
    closing_link = link_to_function(
      options[:icon_close] || (respond_to?(:icon_close) && icon_close) || '&lt;'.html_safe,
      closing_javascript,
      alt: options[:close_alt] || 'close block',
      class: "expblock_close_link #{close_link_class}"
    ).html_safe
    content = ''

    arity = block.arity || 0
    arity = 4 if arity < -1
    if arity > 0
      content = capture(*[closing_link, closing_javascript, o_id, c_id][0..arity], &block)
      closing_link = ''
    else
      content = capture(&block)
    end
    unless options[:noshrink]
      concat(
        content_tag('div',
                    link_to_function(text, "$('#{o_id}').show();$('#{c_id}').hide()").html_safe,
                    { id: '_c_' + @block_id.to_s, class: "expblock_closed #{add_class}" }.merge!(options)
        ).html_safe
      )
    end
    concat(
      content_tag('div',
                  closing_link.html_safe + content.html_safe,
                  { id: '_o_' + @block_id.to_s, class: "expblock_opened #{add_class}" }.merge!(options)
      ).html_safe
    )
    unless expanded
      concat("<script>$('#{o_id}').hide();</script>".html_safe)
    else
      unless options[:noshrink]
        concat("<script>$('#{c_id}').hide();</script>".html_safe)
      end
    end
  end

  def multiple_link_to(ary, sep, *args)
    raw(ary.map { |a| link_to(a, *args) }.join(sep))
  end

  # image tag showing userpicture
  def user_image(user, options = {})
    src = user.image_url
    if flash[:reload_image_for] == user.id
      src += '?t=' + rand(100000).to_s
    end
    image_tag(src, { class: "user_image" }.merge!(options))
  end

  def framed(content)
    content_tag('div', content, :class => 'framed')
  end

  # image tag showing userpicture
  def framed_user_image(user, options = {})
    framed(user_image(user, options))
  end

  # Icons
  #
  def gender_icon(user, opts = {})
    case user.gender
    when true # :)
      image_tag('icon-boy.png', :class => 'gender')
    when false
      image_tag('icon-girl.png', :class => 'gender')
    else
      ''
    end
  end

  class << self
    def define_icon(*names)
      names.each do |name|
        name = name.to_s
        ext = (name =~ /\.(\w+)$/ and $1) || 'gif'
        name.gsub!(/\.\w+$/, '')
        icon_src = "icon-#{name}.#{ext}".gsub('_', '-')
        define_method(meth = 'icon_' + name.to_s.gsub('-', '_')) do |*args|
          opts = extract_options(args) || {}
          image_tag(icon_src, { :class => 'icon' }.merge!(opts)) if icon_src.present?
        end
        make_cached meth, :scope => :object
      end
    end
  end

  define_icon *%w{search close edit.png info delete spinning question comment.png comments.png}
end

