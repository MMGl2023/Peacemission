# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  # =signin form
  def new
    if authenticated?
      if !flash[:double_signin]
        redirect_back_or_default('/i_auth/index')
        flash[:double_signin] = '1'
      end
    end
  end

  # signin post
  def create
    user = User.authenticate(params[:login], params[:password])
    if user
      if params[:remember_me] == "1"
        user.remember_me unless user.remember_token?
        cookies[:auth_token] = { :value => user.remember_token , :expires => user.remember_token_expires_at }
      end
      self.current_user = user
      flash[:info] = "Вы успешно вошли в систему."
      redirect_back_or_default('/i_auth/index')
    else
      flash[:error] = "Неверный логин или пароль."
      redirect_to :action=>'new'
    end
  end

  # signout
  def destroy
    current_user.forget_me if current_user
    cookies.delete :auth_token
    signout
    flash[:info] = "Вы вышли из системы."
    params[:return_to] ||= request.env['HTTP_REFERER'] if request.env['HTTP_REFERER'] =~ %r{(https?://(www.)?rozysk.org)?(/|$).+}
    redirect_back_or_default('/')
  end
end

