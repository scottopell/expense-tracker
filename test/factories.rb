require 'faker'

FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { Faker::Internet.password }

    admin false
  end

  factory :expense do
    amount     { rand(10..50) }
    date       { rand(1.years).seconds.ago }
    category   { Expense.categories.sample }
  end
end
