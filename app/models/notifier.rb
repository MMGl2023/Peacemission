class Notifier < ActionMailer::Base

  unless defined? SITE_NAME
    SITE_NAME = HOST
  end

  @@cfg = APP_CONFIG['emails'] || {}
  @@cfg['admin'] ||= 'root@' + HOST
  @@cfg['to'] ||= @@cfg['admin']
  @@cfg['from'] ||= @@cfg['admin']
  @@cfg['reports_to'] ||= @@cfg['to']
  @@cfg['reports_from'] ||= @@cfg['from']
  @@cfg['requests_to'] ||= @@cfg['to']
  @@cfg['requests_from'] ||= @@cfg['from']
  

  # NB: name methods after names of actions after with the notification should happen
  #

  def signup(user)
    setup_email(user)
    @subject    += 'Подтвердждение регистрации'
    @body[:url]  = "http://#{HOST}/activate/#{user.activation_code}"
  end
  
  def activate(user)
    setup_email(user)
    @subject    += 'Ваш аккаунт был активирован!'
    @body[:url]  = "http://#{HOST}/signin"
  end
  
  def forgot_password(user)
    setup_email(user)
    @subject    += 'Восстановление пароля'
    @body[:url]  = "http://#{HOST}/reset_password/#{user.password_reset_code}"
  end
    
  def reset_password(user)
    setup_email(user)
    @subject    += 'Новый пароль'
    @body[:url]  = "http://#{HOST}/signin"
  end
  
  def invite_user(invitation)
    @subject      = "[#{SITE_NAME}] " + (invitation.subject.blank? ? invitation.subject : 'Вас пригласили стать пользователем сайта ' + SITE_NAME )
    @body[:invitation] = invitation
    @body[:url]   = "http://#{HOST}/signup/#{invitation.code}"
    @recipients   = invitation.email
    @from         = @@cfg['from']
    @sent_on      = Time.now
  end
  
  def report_bug(report)
    @subject       = "[BUG \##{report.id}] #{report.subject}"
    @body[:report] = report
    @from          = report.email || @@cfg['reports_from']
    @sent_on       = Time.now
    @recipients    = @@cfg['reports_to']
  end

  def report_info(report)
    @subject       = "[INFO \##{report.id}] #{report.subject}"
    @body[:report] = report
    @from          = report.email || @@cfg['reports_from']
    @sent_on       = Time.now
    @recipients    = @@cfg['reports_to']
  end

  def new_request(request)
    extend RequestsHelper
    @subject     = "[#{SITE_NAME}] New request / Новый запрос"
    @body[:req]  = request
    @recipients  = [@@cfg['requests_to']].flatten
    @recipients << request.email unless request.email.blank?
    @from        = @@cfg['requests_from']
    @sent_on     = Time.now
    logger.info [@from, @recipients, @sent_on].inspect
  end

  protected
    def setup_email(user)
      @recipients  = user.email
      @from        = @@cfg['from']
      @subject     = "[#{SITE_NAME}] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
