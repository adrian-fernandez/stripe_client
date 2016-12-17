class Import < ActiveRecord::Base
  after_create :do_import
  before_destroy :destroy_elements

  STATUS = { created: 0,
             importing: 1,
             done: 2,
             failed: 3 }

  IMPORTED_TYPE = { charges: 1,
                    disputes: 2 }

  FIELDS_FOR = {
    charges: ['id', 'amount', 'amount_refunded', 'created']
  }

  def self.get_last_imports
    imports = Import.select("distinct FIRST_VALUE(imported_type) OVER(PARTITION BY imported_type ORDER BY id DESC) as imported_type")
                    .select("FIRST_VALUE(id) OVER(PARTITION BY imported_type ORDER BY id DESC) as id")
                    .select("FIRST_VALUE(created_at) OVER(PARTITION BY imported_type ORDER BY id DESC) as created_at")
                    .select("FIRST_VALUE(status) OVER(PARTITION BY imported_type ORDER BY id DESC) as status")
                    .select("FIRST_VALUE(total_count) OVER(PARTITION BY imported_type ORDER BY id DESC) as total_count")

    res = {}
    imports.map do |x|
      res[x.imported_type] = {id: x.id,
                              created_at: x.created_at,
                              status: x.status,
                              total_count: x.total_count }
    end

    res
  end

  def elements
    elements_class.where(import_id: id)
  end

  def set_status!(new_status)
    return unless STATUS.keys.include?(new_status)

    update_attribute(:status, STATUS[new_status])
  end

  def set_total_count!(value)
    return if value.blank?
    return if value.class != Fixnum

    update_attribute(:total_count, value)
  end

  def set_imported_count!(value)
    return if value.blank?
    return if value.class != Fixnum

    update_attribute(:imported_count, value)
  end

  def set_last_id!(value)
    update_attribute(:last_id, value)
  end

  private

  def elements_class
    IMPORTED_TYPE.key(imported_type).to_s.singularize.capitalize.constantize
  end

  def destroy_elements
    elements.destroy_all
  end

  def do_import
    importer = ImportWorker.new(self)
    importer.perform
  end

end