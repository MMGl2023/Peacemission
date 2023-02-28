module TableExtHelper
  module ConditionsMaster
    def conditions_from_params(name, options={})
      klass = name.to_s.camelize.constantize
      search_field  = options[:search_field] ||  name.to_s + '_s'
      table_name = klass.table_name

      sort_hash = (options[:sort_by]||[]).inject({}) {|f,k| f[k.to_sym] = table_name + '.' + k.to_s; f }
      sort = sort_hash[ options[:default_sort] ]

      search_in = (options[:search_in]||[]).map {|k|  table_name + '.' + k.to_s }

      if params[:sort] && sort_hash[params[:sort].to_sym]
        sort = sort_hash[params[:sort].to_sym]
      end

      sort_dirs = ['asc', 'desc']
      sort_dir = options[:default_sort_dir] || 'asc'

      if params[:sort_dir] && sort_dirs.include?(params[:sort_dir])
        sort_dir = params[:sort_dir]
      end

      order = options[:default_order]  

      if sort
        order = sort + ' ' + sort_dir
      end

      ca,cp = [],{}

      (options[:filter]||[]).each do |f|
        unless params[f].blank?
          if params[f] == 'NULL'
            ca << table_name + '.' + f.to_s + ' IS NULL'
          else
            ca << table_name + '.' + f.to_s + ' = :' + f.to_s
            cp[f.to_sym] = (params[f] == "NULL" ? nil : params[f])
          end
        end
      end

      if params[search_field]
        words = params[search_field].split(/\s+/)
        if words.size > 0
          cw = []
          if words.all?{|w| w.length < 3}
            # order = nil
            # flash[:info] = _('search_word_should_be_longer') if request.post?
          end
          words.each_with_index{|x,i|
            word_id = 'word' + i.to_s
            cw << " like :" + word_id
            cp[word_id.to_sym] = '%'+x+'%'
          }
          ca << (' (' + cw.map{|x|
            search_in.map {|a|
              # a - field name, x - condition
              a + x
            }.join(' OR ')
          }.join(') AND (')+') ')
        end
      end
      cnds = {}
      cnds[:conditions] =  ca.size > 0 ?  [ca.join(' AND '), cp] : nil
      [:select, :page, :limit, :per_page].each do |f|
        cnds[f] = options[f] if options.has_key?(f)
      end
      cnds[:order] = order if order
      cnds
    end
  end

  module TableBuilder
    def highlight_search(html_text, search_query)
      words = search_query.split(/[^\w]/)
      words
      html_text
    end

    def sortable_table(name, options, p=nil, &block)
      p ||= params.dup
      show_fields = options[:show_fields]
      sort_by = (options[:sort_by]||[]).inject({}) {|f,k| f[k.to_sym] = true }
      thead = "<table id=\"#{name}_table\" class=\"list\">\n<tr>"
      show_fields.each do |f|
        title = ((options[:titles]||={})[f] || f.camelize)
        title = "" if f == :empty
        thead << "<th>" + 
          (sort_by[f.to_sym] ?  column_title(f, title, p) : title) +  
        "</th>"
      end
      thead << "</tr>\n"
      table_rows = capture(&block)
      if p[:s]
        table_rows = highlight_search(table_rows, p[:s])
      end
      concat(
        thead + table_rows + '</table>',
        block.binding
      )
    end

    def column_title(name, title, p={}, options={})
      name = name.to_s
      res = '<div align="center">'
      full_title = options[:title] || ''
      full_title = "#{full_title}, " unless full_title.blank?
      stop_sorting = ( (p[:sort] == name) ? 
        link_to(icon_close, params.except(:sort, :sort_dir), 
          :title => 'отключить сортировку', 
          :class => 'stop_sorting'
        ) :
        ''
      )
      if params[:sort] == name && params[:sort_dir] == 'asc'
        res << link_to(
          title,
          p.merge({:sort => name, :sort_dir => 'desc'}),
          :title => "#{full_title}сортировать по убыванию"
        ) + "<div class=\"up_arrow\">#{stop_sorting}</div>"
      elsif params[:sort] == name && params[:sort_dir] == 'desc' 
        res << link_to(
          title,
          p.merge({:sort => name, :sort_dir => 'asc'}),
          {:title => "#{full_title}сортировать по возрастанию"}
        ) + "<div class=\"down_arrow\">#{stop_sorting}</div>"
      else 
        res << link_to(
          title,
          p.merge({:sort => name, :sort_dir => 'asc'}),
          {:title => "#{full_title}сортировать по возрастанию"}
        )
      end

      if p[name]
        value = p[name] 
        value_method = name.to_s + '_filter_field'
        value = send(value_method, value) if respond_to?(value_method)
        res <<  content_tag('div', 
          link_to(value + '&nbsp;' + icon_close,
            params.except(name, :page),
            :title => "отключить фильтрацию по значению", :class => 'stop_filtering'
          )
        )
      end
      res << "</div>"
      res
    end

    def column_title_tag(tag, name, title, p={}, html_options={})
      classes = [ html_options[:class] || []].flatten 
      classes << 'filtered_column' if p[name]
      classes << 'sorted_column' if p[:sort] == name
      content_tag(tag,
       column_title(name, title, p, html_options),
       html_options.merge({:class => classes.join(' ')})
      )
    end
  end
end

ActionController::Base.class_eval do
  include TableExtHelper::ConditionsMaster
end

ActionView::Base.class_eval do
  include TableExtHelper::TableBuilder
end

