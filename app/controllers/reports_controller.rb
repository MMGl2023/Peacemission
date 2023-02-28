class ReportsController < ApplicationController

  before_action :signin_if_not_yet, except: %i[new create]
  # require_permission :reports, except: %i[new create]

  before_action :find_report, only: %i[show edit update destroy]

  OSES = [
    'Windows Vista', 'Windows XP', 'Windows 2003', 'Windows 2000', 'Windows 98',
    'Linux',
    'Macintosh',
    'Free BSD',
    'SymbianOS'
  ]

  BROWSERS = [
    'Internet Explorer 7.x', 'Internet Explorer 6.x', 'Internet Explorer 5.x',
    'Firefox 1.x', 'Firefox 2.x', 'Firefox 3.x',
    'Opera 7.x', 'Opera 9.x', 'Opera 8.x',
    'Safari',
    'Konqueror'
  ]

  REPORT_TYPES = ['bug', 'info']

  protected

  def find_report
    @report = Report.find_by_id(params[:id]) or bad_request("Не могу найти указанный отзыв")
  end

  def init_report
    @report = Report.new(
      (params[:report] ? params[:report].to_unsafe_h : {}).project([:report_type, :os, :browser, :subject, :details, :email, :name])
    )
    @report.report_type ||= params[:t] || 'info'
    @report.report_type = 'bug' unless REPORT_TYPES.include?(@report.report_type)
    if current_user
      @report.name ||= current_user.login
      @report.email ||= current_user.email
    end
    @report.created_at = Time.now
    @report.user_id = current_user.id if current_user
  end

  # hide_action :init_report

  public

  def controls_authentication?
    true
  end

  def index
    redirect_to action: 'new'
  end

  # GET /reports/new
  def new
    init_report
    @oses = OSES.map { |o| [o, o] }
    @browsers = BROWSERS.map { |o| [o, o] }
    if remote?
      render action: 'edit', layout: false
    end
  end

  # GET /reports/1/edit
  def edit
    @oses = OSES.map { |o| [o, o] }
    @browsers = BROWSERS.map { |o| [o, o] }
  end

  def upload_files
    find_report unless @report
    return unless params[:report_fitems].present?
    ['file1', 'file2', 'file3'].each do |n|
      stream = params[:report_fitems][n] or break
      break if stream == ''
      f = ReportFitem.create_from(stream)
      f.user = current_user
      @report.fitems << f
    end
  end

  # PUT /reports
  def create
    init_report
    if @report.save
      upload_files
      @report.save
      respond_to do |format|
        format.html {
          flash[:info] = "Спасибо за Ваше сообщение ':subject'" % { subject: @report.subject }
          redirect_to new_report_path
        }
      end
    else
      respond_to do |format|
        format.html { render action: 'new' }
        format.xml { render xml: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /report/1
  def update
    @report.update(params.require(:report).permit!)
    if @report.save
      upload_files
      @report.save
      respond_to do |format|
        format.html {
          flash[:info] = "Данные отзыва обновлены"
          redirect_to report_path(@report)
        }
        format.xml { head :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to edit_report(@report) }
        format.xml { render xml: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /reports/1
  def show

  end

  # GET /reports/
  def index
    list
    respond_to do |format|
      format.html { render action: 'list' }
      format.xml { render xml: @reports }
    end
  end

  # DEL /report/1
  def destroy
    @report.destroy
    respond_to do |format|
      format.html {
        flash[:info] = "Отзыв был удален"
        redirect_to action: 'list'
      }
      format.xml { head :ok }
    end
  end

  # GET /support/list
  def list
    @title ||= "Список отзывов"
    @wide_style = true
    cnds = conditions_from_params :report,
                                  sort_by: %w(id report_type os browser name email),
                                  filter: %w(os browser name report_type),
                                  search_in: %w(os browser name subject details report_type),
                                  default_order: 'created_at DESC',
                                  page: params[:page],
                                  per_page: params[:per_page] || 20

    @reports = Report.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
    if @reports.size == 0 && @reports.total_pages < cnds[:page].to_i
      cnds[:page] = @reports.total_pages
      @reports = Report.where(cnds.delete(:conditions)).order(cnds.delete(:order)).paginate(cnds)
    end
  end
end
