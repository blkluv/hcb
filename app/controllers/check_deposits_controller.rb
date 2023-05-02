# frozen_string_literal: true

class CheckDepositsController < ApplicationController
  include SetEvent

  before_action :set_event

  def index
    @check_deposit = @event.check_deposits.build

    authorize @check_deposit

    @check_deposits = CheckDeposit.where(event: @event).order(created_at: :desc)
  end

  def create
    check_deposit = @event.check_deposits.build(check_deposit_params.merge(created_by: current_user))

    authorize check_deposit

    check_deposit.save!

    redirect_to check_deposit.local_hcb_code.url, flash: { success: "Your check deposit is on the way!" }
  end

  private

  def check_deposit_params
    params[:check_deposit][:amount_cents] = Monetize.parse(params[:check_deposit][:amount_cents]).cents
    params.require(:check_deposit).permit(:front, :back, :amount_cents)
  end

end
