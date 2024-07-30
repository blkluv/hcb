# frozen_string_literal: true

# == Schema Information
#
# Table name: logins
#
#  id                     :bigint           not null, primary key
#  aasm_state             :string
#  browser_token          :string
#  authentication_factors :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :bigint           not null
#  user_session_id        :bigint
#
# Indexes
#
#  index_logins_on_user_id          (user_id)
#  index_logins_on_user_session_id  (user_session_id)
#
class Login < ApplicationRecord
  include AASM
  include Hashid::Rails

  belongs_to :user
  belongs_to :user_session, optional: true

  has_secure_token :browser_token

  store :authentication_factors, accessors: [:sms, :email, :webauthn, :totp], prefix: :authenticated_with

  has_paper_trail

  validate do
    if user_session.present? && !complete?
      # how did we create session when it's not complete?!
      Airbrake.notify("An incomplete login #{id} has a session #{session.id} present.")
      errors.add(:base, "An incomplete login has a session present.")
    end
  end

  validate do
    if user_session.present? && user_session.user != user
      Airbrake.notify("A login with a session present has a session.user (#{session.user.id}) / user (#{user.id}) mismatch.")
      errors.add(:base, "A login with a session present has a session.user / user mismatch.")
    end
  end

  aasm do
    state :incomplete, initial: true
    state :complete

    event :mark_complete do
      transitions from: :incomplete, to: :complete do
        guard do
          authentication_factors_count == (user.using_2fa? ? 2 : 1)
        end
      end
    end
  end

  before_save do
    mark_complete! if may_mark_complete?
  end

  def authentication_factors_count
    authentication_factors.values.count(true)
  end

end
