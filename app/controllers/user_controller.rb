require 'tzinfo_timezone'
require 'digest/sha1'

class UserController < ApplicationController

  before_action :signin_if_not_yet, :except => [:signin, :signup, :forgot_password, :reset_password, :activate]

  protected

  def controls_authentication?
    # skip general scope authentication rules;
    # i will take care of it by myself
    true
  end

  public

  def find_user
    if params[:login]
      if params[:login].index('@')
        @user = User.find_by_email(params[:login])
      else
        @user = User.find_by_login(params[:login])
      end
    elsif params[:id]
      @user = User.find_by_id(params[:id])
    elsif params[:email]
      @user = User.find_by_email(params[:email])
    end
    flash[:error] = "Пользователь #{params[:login] || params[:email] || params[:id]} не найден"
    redirect_back_or_default('/')
  end

  def signin
    @title = "Вход в систему"
    if params[:login]
      if params[:login].index('@')
        @user = User.find_by_email(params[:login])
      else
        @user = User.find_by_login(params[:login])
      end
      if @user
        if @user.active?
          if User.authenticate(@user.login, params[:password])
            self.current_user = @user
            if !params[:redirect_to].blank?
              redirect_to params[:redirect_to]
            elsif flash[:redirect_to]
              redirect_to flash[:redirect_to]
            else
              redirect_to("/")
            end
          else
            @info = 'Неверный логин или пароль'
          end
        else
          @info = 'Данный аккаунт еще не подтверждён'
        end
      else
        @info = 'Неверный логин или пароль'
      end
    end
  end

  def signup
    @title = "Регистрация нового пользователя"
    code = (params[:user] ||= {})[:invitation_code] ||= params[:invitation_code]
    @user = User.new(params[:user])
    if @invitation = Invitation.find_by_code(code)
      @user.email ||= @invitation.email
      @user.full_name ||= @invitation.name
      @user.login ||= @user.full_name.to_login
    end

    if request.post?
      if defined?(ACCEPT_TOU_NEEDED) && ACCEPT_TOU_NEEDED
        if params[:accept_tou].nil?
          @error = 'Следует согласиться с условиями использования'
          render :action => 'signup'
          return
        end
      end

      if @user.save
        Notifier.deliver_signup(@user)
        flash[:info] = 'На ваш email было выслано письмо для подтверждения регистрации'
        redirect_to :action => 'signin'
        return
      end
    end
  end

  def logout
    reset_current_user
    if r = (params[:redirect_to] || session[:redirect_to])
      redirect_to r
    else
      redirect_to link_to_root
    end
  end

  # allows to view other users too
  def show
    if params[:id].to_i == current_user.id
      # User wants to see his home page
      redirect_to :action => 'index'
    elsif params[:id] && !(@user = User.find_by_id(params[:id])).nil?
      # user wants to see other user home page
      # in fact, normal users should be redirected to people_controller --
      # user_controller is for logged in users

      @voted_tracks = @user.last_voted(:track, 5)

      @title = "Данные пользователя " + @user.login unless @title
    else
      redirect_to :action => 'index'
    end
  end

  #
  def good_password?(p)
    #    (p.length > 4) &&
    #    (p =~ /[^a-z]/i) &&
    #    (p =~ /^[a-z0-9!@#$\%\^&*?\\\[\]\(\)_\+=\-]{5,9}$/i)i
    true
  end

  def can_edit?
    has_roles?(:admin) || current_user.id == @user.id
  end

  # hide_action :good_password?, :good_password?

  def edit
    @zones = TZInfo::Country.get('RU').zone_names.map { |x| TZInfo::Timezone.get(x) }
    params[:id] ||= current_user.id
    @user = User.find_by_id(params[:id])
    @title = "Редактирование профайла"

    if !@user
      flash[:error] = "Пользователь с id=:id не существует" % { :id => params[:id] }
      redirect_to :action => 'index'
      return
    end

    unless can_edit?
      flash[:error] = "Вы не можете менять персональные данные пользователя :user" % { :user => (@user.login rescue "") }
      redirect_to :action => 'index'
      return
    end

    if request.post?
      if params[:cancel]
        flash[:info] = "Изменение данных отменено"
        redirect_to :action => 'index'
        return
      end

      # TODO: rewrite it :-) rude DRY violation
      error = false
      if params[:user][:password].length > 0
        if User.authenticate(@user.login, params[:user][:current_password])
          @user.errors.add('current_password', 'Неверный текущий пароль')
        else
          new_password = params[:user][:password]
          if good_password?(new_password)
            @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
          else
            @user.errors.add('password', _('weak_password'))
          end
        end
      end

      if @user.errors.size == 0

        @user.update_attributes(params[:user].project(
          :first_name, :summary, :country, :state, :city, :zip_code,
          :gender, :birthday, :timezone, :ui_language, :preferred_bitrate
        ))

        @user.birthday = build_date_from_params(:birthday, params[:user])

        params[:user_langs] ||= {}
        @user.language = User.basic_languages.select { |l|
          params[:user_langs][l]
        }.join(', ') + ", " + (params[:user][:other_languages] || '')

        @user.ui_language = nil if @user.ui_language.blank?
        session[:lc_code] = @user.ui_language

        @user.string_gender = params[:user][:gender]

        # @user.interest_line = params[:user][:interest_line]
        if @user.save
          begin
            set_userpicture
            flash[:info] = _('personal_information_was_updated')
            redirect_to :action => 'index'
          rescue Exception => e
            logger.error "ERROR: Can't set user picture: #{e.to_s}\n#{e.backtrace.join("\n")}"
            @user.errors.add('picture', _('problems_with_user_picture') + ": #{e.message}")
          end
        end
      end
    end
  end

  def set_userpicture
    if @user
      case params[:user][:picture]
      when 'reset'
        @user.set_picture('')
      when 'upload'
        @user.set_picture(params[:user][:picture_file])
      end
    else
      nil
    end
  end

  # hide_action :set_userpicture

  def userpicture
    begin
      @user = User.find_by_id(params[:id])
      if can_change_userpicture?(@user)
        set_userpicture
        flash[:reload_pic_for] = @user.id
      else
        flash[:error] = _('you_have_no_permission_to_change_userpicture')
      end
      rescue => e
      @info = _('cant_change_userpicture') + ": #{e.message}\n#{e.backtrace[0..10].join("\n")}"
    else
      @info = _('userpicture_was_changed')
    end
    if params[:redirect_to]
      flash[:info] = @message
      redirect_to params[:redirect_to]
    else
      render :partial => 'userpicture_form'
    end
  end

  def forgot_password
    @title = "Восстановление пароля"
    if request.post?
      if find_user
        Notifier.deliver_forgot_password(u)
        flash[:info] = 'Письмо с инструкциями было выслано на почтовый ящик ' + @user.email + '.'
        redirect_to :action => 'signin', :login => @user.login
      end
    end
  end

  def reset_password
    if params[:c] != @user.to_hexdigest
      redirect_to :action => 'forgot_password'
    else
      password = ''
      chars = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!@$%^&()+=|\\<>,"
      (rand(4) + 6).times { password += chars[rand(chars.length - 1), 1] }

      @user.password = @user.password_confirmation = password
      @user.save!

      Notifier.deliver_reset_password(@user)

      flash[:info] = 'Пароль был послан Вам на почту'

      redirect_to :action => 'forgot_password'
    end
  end

  def invite
    unless check_permission :invitations
      flash[:info] = 'У вас нет прав для приглашения новых редакторов сайта'
      redirect_to :action => 'index'
    end

    p = (params[:invitation] || {}).project(:email, :name, :body, :subject)
    @default_subject = "Вас пригласил :name для работы над сайтом :host" % {
      :name => current_user.full_name,
      :host => request.host
    }

    @invitation = Invitation.new(p)

    if request.post?
      begin
        @invitation.created_by = current_user
        if @invitation.subject.blank?
          @invitation.subject = @default_subject
        end
        return unless @invitation.save
        rescue => e
        msg = 'Не могу создать приглашение' + ": #{e.message}\n#{e.backtrace.join("\n")}"
        logger.error msg
        flash[:error] = msg
        redirect_to :action => 'invite'
      else
        Notifier.deliver_invite_user(@invitation)
        flash[:info] = "Приглашение пользователю :user было отправлено. Можно создать ещё одно" % {
          :user => @invitation.name
        }
        redirect_to :action => 'invite'
      end
    else
      # get
      @host = request.host
      @invitation = Invitation.new(
        :body => '[YOUR TEXT]',
        :email => '[EMAIL]',
        :name => '[NAME]',
        :code => '[CODE]',
        :subject => @default_subject
      )
      @invitation.created_by = current_user
      @letter = render_to_string :template => 'notifier/invite_user', :layout => false
      @invitation = Invitation.new
    end
  end

  def activate
    redirect_to :action => 'signin' and return unless params[:id]
    begin
      @user = User.find(params[:id])
    rescue
      flash[:error] = "Пользователь не найден"
      redirect_to index_url
      return
    end

    redirect_to :action => 'signin' and return unless @user
    redirect_to :action => 'signin' and return if params[:activation_code] != @user.to_hexdigest

    @user.activate
    @user.hidden = false
    @user.save
    self.current_user = @user
    flash[:info] = 'Ваш аккаунт активирован'
    redirect_to :action => 'welcome'
  end

  def index
    view
    render :action => 'view'
  end

  def view
    @title = "Домашняя страница"
    @user = current_user
    render :layout => false if params[:partial]
  end
end
