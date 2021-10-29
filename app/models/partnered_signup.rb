# frozen_string_literal: true

class PartneredSignup < ApplicationRecord
  has_paper_trail

  include PublicIdentifiable
  set_public_id_prefix :sup

  belongs_to :partner, required: true
  belongs_to :event,   required: false
  belongs_to :user,    required: false

  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :rejected, -> { where.not(rejected_at: nil) }
  scope :unsubmitted, -> { where(submitted_at: nil) }
  scope :submitted, -> { where.not(submitted_at: nil) }

  validates :redirect_url, presence: true
  validate :not_accepted_and_rejected
  validates_presence_of [:organization_name,
                         :owner_name,
                         :owner_email,
                         :owner_phone,
                         :owner_address,
                         :owner_birthdate
                        ], unless: :unsubmitted?

  def continue_url
    Rails.application.routes.url_helpers.api_connect_continue_api_v1_index_url(public_id: public_id)
  end

  def unsubmitted?
    self.submitted_at.nil?
  end

  private

  def not_accepted_and_rejected
    if accepted_at && rejected_at
      errors.add(:base, "Cannot be both accepted and rejected")
    end
  end
end
