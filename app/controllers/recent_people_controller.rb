class RecentPeopleController < ApplicationController

  before_filter :signin_if_not_yet, :except => ['recent', 'show','list', 'search', 'index', 'db_info']

  # caches_action :index, :if => :caching_index_allowed?, :tag => :action_and_login_and_page_tag

  # caches_action :show,  :tag => :login_tag

  # cache_sweeper :recent_person_sweeper, :only => [:create, :update, :destroy]

  before_filter :extract_fuzzy_dates, :only => [:create, :update]

  before_filter :check_authority, :only => [:update, :destroy]

  before_filter :check_create_authority, :only => [:create]

  before_filter :fix_region
  # ext_auto_complete_for_many :request, :lost_full_name, 
  #  :prefix   => 'recent_person', 
  #  :out      => :signature,
  #  :find     => :find_request_by_text,
  #  :extract_before => [:create, :update]

  ext_auto_complete_for :recent_person, :disappear_region

  protected

  def check_authority
    current_user
  end
    
  def fix_region
    params.delete(:disappear_region) if params[:disappear_region].to_s == ""
  end

  def check_create_authority
    current_user && !has_permission?(:viewer)
  end

  def find_request_by_text(text)
    if text =~ /(\d+)/ && @req = Request.find_by_id($1)
      @req
    else
      @not_found_requests << text
      nil
    end
  end

  def caching_index_allowed?
    [:recent_person_s, :sort, :sort_dir, :birth_year, :lost_on_year, :status, :disappear_region].all?{|p| params[p].blank?}
  end

  public

  def db_info
    render_topic 'people_db_info', :show_title => false
  end

  # GET /people
  # GET /people.xml
  def index
    list
    respond_to do |format|
      format.html { render :action => 'list'  } 
      format.xml  { render :xml => @recent_people }
    end
  end


  # GET /people/recent
  def recent
    @title ||= "Поиск по горячим следам"
  end


  # GET /people/dump
  # GET /people/dump.xml
  def dump
    @recent_people = RecentPerson.find(:all)
    respond_to do |format|
      format.html { render :action => 'dump', :layout => 'plain'  } 
      format.xml  { render :xml => @recent_people }
    end
  end

  # GET /people/1
  # GET /people/1.xml
  def show
    @recent_person = RecentPerson.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @recent_person }
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new
    @recent_person = RecentPerson.new(params[:recent_person])
    @title ||= 'Новая запись в списке по горячим следам'
    if params[:from_lost] && lost = Lost.find_by_id(params[:from_lost])
      if !params[:force] and (p = RecentPerson.find_by_lost_id(lost.id) or (p = RecentPerson.find_by_full_name(lost.full_name) and p.birth_year == lost.birth_year))
        @title = "Редактирование <b>существующей</b> записи"
        @recent_person = p
        @recent_person.lost_id ||= lost.id
      else
        [ :full_name, :last_address,
          :birth_date, :birth_month, :birth_year,
          :lost_on, :lost_on_year, :lost_on_month
        ].each do |f|
          @recent_person[f] = lost[f]
        end
        @recent_person['disappear_location'] = lost['last_location']
        @recent_person.lost_id = lost.id
        @recent_person.info_source = "Сайт rozysk.org"
        @recent_person.remark = "Объявление №#{lost.id}"
      end
    end
    respond_to do |format|
      format.html { render :action => 'edit'} 
      format.xml  { render :xml => @recent_person }
    end
  end

  # GET /people/1/edit
  def edit
    @recent_person = RecentPerson.find(params[:id])
  end

  def extract_fuzzy_dates
    extract_fuzzy_date(:lost_on, :lost_on_year, :lost_on_month, params[:recent_person])
    extract_fuzzy_date(:birth_date, :birth_year, :birth_month, params[:recent_person])
  end
  hide_action :extract_fuzzy_dates

  def init_lost_id
    # if @recent_person.lost_id.blank? && !@recent_person.full_name.blank? && lost=Lost.find_by_full_name(@recent_person.full_name)
    #   @recent_person.lost = lost
    # end
  end
  hide_action :init_lost_id

  def check_requests
    # if @not_found_requests
    #   @recent_person.errors.add :requests, "не могу найти: " +  @not_found_requests.join(',')
    # end
  end
  hide_action :check_requests
 
  # POST /people
  # POST /people.xml
  def create
    if params[:cancel]
      flash[:info] = "Создание записи отменено"
      redirect_to(recent_people_path)
    else
      @recent_person = RecentPerson.new(params[:recent_person])
      # init_lost_id
      # check_requests
      respond_to do |format|
        if @recent_person.save
          flash[:info] = 'Запись на человека успешно создана.'
          format.html { redirect_to(@recent_person) }
          format.xml  { render :xml => @recent_person, :status => :created, :location => @recent_person }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @recent_person.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.xml
  def update
    @recent_person = RecentPerson.find(params[:id])
    if params[:cancel]
      flash[:info] = "Изменение записи отменено"
      redirect_to @recent_person
    else
      # check_requests
      init_lost_id
      respond_to do |format|
        if @recent_person.update_attributes(params[:recent_person])
          flash[:info] = 'Запись на человека успешно обновлена.'
          format.html { redirect_to(@recent_person) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @recent_person.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.xml
  def destroy
    @recent_person = RecentPerson.find(params[:id])
    @recent_person.destroy if @recent_person
    # @recent_person.status = 2
    # @recent_person.save
    
    flash[:info] = "Запись удалена из списка"

    respond_to do |format|
      format.html { redirect_to(recent_people_path) }
      format.xml  { head :ok }
    end
  end

  # GET /people/list
  def list
    @title ||= "Список «Поиск по горячим следам»"
    @wide_style = true
    cnds = conditions_from_params :recent_person,
       :sort_by   => %w(id full_name last_address birth_year lost_on_year disappear_location),
       :filter    => %w(lost_on_year birth_year status disappear_region),
       :search_in => %w(full_name last_address disappear_location info_source remark disappear_region),
       :page      => params[:page],
       :per_page  => params[:per_page] || 20
    
    cnds[:order] ||= 'id ASC'

    @recent_people = RecentPerson.paginate(cnds)
    if @recent_people.size == 0 && @recent_people.total_pages < cnds[:page].to_i
      cnds[:page] = @recent_people.total_pages
      @recent_people = RecentPerson.paginate(cnds)
    end
  end
end

