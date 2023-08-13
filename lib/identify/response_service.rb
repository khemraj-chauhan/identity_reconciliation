module Identify
  class ResponseService
    attr_reader :primary_contact, :secondary_contacts

    def call(contact)
      return [] if contact.blank?

      initialize_attributes(contact)
      {
        contact: {
          primaryContatctId: primary_contact.id, emails: emails, phoneNumbers: phone_numbers,
          secondaryContactIds: secondary_contacts.pluck(:id)
        }
      }
    end

    private

    def initialize_attributes(contact)
      @primary_contact = contact.primary? ? contact : contact.primary_contact
      @secondary_contacts = primary_contact.secondary_contacts
    end

    def emails
      [primary_contact&.email, secondary_contacts.pluck(:email)].flatten.compact_blank.uniq
    end

    def phone_numbers
      [primary_contact&.phone_number, secondary_contacts.pluck(:phone_number)].flatten.compact_blank.uniq
    end
  end
end
