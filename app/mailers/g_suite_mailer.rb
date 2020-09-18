class GSuiteMailer < ApplicationMailer
  def notify_of_configuring
    @recipient = params[:recipient]
    @g_suite = GSuite.find(params[:g_suite_id])

    mail to: @recipient,
         subject: "[Action Requested] Your G Suite for #{@g_suite.domain} needs configuration"
  end

  def notify_of_verified
    @recipient = params[:recipient]
    @g_suite = GSuite.find(params[:g_suite_id])

    mail to: @recipient,
         subject: "[G Suite Verified] Your G Suite for #{@g_suite.domain} has been verified"
  end

end
