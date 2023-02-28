class InvitationObserver < ActiveRecord::Observer
  def after_create(invitation)
    Notifier.deliver_invite_user(invitation)
  end
end
