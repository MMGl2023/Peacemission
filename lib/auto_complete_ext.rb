module AutoCompleteExt

  module ExtractHasManyFields

    def find_by_search(text, klass = nil, options = {}, &block)
      attribute = options[:attribute] || 'name'
      if block
        block[text]
      elsif options[:find_by]
        klass.send('find_by_' + options[:find_by], text)
      else
        (
          text =~ /^(N|№)?(\d+)( |$)/ && klass.find_by_id($2)
        ) ||
          klass.find(:first, :conditions => ["LOWER(#{attribute}) LIKE ?", text + "%"]) ||
          klass.find(:first, :conditions => ["LOWER(#{attribute}) LIKE ?", "%" + text + "%"])
      end
    end

    def extract_has_many_fields(assoc_name, params, options = {}, &block)
      klass = (options[:class_name] || assoc_name.to_s.singularize.camelize).constantize
      objs = []
      name = (options[:name] || assoc_name).to_s
      (0..100).each do |i|
        name_i = name + i.to_s
        text = params.delete(name_i)
        break if text.nil?
        next if text.blank?
        f = find_by_search(text, klass, options, &block)
        objs << f if f
      end
      params[assoc_name] = objs
    end

    def extract_has_many_field(assoc_name, params, options = {}, &block)
      klass = (options[:class_name] || assoc_name.to_s.singularize.camelize).constantize
      objs = []
      name = options[:name] || assoc_name.to_s
      search = params.delete(name) || ''
      sep = (options[:tokens] || [',', ':', "\n"]).join('|')
      search.split(sep).each do |text|
        f = find_by_search(text, klass, options, &block)
        objs << f if f
      end
      params[assoc_name] = objs
    end
  end

  module RenderResult
    # format can be :json, yaml, or :html (default)
    #
    def render_result(result, format)
      @result = result
      case format
      when :json
        render_text result.to_json
      when :yaml
        render_text result.to_yaml
      when :strings
        render :inline => "<%= auto_complete_strings_result @result %>"
      else
        render :inline => "<%= auto_complete_result @result, 'to_s' %>"
      end
    end
  end

  module ControllerClassMethods
    def ext_auto_complete_for_many(obj_name, attribute, options = {}, &block)
      options[:name] ||= obj_name.to_s.pluralize.to_sym
      options[:extract] = :extract_has_many_fields unless options[:extract] == false
      ext_auto_complete_for(obj_name, attribute, options, &block)
    end

    #  Example
    # Controller:
    #  ext_auto_complete_for :artist, :title, {:prefix=>'xxx', :name=>'yyy'}
    #
    # View
    #  <input type="text" id="xxx[yyy]" value="<% @artist.title %>" >
    #
    # And do not forget to include javascript controls.js
    #
    def ext_auto_complete_for(obj_name, attribute, options = {}, &block)
      prefix = options.delete(:prefix) || obj_name
      name = options.delete(:name) || attribute
      out = options.delete(:out) || attribute
      format = options.delete(:format) || :strings
      klass = obj_name.to_s.camelize.constantize
      logger.info "Defining method auto_complete_for_#{prefix}_#{name}"
      extract_method = options.delete(:extract)
      extract_before = options.delete(:extract_before) || [:create, :update]
      find_method = options.delete(:find)
      define_method("auto_complete_for_#{prefix}_#{name}") do
        @items = []
        field_name = params[:name] || name
        if params[prefix] && params[prefix][field_name] && params[prefix][field_name].to_s.length > 2
          # start with records starting with typed substring
          text = params[prefix][field_name].to_s.downcase

          # let's find candidates matching text
          find_options = {
            :conditions => ["LOWER(#{attribute}) LIKE ?", text + '%'],
            :order => "#{attribute} ASC",
            :limit => 10
          }.merge!(options)

          limit = find_options[:limit]

          if text =~ /^(N|№)?(\d+)( |-|$)/ && item = klass.find_by_id($2)
            @items = [item]
            find_options[:limit] = limit - @items.size
          end

          @items += klass.find(:all, find_options)
          find_options[:limit] = limit - @items.size

          # append them by those that have typed substring inside
          if @items.size < find_options[:limit]
            find_options[:conditions] = ["LOWER(#{attribute}) LIKE ?", '%' + text + '%'];
            @items += klass.find(:all, find_options)
          end
        end

        # prepare text presentations of found candidates
        if block
          @items.map(&block)
        else
          @result = @items.map { |i| i.send(out).to_s }
          render_result(@result, format)
        end
      end

      # we need before_action method to convert texts (describing objects for
      # has_many association) to real objects

      if extract_method
        extract_method = :extract_has_many_field if extract_method == true
        filter_method = ("extract_" + prefix.to_s + "_" + name.to_s).to_sym
        if find_method
          define_method(filter_method) do
            find_proc = find_method
            find_proc = proc { |x| send(find_method, x) } if find_method.is_a?(Symbol)
            send(extract_method, name, params[prefix], &find_proc)
          end
        else
          define_method(filter_method) do
            send(extract_method, name, params[prefix])
          end
        end
        # hide_action filter_method

        before_action filter_method, only: extract_before
      end
    end
  end

  module HelperMethods
    #
    # Generates several text_fields with autocomplete
    # for editing has_many associations.
    def auto_complete_fields_for_many(obj, assoc_name, options = {})
      obj_name = obj.class.to_s.underscore
      objs = obj.send(assoc_name)
      attribute = options[:attribute]
      prefix = options[:prefix] || obj_name
      if attribute.nil?
        f = objs.first
        [:signature, :title, :full_name, :name, :label].each do |a|
          (attribute = a and break) if f.respond_to?(a) || f.nil?
        end
      end
      attribute ||= :signature
      name = (options[:name] || assoc_name).to_s
      values = objs.map(&attribute.to_sym)
      options[:max_n] ||= 6
      n = values.size + 1
      n = options[:max_n] if options[:max_n] > n
      prev_value = 1
      raw(content_tag('ul',
                      raw((0...n).map { |i|
                        item = name + i.to_s
                        next_item = name + (i + 1).to_s
                        li_id = "li_#{prefix}_#{item}"
                        li_next_id = "li_#{prefix}_#{next_item}"
                        style = options.delete(:style) || ''
                        style += "display:none" if prev_value.nil?
                        prev_value = values[i]
                        show_next = raw((i == n - 1) ? "" : "$('#{li_next_id}').show()")
                        raw(content_tag('li',
                                        text_field_with_auto_complete(prefix, item,
                                                                      {
                                                                        width: 16,
                                                                        value: values[i] || '',
                                                                        onclick: show_next
                                                                      }.merge!(options[:html] || {}),
                                                                      {
                                                                        url: {
                                                                          action: "auto_complete_for_#{prefix}_#{name}",
                                                                          name: item
                                                                        } #, # after_update_element: show_next
                                                                      }
                                        ),
                                        style: style, id: li_id
                            ))
                      }.join("\n")), class: 'auto_complete_for_many ' + obj.class.to_s.underscore
          ))
    end

    # Generates one text_fields with autocomplete
    # for editing has_many associations (comma-separated ).
    def auto_complete_field_for_many(obj, assoc_name, options = {})
      obj_name = obj.class.to_s.underscore
      objs = obj.send(assoc_name)
      attribute ||= options[:attribute]
      if attr_name.nil?
        f = objs.first
        [:signature, :title, :name, :full_name, :label].each do |a|
          (attribute = a and break) if f.respond_to?(a) || f.nil?
        end
      end
      attribute ||= :signature
      value = options[:value] || options[:values] || objs.map(&attribute.to_sym)
      value = value.join(', ') if value.is_a?(Array)
      prefix = params[:prefix] || obj_name
      name = params[:name] || assoc_name
      res = "<div class=\"auto_complete_field_for_many #{prefix}_#{name}\">"
      if options[:label]
        label = options[:label]
        label = assoc_name.to_s.camelize if label.nil? || label == true
        res << "<label for=\"#{prefix}_#{name}\">#{label}:</label>"
      end
      res << text_field_with_auto_complete(
        prefix, name,
        { :size => 80, :value => value }.merge!(options[:html] || {}),
        {
          :url => { :action => "auto_complete_for_#{prefix}_#{name}" },
          :tokens => (options[:tokens] || [',', ';'])
        }
      ) << "</div>"
    end

    def auto_complete_strings_result(entries, phrase = nil)
      return unless entries
      items = entries.map { |entry| content_tag("li", phrase ? highlight(entry, phrase) : h(entry)) }
      content_tag("ul", items.uniq)
    end

  end
end

ActionController::Base.class_eval do
  include AutoCompleteExt::ExtractHasManyFields
  include AutoCompleteExt::RenderResult
  extend AutoCompleteExt::ControllerClassMethods
end

ActionView::Base.class_eval do
  include AutoCompleteExt::HelperMethods
end

