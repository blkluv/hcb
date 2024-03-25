# frozen_string_literal: true

class CheckDepositPolicy < ApplicationPolicy
  def index?
    admin_or_user?
  end

  def create?
    admin_or_user? && !record.event.demo_mode? && !record.event.outernet_guild?
  end

  private

  def admin_or_user?
    user&.admin? || record.event.users.include?(user)
  end

  def user_who_can_transfer?
    user&.admin? || EventPolicy.new(user, record.event).new_transfer?
  end

end
