# frozen_string_literal: true

class AchTransferPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end

  def new?
    is_public? || user_who_can_transfer?
  end

  def create?
    user_who_can_transfer? && !record.event.demo_mode && !record.event.outernet_guild?
  end

  def show?
    # Semantically, this should be admin_or_manager?, right?
    is_public? || user_who_can_transfer?
  end

  def view_account_routing_numbers?
    admin_or_manager?
  end

  def cancel?
    user_who_can_transfer?
  end

  def transfer_confirmation_letter?
    user_who_can_transfer?
  end

  def start_approval?
    user&.admin?
  end

  def approve?
    user&.admin?
  end

  def reject?
    user&.admin?
  end

  private

  def user_who_can_transfer?
    user&.admin? || EventPolicy.new(user, record.event).new_transfer?
  end

  def admin_or_manager?
    user&.admin? || OrganizerPosition.find_by(user:, event: record.event)&.manager?
  end

  def is_public?
    record.event.is_public?
  end

end
