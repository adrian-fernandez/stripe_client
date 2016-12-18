class Import < ActiveRecord::Base
  before_destroy :destroy_elements
  belongs_to :user

  def self.get_last_imports
    # imports = Import.select("distinct FIRST_VALUE(imported_type) OVER(PARTITION BY imported_type ORDER BY id DESC) as imported_type")
    #                 .select("FIRST_VALUE(id) OVER(PARTITION BY imported_type ORDER BY id DESC) as id")
    #                 .select("FIRST_VALUE(created_at) OVER(PARTITION BY imported_type ORDER BY id DESC) as created_at")
    #                 .select("FIRST_VALUE(status) OVER(PARTITION BY imported_type ORDER BY id DESC) as status")
    #                  .select("FIRST_VALUE(total_count) OVER(PARTITION BY imported_type ORDER BY id DESC) as total_count")
    imports = Import.all

    res = {}
    imports.map do |x|
      res[x.imported_type] = {id: x.id,
                              created_at: x.created_at,
                              status: x.status,
                              imported_count: x.imported_count,
                              total_count: x.total_count }
    end

    res
  end

  def elements
    elements_class.where(import_id: id, user_id: user_id)
  end

  def clean_elements!
    elements.destroy_all
    set_last_id!('')
  end

  def self.data_downloaded_for?(type, user_id)
    Import.where(user_id: user_id, imported_type: Import.imported_type_value_for?(type)).present?
  end

  def set_status!(new_status)
    return unless STATUS.keys.include?(new_status)

    update_attribute(:status, STATUS[new_status])

    case new_status
    when :created
      do_import
    when :deleted
      update_attributes({imported_count: 0,
                         total_count: 0,
                         last_id: ''})
    end
  end

  def set_total_count!(value)
    return if value.blank?
    return if value.class != Fixnum

    update_attribute(:total_count, value)
  end

  def set_imported_count!(value)
    return if value.blank?
    return if value.class != Fixnum

    update_attribute(:imported_count, imported_count + value)
  end

  def set_last_id!(value)
    update_attribute(:last_id, value)
  end

  def self.get_imported_type_from_value(value)
    IMPORTED_TYPE.key(value)
  end

  def self.get_status_from_value(value)
    STATUS.key(value)
  end

  def self.status_value_for?(value)
    STATUS[value]
  end

  def self.imported_type_value_for?(value)
    IMPORTED_TYPE[value]
  end

  def self.available_imported_types
    IMPORTED_TYPE.keys - DISABLED_OBJECTS
  end

  def self.fields_for(value)
    FIELDS_FOR[value]
  end

  def self.get_years_to_retrieve
    YEARS_TO_RETRIEVE
  end

  def month_statistics
    res = QueryResultByMonth.query(user_id)
  end

  def year_statistics
    res = QueryResultByYear.query(user_id, DateTime.now.year)
  end

  private

  YEARS_TO_RETRIEVE = 3

  STATUS = { created: 0,
             importing: 1,
             done: 2,
             failed: 3,
             deleted: 4 }.freeze

  IMPORTED_TYPE = { charges: 1,
                    transfers: 2,
                    disputes: 3,
                    refunds: 4,
                    bankaccounts: 5,
                    orders: 6,
                    returns: 7,
                    subscriptions: 8,
                    creditcardaccounts: 9}.freeze

  DISABLED_OBJECTS = [:creditcardaccounts,
                      :bankaccounts
                     ].freeze

  FIELDS_FOR = {
    charges: ['id', 'amount', 'amount_refunded', 'created'],
    transfers: ['id', 'amount', 'amount_reversed', 'created'],
    disputes: ['id', 'amount', 'charge', 'created'],
    refunds: ['id', 'amount', 'charge', 'status'],
    bankaccounts: ['id', 'account_holder_name', 'account_holder_type', 'last4', 'country', 'currency'],
    orders: ['id', 'amount', 'amount_returned', 'currency', 'items'],
    returns: ['id', 'active', 'attributes', 'product'],
    subscriptions: ['id', 'customer', 'current_period_start', 'current_period_end', 'ended_at', 'plan'],
    creditcardaccounts: ['id', 'brand', 'country', 'last4', 'exp_month', 'exp_year'],
  }.freeze

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