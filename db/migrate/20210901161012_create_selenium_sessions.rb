class CreateSeleniumSessions < ActiveRecord::Migration[6.0]
  def change
    create_table :selenium_sessions do |t|
      t.string :aasm_state
      t.jsonb :cookies
    end
  end
end
