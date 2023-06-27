class Contact < ApplicationRecord
	validates :phone_number, presence: { if: -> { email.blank? } }
	validates :email, presence: { if: -> { phone_number.blank? } }

	enum link_precedence: { primary: "primary", secondary: "secondary" }
end
