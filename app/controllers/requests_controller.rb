# @request cant be used - its reserved for HTTP request object; use @req instead

class RequestsController < ApplicationController

  include RequestsHelper

  before_action :signin_if_not_yet, :only => [:show, :destroy, :list]
  before_action :find_request, :only => [:edit, :update, :show, :destroy]
  before_action :check_authority, :only => [:edit, :update, :destroy]
  before_action :extract_params, :check_create_authority,  :only => [:new, :update, :create]

  ext_auto_complete_for_many :person, :full_name,
    :prefix   => 'request',
    :out      => :signature,
    :extract_before => [:create, :update], # before_action
    :find     => :find_person_by_text

  before_action :check_people, :only => [:create, :update]

  protected

  def find_person_by_text(text)
    (
      text =~ /^(№|N)?(\d+)(\D|$)\s*/ and Person.find_by_id($2)
    ) or (
      Person.find_by_full_name(text.gsub(/^.\d+[\-\s]*|\s*$/))
    ) or (
      (@not_found_people ||= []) << text
      nil
    )
  end

  # check that all specified names for association request-has-many-people work
  # (see how names works in find_preson_by_text)
  def check_people
    @req ||= Request.new(params[:request])

    unless @not_found_people.blank?
      @req.errors.add 'people', "не могу найти :" + @not_found_people.join(', ')
    end
  end

  def allow_edit?
    (has_permission?(:requests) && !has_permission?(:viewer)) ||
    (@req && @req.session_id == session.id)
  end
  helper_method :allow_edit?

  def allow_create?
    has_permission?(:requests) && !has_permission?(:viewer)
  end
  helper_method :allow_edit?

  def find_request
    @req = Request.find_by_id(params[:id]) or access_denied
  end

  def check_authority
    allow_edit? || access_denied
  end

  def check_create_authority
    allow_create? || access_denied
  end

  def extract_params
    extract_fuzzy_date(:lost_birth_date, :lost_birth_year, :lost_birth_month, params[:request])
    extract_fuzzy_date(:lost_on, :lost_on_year, :lost_on_month, params[:request])
  end

  public

  # GET /requests
  # GET /requests.xml
  def index
    list
    @wide_style = false
  end

  # GET /requests/list
  # GET /requests/list.xml
  def list

    @wide_style = true
    cnds2 = ""

    # store search string
    request_s = (params[:request_s]||"").dup

    if params[:request_type].blank?
      types = []
      search_for = (params[:request_s] || "")
      request_short_types.each {|k,v|
        types << k if search_for.gsub!(/#{v}/i,'')
      }
      cnds2 = "request_type IN (#{types.join(', ')})" unless types.empty?
    end

    cnds = conditions_from_params :request,
      :sort_by    => %w(created_at id lost_full_name request_type),
      :search_in  => %w(lost_full_name full_name address request_type contacts phone_number),
      :default_order => 'created_at DESC',
      :filter     => %w(request_type),
      :page       => params[:page],
      :per_page   => params[:per_page] || 20

    @reqs = Request.where(cnds2).where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)

    # restore search string
    params[:request_s] = request_s

    respond_to do |format|
      format.html #  list.html or index.html.erb
      format.xml  { render :xml => @reqs }
    end
  end

  # GET /requests/1
  # GET /requests/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @req }
    end
  end


  # GET /requests/new
  # GET /requests/new.xml
  def new
    @req = Request.new(params[:request])
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @req }
    end
  end

  # GET /requests/1/edit
  def edit
    @title = "Редактирование запроса"
    @submit_text = "Обновить"
    render :action => 'new'
  end

  # POST /requests
  # POST /requests.xml
  def create
    @req ||= Request.new(params[:request])

    respond_to do |format|
      if @req.save
        Notifier.send('deliver_new_request', @req)
        flash[:info] = 'Запрос успешно создан.'
        format.html { redirect_to(@req) }
        format.xml  { render :xml => @req, :status => :created, :location => @req }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @req.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /requests/1
  # PUT /requests/1.xml
  def update
    @req.session_id = session.id rescue nil

    respond_to do |format|
      if @req.update_attributes(params[:request])
        flash[:info] = 'Запрос успешно обновлён.'
        format.html { redirect_to(@req) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @req.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /requests/1
  # DELETE /requests/1.xml
  def destroy
    @req.destroy

    respond_to do |format|
      format.html { redirect_to(requests_url) }
      format.xml  { head :ok }
    end
  end
end

