require 'faker'

names = []
5.times do
  names << Faker::Name.first_name
end

FactoryGirl.define do
  factory :expense do
    user       { names.sample }
    amount     { rand(10..50) }
    date       { rand(1.years).seconds.ago }
    category   { Expense.categories.sample }
  end
end
