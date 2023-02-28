module ControllerCacheMethods
  def caches_action_unless_auth(*actions)
    options = actions.pop if actions.last.is_a?(Hash)
    @@check_auth_count ||= 0
    before_method = "check_auth_methods_#{(@@check_auth_count += 1)}".to_sym
    self.class_eval do
      define_method(before_method) do
        if current_user
          self.action_name += '_auth'
        end
      end
      actions.each do |action|
        define_method(action.to_s + '_auth') do
          self.send(action)
          render :action=>action unless performed?
        end
      end
    end
    before_action before_method, :only => actions
    actions << options if options
    caches_action *actions
    before_method
  end

  # Methods for tagging fragment cache (see conditional caching plugin)

  # login
  def login_tag
    '/u-' + (current_user ? current_user.login : '')
  end

  # logged_in?
  def auth_tag
    authenticated? ?  '/auth-yes' : '/auth-no'
  end

  # /<action>/<login_tag>/p-<page_number>
  def action_and_login_and_page_tag
    '/' + action_name + login_tag + '/p-' + params[:page].to_i.to_s
  end
end

