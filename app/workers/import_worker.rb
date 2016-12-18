# frozen_string_literal: true
# Create Import worker for background processing
class ImportWorker
  include Sidekiq::Worker

  attr_accessor :import, :from_date, :user

  def initialize(import)
    self.import = import
    self.from_date = DateTime.new(Time.now.year - Import.get_years_to_retrieve, 1, 1)
    self.user = User.find_by_id(import.user_id)
  end

  def perform
    import.set_status!(:importing)

    begin
      if import.last_id.blank?
        response = user.send('stripe_import', import.imported_type, from_date)
      else
        response = user.send('stripe_import', import.imported_type, from_date, import.last_id)
      end

      last_id = save_response(response)
      while !last_id.nil?
        response = user.send('stripe_import', import.imported_type, from_date, last_id)
        last_id = save_response(response)
      end

      import.set_status!(:done)
    rescue
      import.set_status!(:failed)
    end
  end

  private

  # Returns: <string> Last saved ID if there are still more data to retrieve from server
  # =>       nil if there are no more pending data.
  def save_response(response)
    import.set_total_count!(response[:total_count])

    response[:data].each do |data_field|
      obj = class_name.new(user_id: import.user_id)
        obj.import_id = import.id
        data_to_save = { }
        Import.fields_for(import_type).each do |field_name|
          data_to_save[field_name] = data_field.send(field_name)
        end

        data_to_save[:user_id] = import.user_id
        data_to_save.merge!(parsed_date_fields(data_to_save['created']))

        obj.data = data_to_save
      obj.save
    end

    if response[:data].count > 0
      import.set_imported_count!(response[:data].count)
      import.set_last_id!(response[:last_id])
    end

    if response[:has_more]
      return last_id
    else
      return nil
    end
  end

  def parsed_date_fields(timestamp)
    return {} if timestamp.blank?

    date = DateTime.strptime(timestamp.to_s, "%s")

    {
      day: date.day,
      month: date.month,
      year: date.year
    }
  end

  def import_type
    Import.get_imported_type_from_value(import.imported_type)
  end

  def import_type_str
    import_type.to_s
  end

  def class_name
    import_type_str.singularize.capitalize.constantize
  end
end
