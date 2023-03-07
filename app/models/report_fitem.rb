class ReportFitem < Fitem
  @sub_dir = 'reports'
  belongs_to :report, foreign_key: :owner_id, optional: true
end

