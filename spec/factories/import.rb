FactoryGirl.define do
  factory :import do
    association :user
    status 0
    imported_type 0
  end
end
