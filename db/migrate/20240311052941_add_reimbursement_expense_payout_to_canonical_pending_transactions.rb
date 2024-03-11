# frozen_string_literal: true

class AddReimbursementExpensePayoutToCanonicalPendingTransactions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # The generated index name is too long, thus we need to specify a shorter
    # index name
    add_reference :canonical_pending_transactions, :reimbursement_expense_payout,
                  index: { algorithm: :concurrently, name: "index_canonical_pending_txs_on_reimbursement_expense_payout_id" }
  end
end
