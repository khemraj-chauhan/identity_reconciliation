class IdentifyController < ApplicationController
	before_action :validate_params!

  def create
    binding.pry
    if valid_for_creation?
		  contact = Contact.create!(email: params[:email], phone_number: params[:phone_number])
    else
      create_or_update
    end
    render json: { success: true, data: [], message: "success"}
  rescue StandardError => exception
    Rails.logger.error(exception)
    render json: { success: false, data: [], message: exception.message }
	end

	private

  def validate_params!
    if params[:email].blank? && params[:phone_number].blank?
      return render json: { success: false, data: [], message: "params are missing" }
    end
  end

  def valid_for_creation?
    Contact.where(email: params[:email]).or(Contact.where(phone_number: params[:phone_number])).blank?
  end

  def email_object
    Contact.find_by(email: params[:email])
  end

  def phone_object
    Contact.find_by(phone_number: params[:phone_number])
  end

  def create_or_update
    if valid_for_email_updation?
      if email_object.phone_number.blank?
        email_object.update!(phone_number: params[:phone_number])
      else
        Contact.create!(email: params[:email], phone_number: params[:phone_number], link_precedence: "secondary", linked_id: phone_object.id)
      end
    elsif valid_for_phone_number_updation?
      if phone_object.email.blank?
        phone_object.update!(email: params[:email])
      else
        Contact.create!(email: params[:email], phone_number: params[:phone_number], link_precedence: "secondary", linked_id: phone_object.id)
      end
    end

    # update secondary objects
    if phone_object.present? && phone_object.secondary? && phone_object.linked_id.eql?(email_object.id)
      phone_object.update!(email: params[:email])
    elsif email_object.present? && email_object.secondary? && email_object.linked_id.eql?(phone_object.id)
      email_object.update!(phone_number: params[:phone_number])
    end
  end

  def valid_for_email_updation?
    email_object.present? && phone_object.blank? && email_object.phone_number != params[:phone_number]
  end

  def valid_for_phone_number_updation?
    phone_object.present? && email_object.blank? && phone_object.email != params[:email]
  end
end
