module TopicsHelper
  def topic_content(name, options = {})
    topic = Topic.find_by_name(name)
    if topic
      if topic.show_title? && (options[:include_title] || options[:title_tag])
        options[:title_tag] ||= 'h1' if options[:include_title] == true
        res = content_tag(options[:title_tag], topic.title) + "\n" + topic.formatted_content(self)
      else
        res = topic.formatted_content(self)
      end
      if has_permission?(:topics)
        res = '<div align="right">' +
          link_to_edit_topic('[Редактировать]', :name => name) +
          '</div>' + res
      end
      res.html_safe
    else
      no_topic(name)
    end
  end

  def no_topic(name)
    if has_permission?(:topics)
      link_to '[Создать пустую страницу]', birth_url(:name => name, :method => :post)
    else
      "Страница #{name} пуста."
    end
  end

  def link_to_topic(text, options = {}, html_options = {})
    # no caching for authorized users
    link_to(text, current_user ? i_auth_path(options) : i_path(options), html_options)
  end

  def link_to_edit_topic(text, options = {}, html_options = {})
    options[:id] ||= options.delete(:name)
    link_to(text, edit_topic_path(options), html_options)
  end

  def link_to_edit_topic_with_icon(text, options = {})
    link_to_edit_topic(icon_edit, options) + '&nbsp;' +
      link_to_edit_topic(text, options)
  end

  def i_topic_path(topic, options = {})
    current_user ?
      i_auth_path(options.merge(:name => topic.name)) :
      i_path(options.merge(:name => topic.name))
  end

  def topic_path(topic, options = {})
    if topic.is_a?(Topic)
      i_topic_path(topic, options)
    else
      (current_user ?
         url_for(options.merge(:action => 'show_auth')) :
         url_for(options.merge(:action => 'show'))
      )
    end
  end
end

module BasicParseMacros
  def parse_link(topic, name, text, html_options = {})
    if name =~ /^(\w+path)$/
      begin
        link_to(raw(text), eval(name), html_options)
      rescue => e
        "<font color=\"red\">LINK ERROR: #{e.message}</font>"
      end
    elsif name =~ /\//
      raw(link_to(raw(text), name, html_options))
    else
      options = { name: name.downcase }
      link_to_topic(raw(text), options, html_options)
    end
  end

  def parse_url(topic, name)
    current_user ? "/i_auth/#{name}" : "/i/#{name}"
  end

  def parse_file(topic, name, text, options = {})
    link_to(text, Fitem.url_by_name(name.downcase), options)
  end

  # image tag
  def parse_image(topic, *args)
    options ||= {}
    options = args.pop if args.last.is_a?(Hash)
    options.merge!(:no_link => true)
    args.push(options)
    parse_thumb(topic, *args)
  end

  # image tag opened in separate window on click
  def parse_thumb(topic, *args)
    options ||= {}
    options = args.pop if args.last.is_a?(Hash)
    name, text = *args
    text ||= name # DEPRICATED
    fitem = Fitem.find_by_name(name)
    options[:align] = 'left' if options.delete(:left)
    options[:align] = 'right' if options.delete(:right)
    options[:align] = 'center' if options.delete(:center)
    options[:alt] ||= h((fitem && (fitem.comment || fitem.name)) || name)
    caption = options.delete(:caption)

    res = (fitem ?
             image_item(fitem, options) :
             image_tag(name, options)
    )
    if caption
      res = "<table align=\"#{options[:align]}\" class=\"image image_#{options[:align]}\"><tr><td>#{res}</td></tr>\n<tr><td>#{caption}</td></tr></table>\n"
    end
    res
  end

  def parse_summary(topic, name, options)
    t = Topic.find_by_name(name)
    res = t.formatted_summary

    unless options[:no_title]
      title_tag = options[:title_tag] || 'h2'
      res = content_tag(title_tag, link_to_topic(options[:title] || t.title, :name => name)) + "\n" + res
    end

    if !(options[:no_link_to_topic] || options[:no_link])
      res.sub!(/(<\/div>|)[\s\n]*\Z/) { |m| link_to_topic("&nbsp;&gt;&gt;&gt;".html_safe, :name => name) + "#{$1}".html_safe }
    end
  end

  def parse_list(topic, section, options)
    topics = Topic.where(section: section)
                  .order(options[:order] || 'published_at DESC')
                  .limit(options[:limit] || 3)
    tag_name = options.fetch(:tag, 'li')
    topics.map { |t|
      content_tag(
        tag_name,
        (
          (options.fetch(:nodate, options.fetch(:no_date, false)) ?
             "" :
             '<span class="date">' + date_s(t.published_at) + '</span>&nbsp;'
          ) + link_to_topic(t.title, name: t.name) + '&nbsp;' +
            ((options[:with_summary] && !t.summary.blank?) ?
               '<div class="summary">' + t.formatted_summary + '</div>&nbsp;' :
               ''
            ) +
            ((options[:with_author] && !t.author.blank?) ?
               '<span class="author">' + t.author + '</span>&nbsp;' :
               ''
            )
        ).html_safe
      ).html_safe
    }.join("\n")
  end

  def parse_set_value(topic, name, value, options)
    begin
      Constant.set(name, value)
    rescue => e
      puts e
    end

    ''
  end

  def parse_get_value(topic, name, options)
    "<span class=\"GET_VALUE_#{name}\">#{Constant.get(name)}</span>"
  end

  def parse_include(topic, name, options)
    t = Topic.find_by_name(name)
    raise "Нет такой страницы" unless t
    res = t.formatted_content(self).html_safe
    unless options[:no_title]
      title_tag = 'h2' || options[:title_tag]
      res = content_tag(
        title_tag,
        (t.title + (
          current_user ? "&nbsp;&nbsp;" + link_to_edit_topic("[редактировать]", t) : ""
        )).html_safe
      ) + "\n" + res
    end
    res.html_safe
  end

  def parse_params(topic, *keys)
    options = keys.pop if keys.last.is_a?(Hash)
    # h(params.inspect + keys.inspect)
    keys.inject(params) { |p, k| p[k] || {} }.to_s
  end

  def parse_permission(topic, *perms)
    logger.info "FOUND PERMISSION (formatting): #{perms.inspect}"
    topic.permissions.push(*perms.select { |p| !p.blank? }.map(&:to_sym))
    ''
  end

end

module ParseTopic
  include TopicParser

  register_macro_parser :parse_topic, %w(LINK URL FILE IMAGE THUMB SUMMARY INCLUDE PARAMS PERMISSION SET_VALUE GET_VALUE LIST)
  after_parse :expand_links, :append_errors, for: :parse_topic

  include BasicParseMacros

  def expand_links(topic, text, parser)
    # anti spam measures for emails
    text.gsub!(/\b(\w[.\w\d]+@[\w\d]+.[\.\w\d]+)([^\w\d"])/) { |m|
      # {|m| "<a href=\"mailto:#{$1}\">#{$1}</a>#{$2}"}
      email = $1
      tail = $2
      email.gsub!('@', '<span class="empty"> УДАЛИ МЕНЯ </span>@<span class="empty"></span>'.html_safe)
      "#{email}#{tail}"
    }

    # autolink external links
    text.gsub!(/(...)((https?|ftp):\/\/[\w\d\-_?\.\&\/_]+)([^"\w\d\-_\.?\&\/]|$)/) { |m|
      prefix = $1
      url = $2
      suffix = $4
      (prefix =~ /=["']?/) ? "#{m}" : "#{prefix}<a href=\"#{url}\">#{url.html_safe}</a>#{suffix}"
    }
  end

  def append_errors(topic, text, parser)
    unless topic.parse_errors.empty?
      text <<
        '<div class="errors">Ошибки на странице: <ul><li>' <<
        h(topic.parse_errors.map { |i| i.join(', ') }.join("</li>\n<li>".html_safe)) <<
        "</li></ul></div>\n"
    end
  end
end

module ExtractPermissions
  include TopicParser
  register_macro_parser :extract_permissions, %w(INCLUDE  PERMISSION), :no_change => true

  def parse_include(topic, name, options)
    t = Topic.find_by_name(name)
    t.extract_permissions(t, t.content)
    topic.permissions.push(*t.permissions)
  end

  def parse_permission(topic, *perms)
    topic.permissions.push(*perms.select { |p| !p.blank? }.map(&:to_sym))
    logger.info "FOUND PERMISSION: #{perms.inspect}"
  end
end

module RenderTopicsHelper
  def render_topic(name, options = {})
    instance_variable_set('@topic', Topic.find_by_name(name))
    instance_variable_set('@name', name)
    instance_variable_set('@options', options)
    params.merge!(options)
    render({ template: 'topics/show' }.merge!(options))
  end
end

ActionController::Base.class_eval do
  include TopicsHelper
  include RenderTopicsHelper
end

ActionView::Base.class_eval do
  include TopicsHelper
  include ParseTopic
end
