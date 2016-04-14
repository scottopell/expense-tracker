# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

num_users = rand 5..10
num_users.times { FactoryGirl.create(:user) }
# autoincrementing primary key on users starts at 1, rand(N) range
# is 0 .. N - 1, so hence the + 1
rand(500..5000).times { FactoryGirl.create(:expense, user_id: rand(num_users) + 1) }
