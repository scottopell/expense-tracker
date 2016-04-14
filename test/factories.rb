require 'faker'

FactoryGirl.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    username { Faker::Internet.user_name }
    password { Faker::Internet.password }

    admin false
  end

  factory :expense do
    amount     { rand(10..50) }
    date       { rand(1.years).seconds.ago }
    category   { Expense.categories.sample }
  end
end
