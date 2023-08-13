class IdentifyController < ApplicationController
	before_action :validate_params!
  before_action :validate_existing_object!

  def create
    response = Identify::ResponseService.new.call(Identify::CreateOrUpdateService.new(params).call)
    render json: { success: true, data: response, message: "success"}
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

  def validate_existing_object!
    contact = Contact.find_by(email: params[:email], phone_number: params[:phone_number])
    if contact.present?
      contact.reset_primary
      return render json: {
        success: true, data: Identify::ResponseService.new.call(contact), message: "success"
      }
    end
  end
end
