class AddressesController < ApplicationController
  include ErrorHandling

  def index
    address_input = Address::Input.new(full_address: params.expect(:full_address)).tap(&:validate!)
    @addresses = Address::Searcher.call(address_input)

    respond_to do |format|
      format.html
      format.json { render "api/v1/addresses/index" }
    end
  end

  private

  def render_error(message, status)
    respond_to do |format|
      format.html do
        @error = message
        render :index, status: status
      end
      format.json { render json: { error: message }, status: status }
    end
  end
end
