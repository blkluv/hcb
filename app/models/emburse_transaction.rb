class EmburseTransaction < ApplicationRecord
  include Receiptable

  enum state: %w{pending completed declined}

  acts_as_paranoid
  validates_as_paranoid

  paginates_per 100

  scope :undeclined, -> { where.not(state: 'declined') }
  scope :under_review, -> { where(event_id: nil).undeclined }
  scope :awaiting_receipt, -> { includes(:receipts).completed.where.not(amount: 0).where(receipts: { receiptable_id: nil}) }
  scope :unified_list, -> { undeclined }

  belongs_to :event, required: false
  belongs_to :emburse_card, required: false
  alias_attribute :card, :emburse_card

  has_many :comments, as: :commentable

  validates_uniqueness_of_without_deleted :emburse_id

  def awaiting_receipt?
    !amount.zero? && approved && receipts.size.zero?
  end

  def self.during(start_time, end_time)
    self.where(["emburse_transactions.transaction_time >= ? and emburse_transactions.transaction_time <= ?", start_time, end_time])
  end

  def memo
    @memo ||= begin
      return 'Transfer from bank account' if amount > 0

      merchant_name || 'Transfer back to bank account'
    end
  end

  def transfer?
    @transfer ||= amount > 0 || merchant_name.nil?
  end

  def under_review?
    self.event_id.nil? && undeclined?
  end

  def undeclined?
    state != 'declined'
  end

  def completed?
    state == 'completed'
  end

  def emburse_path
    "https://app.emburse.com/transactions/#{emburse_id}"
  end

  def filter_data
    {
      exists: true,
      fee_applies: false,
      fee_payment: false,
      card: true
    }
  end

  def status_badge_type
    s = state.to_sym
    return :success if s == :completed
    return :error if s == :declined

    :pending
  end

  def status_text
    s = state.to_sym
    return 'Completed' if s == :completed
    return 'Declined' if s == :declined

    'Pending'
  end

  def is_transfer?
    amount > 0 && merchant_name.nil?
  end

  def self.total_emburse_card_transaction_volume
    -self.where('amount < 0').completed.sum(:amount)
  end

  def self.total_emburse_card_transaction_count
    self.where('amount < 0').completed.size
  end
end
