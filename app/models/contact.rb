class Contact < ApplicationRecord
	validates :phone_number, presence: { if: -> { email.blank? } }
	validates :email, presence: { if: -> { phone_number.blank? } }

	enum link_precedence: { primary: "primary", secondary: "secondary" }

	belongs_to :primary_contact, class_name: "Contact", foreign_key: :linked_id, optional: true

	has_many :secondary_contacts, class_name: "Contact", foreign_key: :linked_id

	def reset_primary
		contacts = Contact.where(email: self.email).or(Contact.where(phone_number: self.phone_number))
		return if contacts.blank?

		contacts.where.not(id: self.id).update_all(link_precedence: "secondary", linked_id: self.id)
		self.update(link_precedence: "primary", linked_id: nil)
	end
end
