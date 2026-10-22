class AddressesController < ApplicationController
  include ErrorHandling

  def index
    address_input = Address::Input.new(full_address: params.expect(:search)).tap(&:validate!)
    @addresses = Address::Searcher.call(address_input)

    respond_to do |format|
      format.json { render "api/v1/addresses/index" }
    end
  end

  private

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
