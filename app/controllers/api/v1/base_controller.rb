module Api
  module V1
    class BaseController < ActionController::API
      rescue_from ActionController::ParameterMissing do |error|
        render_error("#{error.param.to_s.humanize} is required", :bad_request)
      end

      rescue_from ActiveModel::ValidationError do |error|
        render_error(error.model.errors.full_messages.to_sentence, :bad_request)
      end

      private

      def render_error(message, status)
        render json: { error: message }, status: status
      end
    end
  end
end
