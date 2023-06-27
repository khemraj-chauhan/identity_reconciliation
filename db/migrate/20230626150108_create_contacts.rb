class CreateContacts < ActiveRecord::Migration[7.0]
  def change
    create_table :contacts do |t|
      t.string :phone_number
      t.string :email
      t.integer :linked_id
      t.string :link_precedence, default: "primary"

      t.timestamps
    end
  end
end
