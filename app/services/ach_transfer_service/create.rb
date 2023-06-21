# frozen_string_literal: true

module AchTransferService
  class Create
    include ::Shared::AmpleBalance

    def initialize(event_id:,
                   routing_number:, account_number:, bank_name:, recipient_name:, recipient_tel:, amount_cents:, payment_for:,
                   current_user:, scheduled_on:)
      @event_id = event_id

      @routing_number = routing_number
      @account_number = account_number
      @bank_name = bank_name
      @recipient_name = recipient_name
      @recipient_tel = recipient_tel
      @amount_cents = amount_cents
      @payment_for = payment_for
      @scheduled_on = scheduled_on

      @current_user = current_user
    end

    def run
      raise ArgumentError, "You don't have enough money to send this transfer." unless ample_balance?(@amount_cents, event)

      ach_transfer = AchTransfer.create!(create_attrs)

      unless ach_transfer.scheduled_on.present? # don't add this ACH to the ledger if it's scheduled for the future
        ActiveRecord::Base.transaction do
          rpoat = PendingTransactionEngine::RawPendingOutgoingAchTransactionService::OutgoingAch::ImportSingle.new(ach_transfer:).run
          pt = PendingTransactionEngine::CanonicalPendingTransactionService::ImportSingle::OutgoingAch.new(raw_pending_outgoing_ach_transaction: rpoat).run
          PendingEventMappingEngine::Map::Single::OutgoingAch.new(canonical_pending_transaction: pt).run
        end
      end
    end

    private

    def create_attrs
      {
        event:,

        routing_number: @routing_number,
        account_number: @account_number,
        bank_name: @bank_name,
        recipient_name: @recipient_name,
        recipient_tel: @recipient_tel,
        amount: @amount_cents,
        payment_for: @payment_for,
        scheduled_on: @scheduled_on,

        creator: @current_user
      }
    end

    def event
      @event ||= Event.find(@event_id)
    end

  end
end
