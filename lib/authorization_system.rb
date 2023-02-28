#
# Extends AuthenticationSystem  (which allows just to identify user)
# AuthorizationSystem defines access level helper methods
# 
# See http://www.railsforum.com/viewtopic.php?id=14216&p=1  (Restful Authentication with all the bells and whistles)
# 
module AuthorizationSystem
  module ControllerClassMethods

  attr_accessor :controller_permissions, :controller_roles
  
  protected
    #
    # Example
    # class MyController < ActionController::Base
    #   require_role :advanced_user
    #   ....
    # end
    def require_role(*role)
      options = extract_options(role) || {}
      (@controller_roles ||= []).push(*role)
      before_filter :check_controller_role, options
    end
  
    # Example
    # class MyController < ActionController::Base
    #   require_permissions :advanced_user
    #   ....
    # end
    def require_permission(*permission)
      options = extract_options(permission) || {}
      (@controller_permissions ||= []).push(*permission)
      before_filter :check_controller_permission, options 
    end
  end

  attr_accessor :no_authentication_message, :no_authorization_message
    
  def no_authentication_message
    @no_authentication_message ||= "Необходимо войти в систему для досупа к этой странице."
  end
    
  def no_authorization_message
    @no_authorization_message ||= "Нет прав для доступа к указанной странице."
  end
      
  #Override this method in ApplicationController or in specific controller
  # if you want different default behaivour
  def require_authentication?
    false  # authentication IS NOT required by default for all actions
    # true # authentication IS     required by default for all actions
  end

  # Check if the user is authorized
  #
  # Override this method in your controllers if you want to restrict access
  # to only a few actions or if you want to check if the user
  # has the correct rights.
  #
  # Example:
  #
  #  # allow only nonbobs
  #  def authorized?
  #    current_user.login != "bob"
  #  end
  def authorized?
    authenticated?
  end

  # Filter method to enforce a login requirement.
  #
  # To require logins for all actions, use this in your controllers:
  #
  #   before_filter :authentication_required
  #
  # To require logins for specific actions, use this in your controllers:
  #
  #   before_filter :authentication_required, :only => [ :edit, :update ]
  #
  # To skip this in a subclassed controller:
  #
  #   skip_before_filter :authentication_required
  #
  def authentication_required
    authenticated? || not_authenticated_access_denied
  end
  alias :signin_if_not_yet :authentication_required

  def authentication_absence_required
    !authenticated? || access_denied
  end
 
  def authorization_required
    authorized? || access_denied
  end
  
  def authentication_required_if_require_authentication
    !require_authentication? || authenticated? ||  not_authenticated_access_denied
  end
    
  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authenticated.
  # Redirects to login page.
  def not_authenticated_access_denied(message=nil)
    message ||= no_authentication_message
    respond_to do |format|
      format.html do
        if remote?
          remote_message(message)
          return
        end
        flash[:error] = message
        redirect_to signin_url
      end
      format.any do
        request_http_basic_authentication 'Web Password'
      end
    end
  end

  def remote?
    params[:remote] != '0' && (params[:remote] == '1' || request.xml_http_request?)
  end

  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authenticated.
  # Redirects to referer page with message.
  def access_denied(message = nil, url = nil)      
    message ||= no_authorization_message
    respond_to do |format|
      format.html do
        if remote?
          remote_message(message)
          return
        end
        flash[:error] = message
        if url
          redirect_to url
        else
          #Put your domain name here ex. http://www.example.com
          domain_name = "http://#{HOST}"
          http_referer = session[:referer]
          if http_referer.nil?
            store_referer
            http_referer = ( session[:referer] || domain_name )
          end
          if http_referer.index(domain_name) == 0
            redirect_to_referer_or_default(root_path)  
          else
            session[:referer] = nil
            redirect_to root_path
          end
        end
      end
      format.xml do
        headers["Status"]           = "Unauthorized"
        headers["WWW-Authenticate"] = %(Basic realm="Web Password")
        render :text => message, :status => '401 Unauthorized'
      end
    end
  end

  def bad_request(message = nil, url = nil)
    message ||= 'Неверные параметры запроса'
    if remote?
      remote_message(message)
      return
    end
    if url
      flash[:error] = message
      redirect_to url
    else
      @error = message
      render :template => 'shared/message'
    end
  end

  def remote_message(message)
    render :update do |page|
      page << "if ( !$('message') ) {"
      page.insert_html :top, 'content', '<div id="message" style="position:absolute; left: 30%; top:100px;"></div>'
      page << "}"
      @notice = message
      page.replace 'message', :file => 'shared/message'
    end
  end

  # Store the URI of the current request in the session.
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:location] = request.request_uri
  end

  def store_referer
    session[:referer] = request.env["HTTP_REFERER"]
  end
  
  def requests_history
    @history ||= (session[:history] ||= [])
  end

  # You can put in any controller
  #   after_filter :store_requests_history
  def store_history
    if request.get? && !@history_stored       
      requests_history << request.request_uri 
      requests_history.unshift  if requests_history.size > 10
      @history_stored = true
    end
  end
  
  def add_request_to_history?
    response.status.to_i == 200
  end

  def previous_url
    requests_history.last
  end
  
  def make_authenticated_url(url)
    url.gsub('/i/', '/i_auth/')
  end

  def make_unauthenticated_url(url)
    url.gsub('_auth', '')
  end

  # Override this method in ApplicationController if you have different login url
  def signin_url
    url_for :controller=>'sessions', :action => 'new', :return_to => make_authenticated_url(request.request_uri)
  end 

  # Override this method in ApplicationController if you have different logout url
  def signout_url
    url_for :controller => 'sessions', :action => 'destroy', :return_to => make_unauthenticated_url(request.request_uri)
  end
  
  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    url = params[:return_to] || default
    redirect_to(authenticated? ? make_authenticated_url(url) : make_unauthenticated_url(url))
  end

  def redirect_to_referer_or_default(default)
    referer = session[:referer] || params[:referer] || request.env["HTTP_REFERER"]
    referer = default if referer.blank? || request.url == referer # || request.request_uri = referer
    session[:referer] = nil
  end
    
  def redirect_to_signin(message=nil)
    respond_to do |f|
      f.html do
        flash[:info] = message
        redirect_to signin_url
      end
      f.any do
        request_http_basic_authentication 'Web Password'
      end
    end
  end
  
  # Checks if current_user has all specified roles.
  def check_role(*roles)
    has_roles?(*roles) || access_denied
  end

  # Checks controller scope roles.
  def check_controller_role
    check_roles(*self.class.controller_roles)
  end

  # Checks if current_user has all specified permissionss.
  def check_permission(*permissions)
     has_permissions?(*permissions) || access_denied
  end

  # Checks controller scope permissions 
  def check_controller_permission
    check_permission(*self.class.controller_permissions)
  end
  
  def has_role?(*roles)
    roles.empty? || (
      current_user && roles.map(&:to_sym).all? {|r|
        current_user.has_role[r] || r == :any
      }
    )
  end
  alias :has_roles? :has_role?

  def has_permission?(*permissions)
    permissions.empty? || (
      current_user && permissions.map(&:to_sym).all? {|p|
        current_user.has_permission[p] || p == :any
      }
    )
  end
  alias :has_permissions? :has_permission?

  def self.included(klass)
    super
    klass.extend(ControllerClassMethods)
    klass.class_eval do
      before_filter :authentication_required_if_require_authentication
      # after_filter  :store_history # comment this line if you don't want to store history
    end
       
    klass.send(
      :helper_method, 
      :authorized?, 
      :user_menu?, 
      :previous_url, :history_requests,
      :signin_url, :signout_url, 
      :has_permission?, :has_permissions?,
      :has_role?, :has_roles?
    )
  end
end
  

