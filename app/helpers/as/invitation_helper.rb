module As::InvitationHelper
  def send_inv_column(record)
    record.send_inv
  end

  def created_at_column(record)
    if record.created_at.blank?
      "-"
    else
      tz(record.created_at)
    end
  end

  def used_at_column(record)
    if record.used_at.blank?
      "-"
    else
      tz(record.used_at)
    end
  end

  def expired_at_column(record)
    if record.expired_at.blank?
      '-'
    elsif record.expired_at < Time.now
      "<b><font color=\"\#c00\">#{tz(record.expired_at)}</font></b>"
    else
      "<font color=\"\#0a0\">#{tz(record.expired_at)}</font>"
    end
  end
end
