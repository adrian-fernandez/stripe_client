require "rails_helper"

RSpec.describe Import, :type => :model do
  describe 'Validations and relations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'Initial values' do
    let(:import) { build :import }

    it do
      expect(import.total_count).to eq(0)
      expect(import.imported_count).to eq(0)
      expect(import.status).to eq(0)
    end
  end

  describe '#self.get_last_imports' do
    let!(:import1) { create :import, imported_type: 1 }
    let!(:import2) { create :import, imported_type: 2 }

    it do
      result = Import.get_last_imports
      expected_result = { 1 => {
                                id: import1.id,
                                created_at: import1.created_at,
                                status: 0,
                                imported_count: 0,
                                total_count: 0
                             },
                          2 => {
                                id: import2.id,
                                created_at: import2.created_at,
                                status: 0,
                                imported_count: 0,
                                total_count: 0
                             }
                        }

      expect(result).to eq(expected_result)
    end

  end

  describe '#elements' do
    let!(:import) { create :import, imported_type: 1 }
    let!(:user) { create :user }
    let!(:elem1) { Charge.create(import_id: import.id, user_id: import.user_id) }
    let!(:elem2) { Charge.create(import_id: import.id, user_id: user.id) }

    it do
      expect(import.elements.count).to eq(1)
      expect(import.elements[0].id).to eq(elem1.id)
    end
  end

  describe '#clean_elements!' do
    let!(:import) { create :import, imported_type: 1, last_id: 'test' }
    let!(:user) { create :user }
    let!(:elem1) { Charge.create(import_id: import.id, user_id: import.user_id) }
    let!(:elem2) { Charge.create(import_id: import.id, user_id: user.id) }

    it do
      import.clean_elements!

      expect(import.elements.count).to eq(0)
      expect(Charge.find_by_id(elem1.id)).to be_nil
      expect(import.last_id).to eq('')
    end
  end

  describe '#self.data_downloaded_for?' do
    let!(:import) { create :import, imported_type: 1 }
    let!(:user) { create :user }
    let!(:elem1) { Charge.create(import_id: import.id, user_id: import.user_id) }
    let!(:elem2) { Charge.create(import_id: import.id, user_id: user.id) }

    it do
      expect(Import.data_downloaded_for?(:charges, import.user_id)).to be_truthy
      expect(Import.data_downloaded_for?(:charges, user.id)).to be_falsey
      expect(Import.data_downloaded_for?(:transfers, import.user_id)).to be_falsey
      expect(Import.data_downloaded_for?(:transfers, user.id)).to be_falsey
    end
  end

  describe '#set_total_count!' do
    let!(:import) { build :import, imported_type: 1 }

    it do
      import.set_total_count!(3)
      expect(import.total_count).to eq(3)

      import.set_total_count!(5)
      expect(import.total_count).to eq(5)
    end
  end

  describe '#set_imported_count!' do
    let!(:import) { build :import, imported_type: 1 }

    it do
      import.set_imported_count!(3)
      expect(import.imported_count).to eq(3)

      import.set_imported_count!(5)
      expect(import.imported_count).to eq(8)
    end
  end

  describe '#self.imported_type_value_for?' do
    it do
      expect(Import.imported_type_value_for?(:charges)).to eq(1)
      expect(Import.imported_type_value_for?(:transfers)).to eq(2)
      expect(Import.imported_type_value_for?(:disputes)).to eq(3)
      expect(Import.imported_type_value_for?(:refunds)).to eq(4)
      expect(Import.imported_type_value_for?(:bankaccounts)).to eq(5)
      expect(Import.imported_type_value_for?(:orders)).to eq(6)
      expect(Import.imported_type_value_for?(:returns)).to eq(7)
      expect(Import.imported_type_value_for?(:subscriptions)).to eq(8)
      expect(Import.imported_type_value_for?(:creditcardaccounts)).to eq(9)
    end
  end

  describe '#self.get_imported_type_from_value' do
    it do
      expect(Import.get_imported_type_from_value(1)).to eq(:charges)
      expect(Import.get_imported_type_from_value(2)).to eq(:transfers)
      expect(Import.get_imported_type_from_value(3)).to eq(:disputes)
      expect(Import.get_imported_type_from_value(4)).to eq(:refunds)
      expect(Import.get_imported_type_from_value(5)).to eq(:bankaccounts)
      expect(Import.get_imported_type_from_value(6)).to eq(:orders)
      expect(Import.get_imported_type_from_value(7)).to eq(:returns)
      expect(Import.get_imported_type_from_value(8)).to eq(:subscriptions)
      expect(Import.get_imported_type_from_value(9)).to eq(:creditcardaccounts)
    end
  end

  describe '#self.status_value_for?' do
    it do
      expect(Import.status_value_for?(:created)).to eq(0)
      expect(Import.status_value_for?(:importing)).to eq(1)
      expect(Import.status_value_for?(:done)).to eq(2)
      expect(Import.status_value_for?(:failed)).to eq(3)
      expect(Import.status_value_for?(:deleted)).to eq(4)
    end
  end

  describe '#self.get_status_from_value' do
    it do
      expect(Import.get_status_from_value(0)).to eq(:created)
      expect(Import.get_status_from_value(1)).to eq(:importing)
      expect(Import.get_status_from_value(2)).to eq(:done)
      expect(Import.get_status_from_value(3)).to eq(:failed)
      expect(Import.get_status_from_value(4)).to eq(:deleted)
    end
  end

  describe '#self.available_imported_types' do
    it do
      expect(Import.available_imported_types).to eq([:charges,
                                                     :transfers,
                                                     :disputes,
                                                     :refunds,
                                                     :orders,
                                                     :returns,
                                                     :subscriptions])
    end
  end

  describe '#self.fields_for' do
    it do
      expect(Import.fields_for(:charges)).to eq(['id', 'amount', 'amount_refunded', 'created'])
      expect(Import.fields_for(:transfers)).to eq(['id', 'amount', 'amount_reversed', 'created'])
      expect(Import.fields_for(:disputes)).to eq(['id', 'amount', 'charge', 'created'])
      expect(Import.fields_for(:refunds)).to eq(['id', 'amount', 'charge', 'status'])
      expect(Import.fields_for(:bankaccounts)).to eq(['id', 'account_holder_name', 'account_holder_type', 'last4', 'country', 'currency'])
      expect(Import.fields_for(:orders)).to eq(['id', 'amount', 'amount_returned', 'currency', 'items'])
      expect(Import.fields_for(:returns)).to eq(['id', 'active', 'attributes', 'product'])
      expect(Import.fields_for(:subscriptions)).to eq(['id', 'customer', 'current_period_start', 'current_period_end', 'ended_at', 'plan'])
      expect(Import.fields_for(:creditcardaccounts)).to eq(['id', 'brand', 'country', 'last4', 'exp_month', 'exp_year'])
    end
  end

  describe '#self.get_years_to_retrieve' do
    it do
      expect(Import.get_years_to_retrieve).to eq(3)
    end
  end

  describe 'elements_class' do
    context 'elements are charges' do
      let!(:import) { create :import, imported_type: 1  }
      it { expect(import.send('elements_class')).to eq(Charge) }
    end
    context 'elements are transfers' do
      let!(:import) { create :import, imported_type: 2  }
      it { expect(import.send('elements_class')).to eq(Transfer) }
    end
    context 'elements are disputes' do
      let!(:import) { create :import, imported_type: 3  }
      it { expect(import.send('elements_class')).to eq(Dispute) }
    end
    context 'elements are refunds' do
      let!(:import) { create :import, imported_type: 4  }
      it { expect(import.send('elements_class')).to eq(Refund) }
    end
    context 'elements are bankaccounts' do
      let!(:import) { create :import, imported_type: 5  }
      it { expect(import.send('elements_class')).to eq(Bankaccount) }
    end
    context 'elements are orders' do
      let!(:import) { create :import, imported_type: 6  }
      it { expect(import.send('elements_class')).to eq(Order) }
    end
    context 'elements are returns' do
      let!(:import) { create :import, imported_type: 7  }
      it { expect(import.send('elements_class')).to eq(Return) }
    end
    context 'elements are subscriptions' do
      let!(:import) { create :import, imported_type: 8  }
      it { expect(import.send('elements_class')).to eq(Subscription) }
    end
  end

end