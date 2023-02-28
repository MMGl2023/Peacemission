# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticationSystem
  include AuthorizationSystem
  include ControllerCacheMethods
  include FitemUploader
  include YacaphHelper

  # skip_before_action :verify_authenticity_token

  layout 'main'
  helper :all # include all helpers, all the time

  around_action :set_timezone
  around_action :set_comments_visibility


  TzTime.zone = TZInfo::Timezone.get('Europe/Moscow')

  # before_action :log_request_info

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery  :secret => 'ce59b34b607a0913bda77c5e69718dfwrfexx34rcfrf4f4grwetgd18'


  public

  def replace_html(message, target=nil)
    @target ||= target || params[:target]
    @text = message
    render :template => '/shared/replace_html', :rjs => true, :layout => false
  end

  protected

  def caching_allowed?
    request.get? &&
      (response.headers['Status']||200).to_i == 200 &&
        flash.blank?
  end

  def require_authentication?
    false
  end

  def set_comments_visibility
    cnds = {}
    cnds[:visibility] = [nil, 0] unless current_user
    Comment.where(cnds) do
      yield
    end
  end

  def set_timezone
    if current_user && !current_user.time_zone.blank?
      TzTime.zone = TZInfo::Timezone.get(current_user.time_zone)
    else
      TzTime.zone = TZInfo::Timezone.get('Europe/Moscow')
    end
    yield
    TzTime.reset!
  end

  def log_request_info
    [
      'HTTP_COOKIE',
      'HTTP_HOST'
    ].each do |p|
      logger.info p + ': ' + request.env[p].to_s
    end
  end

  def check_post
    unless request.post?
      @error = "Нельзя менять данные методом GET"
      rednder :file => 'shared/message'
    end
  end

  def redirect_to_index(msg = nil)
    if action_name == 'index' && self.class.name == 'TopicController'
      @info ||= flash.delete(:info) || msg
      @error ||= flash.delete(:error)
    else
      flash[:info] = msg if msg
      redirect_to :action => 'index', :controller => 'topic'
    end
  end


  public

  # does not work for caches_page -  flash emptyness is still not checked
  def self.caching_allowed(controller)
    controller.caching_allowed?
  end

  def remote?
    params[:remote] || request.xml_http_request?
  end
  # hide_action :remote?

  attr_accessor :submenu, :wide_style, :no_user_menu
  def user_menu?
    authenticated? && !@no_user_menu
  end

  def submenu?
    false
  end

  def _(x, y=nil)
    x
  end

  def make_authenticated_url(url)
    logger.info ['MA', url].inspect
    case url
    when '', '/', %r{^https?://[^\/]+/?$}
      '/i_auth/index'
    else
      url.sub(%r{/i/}, '/i_auth/')
    end
  end

  def make_unauthenticated_url(url)
    logger.info ['MUA', url].inspect
    url.sub(%r{_auth}, '').sub(%r{/topics/(.+)/edit}, '/i/\1')
  end

  def main_path()
    authenticated? ? '/i_auth/index' : '/'
  end

  def to_b(v)
    case v
    when '', nil, '0', 0
      false
    else
      true
    end
  end

  helper_methods = :submenu,
    :remote?, :submenu?,
    :sumbenu?, :wide_style, :user_menu?,
    :_,
    :make_authenticated_url, :make_unauthenticated_url,
    :main_path,
    :to_b

  # hide_action *helper_methods
  helper_method *helper_methods


  # COMMENTS STYSTEM
  # DOM id of div with object description and "Add comment" link
  def cdom_id(obj=nil)
    if obj
      obj.class.to_s + obj.id.to_s
    else
      params[:comment] ||= {}
      params[:comment][:obj_type].to_s + params[:comment][:obj_id].to_s
    end
  end

  # DOM id of div with comment && comments for object
  def wrapper_cdom_id(obj=nil)
    cdom_id(obj) + '_wrapper'
  end

  # DOM id of div with comments for objects
  def comments_cdom_id(obj=nil)
    cdom_id(obj) + '_comments'
  end
  # hide_action :comments_cdom_id, :wrapper_cdom_id, :cdom_id
  helper_method :comments_cdom_id, :wrapper_cdom_id,  :cdom_id

  def can_edit_comment?(c=nil)
    (cc = c || @comment) && (
      # logger.info "#{cc.session_id}: #{cc.ensure_author_name}"
      cc.session_id == session.id || has_permission?(:comments)
    )
  end
  helper_method :can_edit_comment?
  # hide_action :can_edit_comment?

  def can_edit_comment_required
    can_edit_comment? || access_denied("Нет прав для редактирования комментария")
  end
  # hide_action :can_edit_comment_required

  def page_for(obj, params)
    params[page_param_name_for(obj)]
  end

  def page_param_name_for(obj)
    cdom_id(obj) + '_page'
  end
  helper_method :page_for, :page_param_name_for
  # hide_action :page_for, :page_param_name_for
end

