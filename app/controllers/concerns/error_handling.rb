module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::ParameterMissing do |error|
      render_error("#{error.param.to_s.humanize} is required", :bad_request)
    end

    rescue_from ActiveModel::ValidationError do |error|
      render_error(error.model.errors.full_messages.to_sentence, :bad_request)
    end

    rescue_from Address::Fetcher::ServiceError, Forecast::Fetcher::ServiceError do |error|
      render_error(error.message, :bad_gateway)
    end
  end
end
