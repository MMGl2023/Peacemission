class AddMonthFields < ActiveRecord::Migration[6.0]
  @@flds = [
    [:losts, :lost_on_month],
    [:losts, :found_on_month],
    [:losts, :birth_month],
    [:people, :birth_month],
    [:people, :lost_on_month],
    [:requests, :lost_on_month],
    [:requests, :lost_birth_month]
  ]

  def self.up
    begin
      rename_column :people, :disappear_on, :lost_on
      rename_column :people, :disappear_year, :lost_on_year
      rename_column :requests, :lost_on_date, :lost_on

      # method reload! does not work in migration
    rescue => e
      puts "Second run will work"
    else
      raise RuntimeError, "Repeate db:migrate" # @todo: commented?
    end

    @@flds.each do |tbl, fld|
      date_fld = fld.to_s.sub('on_month', 'on').sub('birth_month', 'birth_date')
      add_column tbl, fld, :integer, :limit => 8
      tbl.to_s.camelize.singularize.constantize.all.each do |x|
        d = x.send(date_fld)
        x[fld] = d.month unless d.blank?
      end
    end
  end

  def self.down
    @@flds.each do |tbl, fld|
      remove_column tbl, fld rescue nil
    end
    rename_column :people, :lost_on, :disappear_on
    rename_column :people, :lost_on_year, :disappear_year
    rename_column :requests, :lost_on, :lost_on_date
  end
end
