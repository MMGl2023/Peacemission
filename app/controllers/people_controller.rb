class PeopleController < ApplicationController
  before_action :signin_if_not_yet, except: %i[show recent recent_list list search index db_info]

  # caches_action :index, if: :caching_index_allowed?, tag: :action_and_login_and_page_tag

  # caches_action :show, tag: :login_tag

  # cache_sweeper :person_sweeper, only: %i[create update destroy]

  before_action :extract_fuzzy_dates, only: %i[create update]

  before_action :check_authority, only: %i[update destroy]

  before_action :check_create_authority, only: %i[create]

  ext_auto_complete_for_many :request, :lost_full_name,
                             prefix: 'person',
                             out: :signature,
                             find: :find_request_by_text,
                             extract_before: [:create, :update]

  ext_auto_complete_for :person, :disappear_region

  protected

  def self.person_class
    Person
  end

  def check_authority
    current_user
  end

  def check_create_authority
    current_user && !has_permission?(:viewer)
  end

  def find_request_by_text(text)
    if text =~ /(\d+)/ && @req = Request.find_by_id($1)
      @req
    else
      @not_found_requests ||= ''
      @not_found_requests << text
      nil
    end
  end

  def caching_index_allowed?
    [:person_s, :sort, :sort_dir, :birth_year, :lost_on_year, :status, :disappear_region].all? { |p| params[p].blank? }
  end

  public

  def db_info
    render_topic 'people_db_info', show_title: false
  end

  # GET /people
  # GET /people.xml
  def index
    params[:main] = true
    list
    params.delete(:main)
    respond_to do |format|
      format.html { render action: 'list' }
      format.xml { render xml: @people }
    end
  end

  # GET /people/recent
  def recent2
    @title ||= "Поиск по горячим следам"
  end

  # GET /people/recent_list
  # GET /people.recent_list.xml
  def recent_list
    @title ||= "Поиск по горячим следам"
    params[:recent] = 1
    list
    params.delete(:recent)
    respond_to do |format|
      format.html { render action: 'recent_list' }
      format.xml { render xml: @people }
    end
  end

  # GET /people/dump
  # GET /people/dump.xml
  def dump
    @people = Person.all
    respond_to do |format|
      format.html { render action: 'dump', layout: 'plain' }
      format.xml { render xml: @people }
    end
  end

  # GET /people/1
  # GET /people/1.xml
  def show
    @person = Person.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render xml: @person }
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new
    @person = Person.new(params[:person])
    @title ||= 'Новая запись'
    if params[:from_lost] && lost = Lost.find_by_id(params[:from_lost])
      if !params[:force] and (p = Person.find_by_lost_id(lost.id) or (p = Person.find_by_full_name(lost.full_name) and p.birth_year == lost.birth_year))
        @title = "Редактирование <b>существующей</b> записи"
        @person = p
        @person.lost_id ||= lost.id
      else
        [:full_name, :last_address,
         :birth_date, :birth_month, :birth_year,
         :lost_on, :lost_on_year, :lost_on_month
        ].each do |f|
          @person[f] = lost[f]
        end
        @person['disappear_location'] = lost['last_location']
        @person.lost_id = lost.id
        @person.info_source = "Сайт rozysk.org"
        @person.remark = "Объявление №#{lost.id}"
      end
    end
    respond_to do |format|
      format.html { render action: 'edit' }
      format.xml { render xml: @person }
    end
  end

  # GET /people/1/edit
  def edit
    @person = Person.find(params[:id])
  end

  def extract_fuzzy_dates
    @permitted_params = (params.require(:person).permit!).to_hash
    extract_fuzzy_date(:lost_on, :lost_on_year, :lost_on_month, @permitted_params)
    extract_fuzzy_date(:birth_date, :birth_year, :birth_month, @permitted_params)
  end

  # hide_action :extract_fuzzy_dates

  def init_lost_id
    if @person.lost_id.blank? && !@person.full_name.blank? && lost = Lost.find_by_full_name(@person.full_name)
      @person.lost = lost
    end
  end

  # hide_action :init_lost_id

  def check_requests
    if @not_found_requests
      @person.errors.add :requests, "не могу найти: " + @not_found_requests.join(',')
    end
  end

  # hide_action :check_requests

  # POST /people
  # POST /people.xml
  def create
    if params[:cancel]
      flash[:info] = "Создание записи отменено"
      redirect_to(people_path)
    else
      @person = Person.new(@permitted_params)
      init_lost_id
      check_requests
      respond_to do |format|
        if @person.save
          flash[:info] = 'Запись на человека успешно создана.'
          format.html { redirect_to(@person) }
          format.xml { render xml: @person, status: :created, location: @person }
        else
          format.html { render action: "new" }
          format.xml { render xml: @person.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.xml
  def update
    @person = Person.find(params[:id])
    if params[:cancel]
      flash[:info] = "Изменение записи отменено"
      redirect_to @person
    else
      check_requests
      init_lost_id
      respond_to do |format|
        if @person.update(@permitted_params)
          flash[:info] = 'Запись на человека успешно обновлена.'
          format.html { redirect_to(@person) }
          format.xml { head :ok }
        else
          format.html { render action: "edit" }
          format.xml { render xml: @person.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.xml
  def destroy
    @person = Person.find(params[:id])
    # @person.destroy if @person
    @person.main = false
    @person.recent = false
    @person.save

    flash[:info] = "Запись удалена из списка"

    respond_to do |format|
      format.html { redirect_to(people_path) }
      format.xml { head :ok }
    end
  end

  # POST /people/1/props?main=1&recent=1
  def props
    @person = Person.find(params[:id])
    if @person
      old_main = @person.main
      old_recent = @person.recent

      @person.main = params[:main] if params[:main]
      @person.recent = params[:recent] if params[:recent]
      @person.save
      # @person.update_selected_attributes(:main, :recent) # PersonSweeper does not know about it

      msgs = []

      if old_main != @person.main
        if @person.main
          msgs << "Запись добавлена в основной список."
        else
          msgs << "Запись удалена из основного списка."
        end
      end

      if old_recent != @person.recent
        if @person.recent
          msgs << "Запись перенесена в горячий список."
        else
          msgs << "Запись удалена из горячего списка."
        end
      end

      flash[:info] = msgs.join(" ")
    else
      flash[:error] = "Не могу найти запись id=#{params[:id]} в списке."
    end

    respond_to do |format|
      format.html { redirect_to(@person) }
      format.xml { head :ok }
    end
  end

  # GET /people/list
  def list
    @title ||= "Список пропавших без вести"
    @wide_style = true

    cnds = conditions_from_params :person,
                                  sort_by: %w(id full_name last_address birth_year lost_on_year disappear_location anket_n),
                                  filter: %w(lost_on_year birth_year status recent main disappear_region),
                                  search_in: %w(full_name last_address disappear_location orig_record remark disappear_region),
                                  page: params[:page],
                                  per_page: params[:per_page] || 20

    cnds[:order] ||= 'id ASC'

    @people = Person.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
    if @people.size == 0 && @people.total_pages < cnds[:page].to_i
      cnds[:page] = @people.total_pages
      @people = Person.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
    end
  end
end

