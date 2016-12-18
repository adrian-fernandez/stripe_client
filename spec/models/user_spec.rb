require "rails_helper"

RSpec.describe User, :type => :model do
  describe 'validations and relations' do
    it { is_expected.to have_many(:imports) }
  end

  describe '#stripe_account_connected?' do
    let(:user) { build :user }

    context 'with account' do
      it do
       user.stripe_access_token = 'some_token'
       expect(user.stripe_account_connected?).to be_truthy
      end
    end

    context 'without account' do
      it do
        user.stripe_access_token = ''
        expect(user.stripe_account_connected?).to be_falsey
      end
    end
  end
end