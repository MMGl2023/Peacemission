class ReportObserver < ActiveRecord::Observer
  def after_create(report)
    type = (report.report_type == 'info') ? 'info' : 'bug'
    Notifier.send('deliver_report' + type)
  end
end
