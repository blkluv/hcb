class LoadCardRequest < ApplicationRecord
  include Rejectable

  belongs_to :card
  belongs_to :fulfilled_by, class_name: 'User', required: false
  belongs_to :creator, class_name: 'User'
  has_one :t_transaction, class_name: 'Transaction'

  validate :status_accepted_canceled_or_rejected

  scope :under_review, -> { where(rejected_at: nil, canceled_at: nil, accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :pending, -> do
    includes(:t_transaction)
      .accepted
      .where(
        emburse_transaction_id: nil,
        transactions: { id: nil }
      )
  end


  def status
    return 'completed' if accepted_at.present?
    return 'canceled' if canceled_at.present?
    return 'rejected' if rejected_at.present?
    'under review'
  end

  def under_review?
    rejected_at.nil? && canceled_at.nil? && accepted_at.nil?
  end

  include ApplicationHelper
  def description
    "#{self.id} (#{render_money self.load_amount}, #{time_ago_in_words self.created_at} ago, #{self.card.event.name})"
  end
end
