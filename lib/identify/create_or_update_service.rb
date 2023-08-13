module Identify
  class CreateOrUpdateService
    attr_reader :params
    attr_accessor :email_object, :phone_object

    def initialize(params)
      @params = params
      @email_object = params[:email].present? ? Contact.find_by(email: params[:email]) : nil
      @phone_object = params[:phone_number].present? ? Contact.find_by(phone_number: params[:phone_number]) : nil
    end

    def call
      if params[:phone_number].present? && params[:email].present?
        perform_on_email_and_phone
      elsif create_with_email_or_phone?
        create_contact
      end
      Contact.where(phone_number: params[:phone_number], email: params[:email]).primary.first
    end

    private

    def perform_on_email_and_phone
      if email_object.blank? && phone_object.blank?
        create_contact
      elsif email_object.present? && phone_object.present?
        decide_primary_or_secondary
      elsif phone_object.present?
        primary_secondary_create_update_based_on_phone
      elsif email_object.present?
        primary_secondary_create_update_based_on_email
      end
    end

    def create_contact
      Contact.create!(email: params[:email], phone_number: params[:phone_number])
    end

    def decide_primary_or_secondary
      if email_object.phone_number.present? && email_object.phone_number != params[:phone_number]
        decision_on_phone_object
      elsif phone_object.email.present? && phone_object.email != params[:email]
        decision_on_email_object
      elsif email_object.phone_number.blank? || phone_object.email.blank?
        if email_object.id < phone_object.id
          decision_on_email_object
        else
          decision_on_phone_object
        end
      end
    end

    def decision_on_email_object
      email_object.update!(phone_number: params[:phone_number], link_precedence: "primary", linked_id: nil)
      phone_object.update!(link_precedence: "secondary", linked_id: email_object.id)
    end

    def decision_on_phone_object
      phone_object.update!(email: params[:email], link_precedence: "primary", linked_id: nil)
      email_object.update!(link_precedence: "secondary", linked_id: phone_object.id)
    end

    def primary_secondary_create_update_based_on_phone
      binding.pry
      contacts = Contact.where(phone_number: params[:phone_number])
      if contacts.count > 1
        handle_multiple_secondary_phone_contacts(contacts)
      else
        handle_single_secondary_phone_contact
      end
    end

    def handle_multiple_secondary_phone_contacts(contacts)
      binding.pry
      update_link_precedence(contacts, "email")
      binding.pry
    end

    def handle_single_secondary_phone_contact
      if phone_object.email.blank?
        phone_object.update!(email: params[:email])
      else
        phone_object.update!(link_precedence: "secondary", linked_id: create_contact.id)
      end
    end

    def primary_secondary_create_update_based_on_email
      contacts = Contact.where(email: params[:email])
      if contacts.count > 1
        handle_multiple_secondary_email_contacts(contacts)
      else
        handle_single_secondary_email_contact
      end
    end

    def handle_multiple_secondary_email_contacts(contacts)
      update_link_precedence(contacts, "phone_number")
    end

    def update_link_precedence(contacts, check_for)
      binding.pry
      primary_contact = contacts.primary.first
      secondary_contact = contacts.secondary.find_by(check_for => nil)
      if secondary_contact.present?
        if check_for.eql?("email")
          secondary_contact.update!(
            email: params[:email], link_precedence: "primary", linked_id: nil
          )
        else
          secondary_contact.update!(
            phone_number: params[:phone_number], link_precedence: "primary", linked_id: nil
          )
        end
        primary_contact.update!(link_precedence: "secondary", linked_id: secondary_contact.id)
      else
        create_contact.reset_primary
      end
      contacts.reload
    end

    def handle_single_secondary_email_contact
      if email_object.phone_number.blank?
        email_object.update!(phone_number: params[:phone_number])
      else
        email_object.update!(link_precedence: "secondary", linked_id: create_contact.id)
      end
    end

    def create_with_email_or_phone?
      (params[:phone_number].present? && phone_object.blank?) ||
      (params[:email].present? && email_object.blank?)
    end
  end
end
