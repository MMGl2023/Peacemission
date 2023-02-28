class FitemsController < ApplicationController
  
  before_filter :signin_if_not_yet, :except=>[:index, :show, :image]

  def find_or_message
    unless (params[:id] && @fitem = Fitem.find_by_id(params[:id])) or
           (params[:name] && @fitem = Fitem.find_by_name(params[:name]))
      flash[:error] = "Не могу найти файл с name=#{params[:name]||'*'} и id=#{params[:id]||'*'}"
      respond_to do |f|
        f.html { redirect_to fitems_path }
        f.xml  { head :not_found }
      end
      false
    else
      @fitem
    end
  end

  def index
    list
  end

  def edit
    find_or_message
  end

  def show
    if find_or_message
      respond_to do |f|
        f.html # show.html.erb
        f.xml  { render :xml=>@fitem }
      end
    end
  end

  def image
    if find_or_message
      respond_to do |f|
        f.html { render :action=>'image', :layout=>'image' }
        f.xml  { render :xml=>@fitem }
      end
    end
  end

  def update
    if find_or_message
      if params[:cancel]
        flash[:info] = "Изменения были отменены"
        respond_to do |f|
          f.html { redirect_to @fitem }
          f.xml  { render :xml => @fitem, :status => :canceled, :location => @fitem }
        end
      else
        if @fitem.update_attributes( params[:fitem].project(:name, :comment) )
          case params[:fitem][:file_action]
          when 'upload'
            @fitem.update_from_stream(params[:fitem][:file], :max_width=>1024)
          end
          flash[:info] = "Файл был обновлён"
          if @fitem.errors.empty?
            respond_to do |f|
              f.html { redirect_to @fitem }
              f.xml  { head :ok }
            end
            return
          end
        end
      end
      respond_to do |f|
        f.html { render :action=>'edit'  }
        f.xml  { render :xml => @fitem.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create
    attrs = params[:fitem]
    if attrs && attrs[:name]
      if attrs[:name] == '#'
        attrs[:name] = 'file' + (Fitem.max_id+1).to_s
      end
      unless Fitem.find_by_name(attrs[:name])
        @fitem = Fitem.create_from(
          attrs[:file], 
          attrs.project(:name,:content_type,:ext,:original_filename)
        )

        if @fitem.errors.empty?
          flash[:info] = "Файл #{@fitem.name} успешно загружен. <a href=\"#{fitem_path(@fitem)}\">Редактировать</a>"
          respond_to do |f|
            f.html { redirect_to @fitem }
            f.xml  { render :xml => @fitem, :status => :created, :location => @fitem }
          end
          return
        else
          @e = [:name, "Не могу создать файл #{attrs[:name]}"]
        end
      else
        @e = [:name, "Файл с именем #{attrs[:name]} уже существует"]
      end
    else
      @e = [:name, "Не указано имя файла"]
    end
    @fitem ||= Fitem.new(attrs)

    @fitem.errors.add(*@e)  if @e

    respond_to do |f|
       f.html { render :action => 'edit' }
       f.xml  { render :xml => @fitem.errors, :status => :unprocessable_entity }
    end
  end


  def destroy
    if find_or_message
      @fitem.destroy
      respond_to do |f|
        f.html { 
          flash[:info] = "Файл #{@fitem.name} (#{@fitem.original_filename}) был удален"
          redirect_to fitems_path
        }
        f.xml { head :ok }
      end
    end
  end

  def list
    @title ||= "Пользовательские файлы"

    @wide_style = true
    sort_cnds = params[:sort] ? {} : {:order => 'created_at DESC'} 

    cnds = conditions_from_params :fitem,
      :sort_by    => %w(id name original_filename ext created_at),
      :search_in  => %w(name content_type comment original_filename),
      :filter     => %w(content_type ext),
      :per_page   => params[:per_page] || 20,
      :page       => params[:page]

    Fitem.send(:with_scope, :find => sort_cnds) do
      @fitems = Fitem.paginate(cnds)
    end

    respond_to do |f|
      f.html { render :action => 'list' }
      f.xml  { render :xml => @fitems }
    end
  end
end
