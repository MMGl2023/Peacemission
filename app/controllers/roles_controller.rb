class RolesController < ApplicationController

  # include RolesHelper

  before_action :signin_if_not_yet, :only => [:show, :destroy, :list]

  before_action :find_role, :only => [:edit, :update, :show, :destroy]
  before_action :check_authority, :only => [:edit, :update]

  ext_auto_complete_for_many :permission, :name,
                             :prefix => 'role', :out => :name,
                             :find => :find_permission_by_text,
                             :extract_before => [:create, :update]

  before_action :check_people, :only => [:create, :update]

  def find_permission_by_text(text)
    if text =~ /(\d+)/ && @permission = Permission.find_by_id($1)
      @permission
    else
      (@not_found_permissions ||= []) << text
      nil
    end
  end

  # hide_action :find_permission_by_text

  def check_permission
    @role ||= Role.new(params[:role])

    unless @not_found_permissions.blank?
      @role.errors.add 'people', "не могу найти :" + @not_found_permissions.join(', ')
    end
  end

  def allow_edit?
    has_permission?(:roles) || (@role && @role.session_id == session.id)
  end

  helper_method :allow_edit?

  protected

  def find_role
    @role = Role.find_by_id(params[:id]) or access_denied
  end

  def check_authority
    has_permission?(:roles) || (@role && @role.session_id == session.id) || access_denied
  end

  def extract_params
    extract_fuzzy_date(:lost_birth_date, :lost_birth_year, :lost_birth_month, params[:role])
    extract_fuzzy_date(:lost_on, :lost_on_year, :lost_on_month, params[:role])
  end

  public

  # GET /roles
  # GET /roles.xml
  def index
    list
    @wide_style = false
  end

  # GET /roles/list
  # GET /roles/list.xml
  def list

    @wide_style = true
    cnds2 = ""

    # store search string
    role_s = (params[:role_s] || "").dup

    cnds = conditions_from_params :role,
                                  :sort_by => %w(created_at id lost_full_name role_type),
                                  :search_in => %w(lost_full_name full_name address role_type contacts phone_number),
                                  :default_order => 'created_at DESC',
                                  :filter => %w(role_type),
                                  :page => params[:page],
                                  :per_page => params[:per_page] || 20

    @roles = Role.where(cnds2).where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)

    # restore search string
    params[:role_s] = role_s

    respond_to do |format|
      format.html #  list.html or index.html.erb
      format.xml { render :xml => @roles }
    end
  end

  # GET /roles/1
  # GET /roles/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @role }
    end
  end

  # GET /roles/new
  # GET /roles/new.xml
  def new
    @role = Role.new(params[:role])
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @role }
    end
  end

  # GET /roles/1/edit
  def edit
    @title = "Редактирование запроса"
    @submit_text = "Обновить"
    render :action => 'new'
  end

  # POST /roles
  # POST /roles.xml
  def create
    @role ||= Role.new(params[:role])

    respond_to do |format|
      if @role.save
        Notifier.send('deliver_new_role', @role)
        flash[:info] = 'Запрос успешно создан.'
        format.html { redirect_to(@role) }
        format.xml { render :xml => @role, :status => :created, :location => @role }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /roles/1
  # PUT /roles/1.xml
  def update
    @role.session_id = session.id rescue nil

    respond_to do |format|
      if @role.update_attributes(params[:role])
        flash[:info] = 'Запрос успешно обновлён.'
        format.html { redirect_to(@role) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.xml
  def destroy
    @role.destroy

    respond_to do |format|
      format.html { redirect_to(roles_url) }
      format.xml { head :ok }
    end
  end
end

