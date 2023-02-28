module FitemUploader

  def new_fitem
    @fitem = Fitem.new
    render :file => 'fitem/_upload_form'
  end

  attr_accessor :fitem

  def save
    true
  end

  def create_fitem 
    upload_fitem(self)
    if @error
      @error = @error.to_s.humanize
      render :file => 'fitem/_upload_form'
    else
      flash[:info] = 'Succsessfuly uploaded. One more?'
      redirect_to :action => 'new_fitem'
    end
  end

  def upload_fitem(object, attr_name=:file, options={})
    fitem_options = options[:fitem_options] || {:max_width => 1024}
    pars = options[:params] || params[:fitem] || params
    file_field = options[:file_field] || :file 
    fitem_options[:name] ||= 'fitem_at_' + Time.now.to_i.to_s

    if fitem_options[:name].is_a?(Proc)
      fitem_options[:name] = fitem_options[:name][pars[file_field]]
    end

    @fitem = nil
    @error = nil
    @prev_fitem = object.send(attr_name)
    case pars[:fitem_action]
    when 'upload', nil
      unless pars[file_field].blank?
        @fitem = Fitem.create_from(pars[file_field], fitem_options)
        if @fitem && @fitem.save
          object.send(attr_name.to_s + '=', @fitem)
          if object.save
            @prev_fitem.destroy if @prev_fitem
          else
            @error = :cant_save_object
          end
        else
          @error = :cant_upload_file
        end
      else
        @error = :no_file
      end
    when 'reset'
      @fitem = object.send(attr_name)
      @fitem.destroy if fitem
      unless object.save
        @error = :cant_save_object_after_reset
      end
    when 'nochange'
    else
      @error = :invalid_action
    end
  end
end

