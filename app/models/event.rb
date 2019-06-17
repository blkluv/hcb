class Event < ApplicationRecord
  extend FriendlyId

  default_scope { order(id: :asc) }

  friendly_id :name, use: :slugged

  belongs_to :point_of_contact, class_name: 'User'

  has_many :organizer_position_invites
  has_many :organizer_positions
  has_many :users, through: :organizer_positions
  has_one :g_suite_application, required: false
  has_one :g_suite, required: false
  has_many :g_suite_accounts, through: :g_suite

  has_many :fee_relationships
  has_many :transactions, through: :fee_relationships, source: :t_transaction

  has_many :cards
  has_many :card_requests
  has_many :load_card_requests

  has_many :emburse_transactions

  has_many :sponsors
  has_many :invoices, through: :sponsors

  has_many :documents

  validate :point_of_contact_is_admin

  validates :name, :start, :end, :address, :sponsorship_fee, presence: true
  validates :slug, uniqueness: true, presence: true,  format: { without: /\s/ }

  before_create :default_values

  def self.pending_fees
    # minimum that you can move with SVB is $1
    select { | event | event.fee_balance > 100 }
  end

  def emburse_department_path
    "https://app.emburse.com/budgets/#{emburse_department_id}"
  end

  def emburse_budget_limit
    self.emburse_transactions.completed.where(emburse_card_id: nil).sum(:amount)
  end

  def emburse_balance
    completed_t = self.emburse_transactions.completed.sum(:amount)
    # We're including only pending charges on cards so organizers have a conservative estimate of their balance
    pending_t = self.emburse_transactions.pending.where('amount < 0').sum(:amount)
    completed_t + pending_t
  end

  def balance
    transactions.sum(:amount)
  end

  def lcr_pending
    lcrs = self.load_card_requests
    (lcrs.under_review + lcrs.accepted - lcrs.completed - lcrs.canceled - lcrs.rejected).sum(&:load_amount)
  end

  # used for load card requests, this is the amount of money available that isn't being transferred out by an LCR -tmb@hackclub
  def balance_available
    lcrs = self.load_card_requests
    balance - lcr_pending
  end
  alias_method :available_balance, :balance_available

  # amount incoming from paid Stripe invoices not yet deposited
  def pending_deposits
    # money that is pending payout- aka payout has not been created yet
    pre_payout = self.invoices.where(status: 'paid', payout: nil).sum(:payout_creation_balance_net)

    # money that has a payout created, but where the transaction has not hit the account yet / been associated with the pending payout
    payout_created = self.invoices.joins(payout: :t_transaction).where(status: 'paid', payout: { transactions: { id: nil } }).sum(:payout_creation_balance_net)

    pre_payout + payout_created
  end

  def billed_transactions
    transactions
      .joins(:fee_relationship)
      .where(fee_relationships: { fee_applies: true })
  end

  def fee_payments
    transactions
      .joins(:fee_relationship)
      .where(fee_relationships: { is_fee_payment: true })
  end

  # total amount over all time paid agains the fee
  def fee_paid
    # fee payments are withdrawals, so negate value
    -self.fee_payments.sum(:amount)
  end

  def fee_balance
    total_fees = self.billed_transactions.sum('fee_relationships.fee_amount')
    total_payments = self.fee_paid

    total_fees - total_payments
  end

  def balance_transacted_since_last_fee_payment
    date = self.fee_payments.first.date
    transactions = self.transactions.select { |t| t.date > date && t.fee_relationship.fee_applies }

    return 0 if transactions.size == 0
    return transactions.sum(&:amount)
  end

  def balance_being_withdrawn
    lcrs = self.load_card_requests
    return fee_balance + lcr_pending
  end

  def g_suite_status
    return :start if g_suite_application.nil?
    return :under_review if g_suite_application.under_review?
    return :app_accepted if g_suite_application.accepted? && g_suite.present?
    return :app_rejected if g_suite_application.rejected?
    return :verify_setup if !g_suite.verified?
    return :done if g_suite.verified?

    :start
  end

  def past?
    self.end < Time.current
  end

  def future?
    self.start > Time.current
  end

  def filter_data
    {
      exists: true,
      past: past?,
      future: future?
    }
  end

  private

  def default_values
    self.has_fiscal_sponsorship_document = true
  end

  def point_of_contact_is_admin
    return if self.point_of_contact&.admin?

    errors.add(:point_of_contact, 'must be an admin')
  end
end
