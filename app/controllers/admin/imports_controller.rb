class Admin::ImportsController < ApplicationController
  before_action :check_params, only: [:download]
  before_action :set_import, only: [:show, :destroy]

  def download
    import = Import.find_or_create_by(imported_type: Import.imported_type_value_for?(import_params[:type].to_sym),
                                      user_id: current_user.id)
    import.set_status!(:created)                          

    redirect_to(controller: :users, action: :index)
  end

  def download_all
    import = Import.find_or_create_by(imported_type: Import.imported_type_value_for?(import_params[:type].to_sym),
                                      user_id: current_user.id)
    import.clean_elements!
    import.set_status!(:created)

    redirect_to(controller: :users, action: :index)
  end

  def destroy
    @import.clean_elements!
    @import.set_status!(:deleted)

    redirect_to(controller: :users, action: :index)
  end

  def show
    @elements = @import.elements.page(params[:page]).per(25)
  end

  def show_full_data
    id = full_data_params[:id]
    @type = full_data_params[:type]

    @data = current_user.stripe_retrieve(id, @type)

    respond_to do |format|
      format.js
    end
  end

  def data_by_month
    import = Import.where(imported_type: Import.imported_type_value_for?(:charges))
                   .where(user_id: current_user.id)
                   .limit(1).first

    @data = import.nil? ? nil : import.month_statistics
  end

  def averages_year
    import = Import.where(imported_type: Import.imported_type_value_for?(:charges))
                   .where(user_id: current_user.id)
                   .limit(1).first

    @data = import.nil? ? nil : import.year_statistics
  end

  private

  def set_import
    @import = Import.find_by_id(params[:id])
  end

  def import_params
    params.permit([:type])
  end

  def full_data_params
    params.permit([:id, :type])
  end

  def check_params
    allowed_values = Import.available_imported_types.map(&:to_s)
    raise ArgumentError unless allowed_values.include?(import_params[:type])
  end
end
