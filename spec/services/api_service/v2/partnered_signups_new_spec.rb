# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiService::V2::PartneredSignupsNew, type: :model do
  let!(:event) { create(:event) }
  let(:partner) { event.partner }

  let(:partner_id) { partner.id }
  let(:organization_identifier) { "org_1234" }
  let(:redirect_url) { "http://example.com/redirect" }
  let(:webhook_url) { "http://example.com/webhook" }

  let(:service) do
    ApiService::V2::PartneredSignupsNew.new(
      partner_id:,
      organization_identifier:,
      redirect_url:,
      webhook_url:
    )
  end

  it "creates an organization" do
    expect do
      service.run
    end.to change(Event, :count).by(1)
  end

  it "creates with the redirect url" do
    event = service.run

    expect(event.redirect_url).to eql(redirect_url)
  end

  it "idempotently creates" do
    service.run

    expect do
      service.run
    end.to_not raise_error
  end

  context "when partner does not exist" do
    let(:partner_id) { "999999" }

    it "raises a 404" do
      expect do
        service.run
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when organization identifier exists" do
    let(:organization_identifier) { event.organization_identifier }

    it "does not create the event" do
      expect do
        service.run
      end.not_to change(Event, :count)
    end

    context "when for a different partner" do
      let(:partner_id) { create(:partner).id }

      it "does create the event" do
        expect do
          service.run
        end.to change(Event, :count).by(1)
      end
    end
  end
end
