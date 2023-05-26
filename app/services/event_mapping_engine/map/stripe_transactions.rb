# frozen_string_literal: true

module EventMappingEngine
  module Map
    class StripeTransactions
      include ::TransactionEngine::Shared

      def initialize(start_date: nil)
        @start_date = start_date || last_1_month
      end

      def run
        RawStripeTransaction.where("date_posted >= ?", @start_date).find_each(batch_size: 100) do |raw_stripe_transaction|

          event_id = raw_stripe_transaction.likely_event_id

          next unless event_id # TODO: surface these somehow that have no likely event id

          canonical_transaction = raw_stripe_transaction.canonical_transaction

          next unless canonical_transaction # must be canon-ized already

          current_canonical_event_mapping = ::CanonicalEventMapping.find_by(canonical_transaction_id: canonical_transaction.id)

          ## Notify Airbrake if discrepancy in event that was being set
          if current_canonical_event_mapping.try(:event_id) && current_canonical_event_mapping.event_id != event_id
            Airbrake.notify("CanonicalTransaction #{canonical_transaction.id} already has an event mapping to event #{current_canonical_event_mapping.event_id} (but it seems like it should be mapped to event #{event_id})")
          end

          next if current_canonical_event_mapping

          attrs = {
            canonical_transaction_id: canonical_transaction.id,
            event_id: event_id,
            subledger_id: canonical_transaction.stripe_card.subledger_id,
          }
          ::CanonicalEventMapping.create!(attrs)
        end
      end

    end
  end
end
