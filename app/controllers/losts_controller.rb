class LostsController < ApplicationController
  
  before_filter :signin_if_not_yet, :except=>[:show, :index, :search, :update, :create, :new, :edit]

  before_filter :find_lost, :only => [:edit, :update, :show, :destroy]
  before_filter :check_edit_permissions, :only => [:edit, :update, :destroy]


  caches_action :show,  :if => :caching_allowed?, :tag => :login_tag
  caches_action :index, :if => :caching_index_allowed?, :tag => :action_and_login_and_page_tag
 
  cache_sweeper :lost_sweeper, :only => [:update, :create]

  protected

  def allow_edit?
    has_permission?(:losts) || session.session_id == @lost.session_id
  end
  helper_method :allow_edit?

  def check_edit_permissions
    allow_edit? || access_denied("Нет прав для редактирования объявления", lost_path(@lost)) 
  end

  def caching_index_allowed?
    [:lost_s, :sort, :sort_dir, :year].all?{|i| params[i].blank?} && flash.empty?
  end

  def find_lost
    (params[:id] && @lost = Lost.find_by_id(params[:id])) || 
      bad_request("Не могу найти запись с id='#{params[:id]}'", losts_path)
  end

  public

  # GET /losts
  def index
    list
    @wide_style = false
    render :action => 'search'
  end

  # GET /losts/search
  def search
    @title ||= "Поиск в списке пропавших без вести"
    list
  end

  # GET /losts/1
  # GET /losts/1.xml
  def show
    respond_to do |format|
      format.html 
      format.xml { render :xml=>@lost }
    end
  end

  # GET /losts/1/edit
  def edit
    @title = "Редактирование записи на #{@lost.full_name}"
  end

  # POST /lost/1
  def update
    if params[:cancel]
      flash[:info] = "Обновление записи было отменено"
      redirect_to losts_path
    else
      update_and_edit_if_error
    end
  end

  # GET /lost/new
  def new
    @title = "Добавление объявления о пропавшем человеке"
    @lost = Lost.new
    @lost.active = true
    render :action=>'edit'
  end

  # POST /losts
  def create
    if params[:cancel]
      flash[:info] = "Добавление нового объявления было отменено"
      redirect_to :action=>'index'
    else
      @lost = Lost.new
      update_and_edit_if_error
    end
  end

  # DELETE /losts/1
  # DELETE /losts/1.xml
  def destroy
    @lost = Lost.find(params[:id])
    @lost.destroy

    respond_to do |format|
      format.html { 
        flash[:info] == "Объявление №#{params[:id]} удалено" 
        redirect_to_referer_or_default(list_losts_path)
      }
      format.xml  { head :ok }
    end
  end

  def update_attributes
    extract_fuzzy_date(:birth_date, params[:lost])
    extract_fuzzy_date(:lost_on, params[:lost])
    extract_fuzzy_date(:found_on, params[:lost])

    @lost.attributes = params[:lost]
    # .project(
    #    :full_name, :lost_on, :lost_on_year, :lost_on_month, 
    #    :found_on, :found_on_year, :found_on_month,
    #    :active,
    #    :last_location, :birth_year, :birth_date, :bith_month, :details,
    #    :author_full_name, :author_address, :author_email, :author_contacts, :author_phone_number
    #)
  end
  hide_action :update_attributes

  def update_was_successful
    flash[:info] = "Запись на '#{@lost.full_name}' успешно обновлена. <a href=\"#{edit_lost_path(@lost)}\">Редактировать</a>"
    redirect_to lost_path(@lost)
  end
  hide_action :update_was_successful
  
  def update_and_edit_if_error
    update_attributes
    attrs = params[:lost_image] || {}
    # update image
    if @lost.valid?
      @lost.active = true if @lost.active.nil?
      @lost.session_id ||= session.session_id
      case attrs[:fitem_action]
      when 'upload', nil
        unless attrs[:file].blank?
          @prev_fitem = @lost.image
          name = 'lost_at_' + Time.now.to_i.to_s
          @fitem = Fitem.create_from(attrs[:file], :name=>name, :max_width=>1024, :max_height=>712)
          #logger.info "FITEM: " + @fitem.inspect
          if @fitem && @fitem.save
            @lost.image = @fitem
            if @lost.save 
              @prev_fitem.destroy if @prev_fitem
              @fitem.name = 'lost_' + @lost.id.to_s + '.jpg'
              @fitem.save
              update_was_successful
            else
              @fitem.destroy
            end
          else
            # logger.info "FITEM ERRORS: " + @fitem.errors.inspect
            # @lost.errors.add @fitem.errors if @fitem && !@fitem.valid?
            @error = "Не могу загрузить файл с фото. Попробуйте еще раз."
          end
        else
          @error = "Не указан файл с фотографией"
        end
      when 'nochange'
        if @lost.save 
          update_was_successful
        end
      when 'reset'
        if @lost.save
          @lost.image.destroy if @lost.image
          # @lost.image_id
          @lost.save(false)
          update_was_successful
        end
      else
        @error = "Неизвестное действие с фото #{attrs[:image_action]}"
      end
    end
    render :action=>'edit' unless performed?
  end
  hide_action :update_and_edit_if_error
 
  # GET /losts/list 
  def list
    @title ||= "Объявления о розыске"
    @wide_style = true

    params[:active] = 1 unless params[:show_all] == 'true' || action_name == 'list'

    cnds = conditions_from_params :lost,
      :sort_by    => %w(id full_name last_location birth_date birth_year lost_on created_at active),
      :filter     => %w(birth_year active lost_on_year),
      :search_in  => %w(full_name last_location details),
      :page       => params[:page],
      :per_page   => params[:per_page] || 20,
      :default_order => 'created_at DESC'

    @losts = Lost.paginate(cnds)
    if @losts.size == 0 && @losts.total_pages < cnds[:page].to_i
      cnds[:page] = @losts.total_pages
      @losts = Lost.paginate(cnds)
    end
  end
end

