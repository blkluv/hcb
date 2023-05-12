# frozen_string_literal: true

class ReceiptableMailer < ApplicationMailer
  default to: -> { @user.email },
          subject: -> { @subject }

  def receipt_report
    @user = User.includes(:stripe_cards).find params[:user_id]

    @feature_enabled = Flipper.enabled?(:receipt_report_2023_04_19, @user)

    @hcb_ids = params[:hcb_ids]
    @hcb_codes = HcbCode.where(id: @hcb_ids)
    @subject = "[WEEKLY] Missing #{"receipt".pluralize(@hcb_ids.size)} on Hack Club Bank"

    @show_flavor_text = Flipper.enabled?(:flavored_receipt_report_2023_05_12, @user)
    @flavor_text = flavor_text.sample if @show_flavor_text

    @show_org = @user.events.size > 1

    mail
  end

  private

  def flavor_text
    [
      # flavor text to put above list of missing receipts
      "You know what happens now!",
      "Don't tell the IRS!",
      "You monster!",
      "Receipts or it didn't happen!",
      "Better upload them or noone will believe you.",
      "Quick! Upload them before they go sour.",
      "Quick! Upload them before they expire.",
      "You're going to get in trouble!",
      "Just a little bit of accounting to go!",
    ]
  end

end
