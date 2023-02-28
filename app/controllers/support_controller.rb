class SupportController < ApplicationController
  OSES = [
      'Windows Vista', 'Windows XP', 'Windows 2003', 'Windows 2000', 'Windows 98',
      'Linux',
      'Macintosh',
      'Free BSD',
      'SymbianOS'
  ]

  BROWSERS = [
    'Internet Explorer 7.x',  'Internet Explorer 6.x', 'Internet Explorer 5.x',
    'Mozilla Firefox 1.x', 'Mozilla Firefox 2.x',
    'Opera 7.x', 'Opera 9.x', 'Opera 8.x',
    'Safari',
    'Konqueror'
  ]

  REPORT_TYPES = ['bug', 'info']

  # before_action :signin_if_not_yet, :except=>['tou']

  def controls_authentication?
    true
  end

  def index
    redirect_to :action => 'r'
  end

  def faq
    render_topic 'fac'
  end

  def tou
    render_topic 'tou'
  end

  def init_report
    @report = Report.new(
      (params[:report]||{}).project([:report_type, :os, :browser, :subject, :details, :email, :name])
    )
    @report.report_type ||=  params[:t] || 'info'
    @report.report_type = 'bug' unless REPORT_TYPES.include?(@report.report_type)
    if current_user
      @report.name ||=  current_user.login
      @report.email ||= current_user.email
    end
    @oses = OSES.map{|o| [o,o]}
    @browsers = BROWSERS.map{|o| [o,o]}
  end
  # hide_action :init_report

  def r
    init_report
    if request.post?
      begin
        @report.created_at = Time.now
        @report.user_id = current_user.id if current_user
        @report.save!
        ['file1', 'file2', 'file3'].each do |n|
          stream = params['report'][n] or break
          break if stream == ''
          f = ReportFitem.create_from(stream)
          f.user = current_user
          @report.file_items << f
        end
        @report.save!
        Notifier.send('deliver_report_' + @report.report_type, @report)
        flash[:info] = "Спасибо за Ваше сообщение ':subject'" % { :subject => @report.subject }
        redirect_to :action => 'r'
      rescue Exception => e
        logger.error "#{e.message}\n#{e.backtrace.join("\n")}";
        # TODO: hide errors in production
        flash[:error] = "#{e.message}\n#{e.backtrace.join("\n")}"
        (@report.destroy if @report) rescue nil
      end
    end
  end

  def change_report
    init_report
  end

  def report
    init_report
    render :action => 'report', :layout => false
  end

  # GET /support/list
  def list
    @title ||= "Список отзывов"
    @wide_style = true
    cnds = conditions_from_params :report,
       :sort_by   => %w(id report_type os browser name email),
       :filter    => %w(os browser name),
       :search_in => %w(os browser name subject details),
       :page      => params[:page],
       :per_page  => params[:per_page] || 20

    @reports = Report.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
    if @reports.size == 0 && @reports.total_pages < cnds[:page].to_i
      cnds[:page] = @reports.total_pages
      @people = Report.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
    end
  end
end
