class DocumentPolicy < ApplicationPolicy
  def common_index?
    user.admin?
  end

  def index?
    return true if user.admin?
    return true if record.blank?

    event_ids = record.map(&:event).pluck(:id)
    same_event = event_ids.uniq.size == 1
    return true if same_event && user.events.pluck(:id).include?(event_ids.first)
  end

  def new?
    user.admin?
  end

  def create?
    user.admin?
  end

  def show?
    user.admin?
  end

  def edit?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def download?
    user.admin? || record.event.nil? || record.event.users.include?(user)
  end

  def fiscal_sponsorship_letter?
    !record&.is_spend_only && ( record.users.include?(user) || user.admin? )
  end
end
