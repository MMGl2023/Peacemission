class UsersController < ApplicationController

  # Protect these actions behind an admin login

  change_state_actions = [:suspend, :unsuspend, :destroy, :purge]

  before_action :find_user_or_current_or_access_denied, only: [:show, :edit, :update_image, :update]

  before_action :find_user_or_bad_request, only: change_state_actions

  # before_action :not_authenticated_required, only: [:create]

  before_action :authentication_required, only: [:home]

  require_permission :users, only: [:index, :destroy] + change_state_actions

  before_action :can_modify_user?, only: [:update, :edit, :update_image]

  protected

  # Checks if current user can modify found @user
  def can_modify_user?
    (@user && @user == current_user) ||
      has_permission?(:users) || access_denied('Нет прав для редактирования пользователя')
  end

  def find_user
    params[:email] ||= params[:login] if params[:login] && params[:login].index('@')
    @user = (
      (params[:id] && User.find_by_id(params[:id])) ||
        (params[:login] && User.find_by_login(params[:login])) ||
        (params[:email] && User.find_by_email(params[:emai]))
    )
  end

  def find_user_or_bad_request(msg = nil)
    find_user || bad_request(msg ||
                               "Пользователь #{params[:login] || params[:email] || params[:id]} не найден."
    )
  end

  def find_user_or_current_or_access_denied
    find_user || @user = current_user ||
      access_denied('Войдите в систему или укажите логин пользователя.')
  end

  public

  # GET /users
  # GET /users.xml
  def index
    list
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render xml: @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  # This action allows to view other user's pages
  def show
    @title = "Страница пользователя :user" % { user: @user.login }

    respond_to do |f|
      f.html # show.html.erb
      f.xml { render xml: @user }
    end
  end

  # GET /users/home
  # This action only allows users to view their own profile
  def home
    @user = current_user
    @title = ":user: моя домашняя страница" % { user: @user.login }
  end

  # GET /users/new
  # GET /users/new.xml
  # GET /signup/:invitation_code
  # register new user (signup)
  def new
    @user = User.new
    @user.invitation_code = params[:invitation_code]
    if !params[:invitation_code].blank? && @invitation = Invitation.find_by_code(params[:invitation_code])
      @user.email = @invitation.email
      @user.full_name = @invitation.name
    end

    respond_to do |f|
      f.html # new.html.erb
      f.xml { render xml: @user }
    end
  end

  # GET /users/1/edit
  def edit

  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    if params[:cancel]
      flash[:info] = 'Изменение данных отменено'
      redirect_to action: 'home'
      return
    end

    permitted_params = params.require(:user).permit!

    if permitted_params.dig(:password).present?
      unless User.authenticate(@user.login, permitted_params.delete(:current_password))
        @user.errors.add(:current_password, 'Неверный текущий пароль')
      end
    end

    if @user.errors.empty?
      @user.update(permitted_params)

      # For localization
      # if self.lc_code != @user.ui_lc  && lcs.has_key?(@user.ui_lc)
      #   self.lc_code = @user.ui_lc
      # end
    end

    respond_to do |f|
      if @user.errors.empty?
        f.html {
          flash[:info] = "Данные на пользователя '#{@user.login}' успешно обновлены"
          redirect_to(@user)
        }
        f.xml { head :ok }
      else
        f.html { render action: "edit" }
        f.xml { render xml: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /users/1/update_image
  # POST /users/1/update_image.xml
  def update_image
    upload_fitem(@user, :image, params: params[:fitem])
    case @error
    when nil
      respond_to do |f|
        f.html { redirect_back_or_default(user_path(@user)) }
        f.xml { head :ok }
      end
    else
      @error = @error.to_s.humanize
      @user.errors.add :image, @error
      respond_to do |f|
        f.html { render action: 'home' }
        f.xml { render xml: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /users
  # POST /users.xml
  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params.permit(:user)[:user] ||= {})

    if defined?(ACCEPT_TOU_NEEDED) && ACCEPT_TOU_NEEDED
      if params[:accept_tou].nil?
        @user.errors.add ['accept_tou', 'Для регистрации в системе вы должны согласится с условиями использования.']
      end
    end

    @user.register! if @user.valid?

    respond_to do |f|
      if @user.errors.empty?
        f.html {
          flash[:info] = 'Вам на почту было выслано письмо. Следуйте описанным в нём инструкциям.'
          redirect_to signin_path(:login => @user.login)
        }
        f.xml { render :xml => @user, :status => :created, :location => @user }
      else
        f.html { render :action => "new" }
        f.xml { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /activate/<activation_code>
  # GET /activate/<activation_code>.xml
  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if current_user
      if !current_user.active?
        current_user.activate!
        flash[:info] = "Пользователь '#{current_user.login}' был активирован."
      else
        flash[:info] = "Пользователь '#{current_user.login}' уже активирован."
      end
      redirect_to :action => 'home'
    else
      flash[:info] = 'Код активации недействителен. Попробуйте <a href=":url">зарегистрировать</a> нового пользователя' % {
        url: signup_path
      }
      redirect_to new_user_path
    end
  end

  def suspend
    @user.suspend!
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend!
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end

  def forgot_password
    @title = "Восстановление пароля"
    if request.post?
      find_user_or_bad_request("Пользователь не найден")
      if @user
        @user.forgot_password
        @user.save
        flash[:info] = 'Письмо с инструкциями было выслано на почтовый ящик ' + @user.email + '.'
      end
    end
  end

  def reset_password
    if !params[:password_reset_code].blank? && @user = User.find_by_password_reset_code(params[:password_reset_code])
      if request.get?
        # render reset_password
      else
        #  request.post?
        if params[:password]
          @user.password = params[:password]
          @user.password_confirmation = params[:password_confirmation]
        else
          @user.password = @user.password_confirmation = User.generate_password
        end
        logger.info "TRUE =" + (@user.password == @user.password_confirmation).inspect
        if @user.save && @user.reset_password
          flash[:info] = 'Новый пароль был выслан Вам на почтовый ящик'
          redirect_to signin_path(login: @user.login)
        else
          # @error = "Невозможно поменять пароль"
        end
      end
    else
      @error = "Некорректный код восстановления пароля"
    end
  end
end

# GET /users/list
def list
  @title ||= "Список пользователей сайта"
  @wide_style = true
  cnds = conditions_from_params :user,
                                sort_by: %w(id login city email),
                                filter: %w(city),
                                search_in: %w(login full_name email info),
                                page: params[:page],
                                per_page: params[:per_page] || 20

  @users = User.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
  if @users.size == 0 && @users.total_pages < cnds[:page].to_i
    cnds[:page] = @users.total_pages
    @users = User.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
  end
end

