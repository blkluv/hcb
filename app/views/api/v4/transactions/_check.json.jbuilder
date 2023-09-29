json.recipient_name check.recipient_name
json.memo check.memo
json.payment_for check.payment_for
json.status check.is_a?(IncreaseCheck) ? check.state_text.parameterize(separator: "_") : nil # TODO: handle statuses for old Lob checks
json.sender { json.partial! "api/v4/users/user", user: check.try(:creator) || check.try(:user) }
