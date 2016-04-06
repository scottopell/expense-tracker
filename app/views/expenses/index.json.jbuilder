json.array!(@expenses) do |expense|
  json.extract! expense, :id, :amount, :category, :date, :user
  json.url expense_url(expense, format: :json)
end
