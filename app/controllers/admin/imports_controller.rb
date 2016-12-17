class Admin::ImportsController < ApplicationController
  before_action :check_params, only: [:download]
  before_action :set_import, only: [:view]

  def download
    import = Import.create({ status: 'created',
                             imported_type: Import::IMPORTED_TYPE[import_params[:type].to_sym] })

    redirect_to(controller: :users, action: :index)
  end

  def view
    @elements = @import.elements.page(params[:page]).per(25)
  end

  private

  def set_import
    @import = Import.find_by_id(params[:id])
  end

  def import_params
    params.permit([:type])
  end

  def check_params
    allowed_values = Import::IMPORTED_TYPE.keys.map(&:to_s)
    raise ArgumentError unless allowed_values.include?(import_params[:type])
  end
end