# frozen_string_literal: true
# Create Import worker for background processing
class ImportWorker
  include Sidekiq::Worker

  attr_accessor :import, :from_date

  def initialize(import)
    self.import = import
    self.from_date = DateTime.new(Time.now.year - 3, 1, 1)
  end

  def perform
    import.set_status!(:importing)

    response = StripeApi.send('import', import.imported_type, from_date)

    last_id = save_response(response)
    while !last_id.nil?
      response = StripeApi.send('import', import.imported_type, from_date, last_id)
      last_id = save_response(response)
    end

    import.set_status!(:done)
  end

  private

  # Returns: <string> Last saved ID if there are still more data to retrieve from server
  # =>       nil if there are no more pending data.
  def save_response(response)
    import.set_total_count!(response[:total_count])
    last_id = ''

    response[:data].each do |data_field|
      obj = class_name.new
        obj.import_id = import.id
        data_to_save = {}
        Import::FIELDS_FOR[import_type].each do |field_name|
          data_to_save[field_name] = data_field.send(field_name)
        end

        obj.data = data_to_save
      obj.save
      last_id = data_field.id
    end

    import.set_imported_count!(response[:data].count)
    import.set_last_id!(last_id)

    if response[:has_more]
      return last_id
    else
      return nil
    end
  end

  def import_type
    Import::IMPORTED_TYPE.key(import.imported_type)
  end

  def import_type_str
    import_type.to_s
  end

  def class_name
    import_type_str.singularize.capitalize.constantize
  end
end
