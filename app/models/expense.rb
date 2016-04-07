class Expense < ActiveRecord::Base
  def self.past_week
    Expense.where('date > ?', 1.week.ago)
  end

  def self.categories
    [ 'Housing', 'Supermarkets and Grocery Stores', 'Gasoline and Automotive',
      'General Merchandise', 'Restaraunts and Bars', 'Miscellaneous' ]
  end

  # This is probably the slowest method in here, but still not that bad.
  # I tested with ~3000 rows and it takes ~25ms in activerecord
  def self.average_week user=nil, category=nil
    records = Expense.all
    if user.present?
      records = records.where(user: user)
    end
    if category.present?
      records = records.where(category: category)
    end

    # DATE_TRUNC will truncate every date value to the nearest specified amount
    # in this case I specify "week"
    # So group by this aggregate value will group all expenses by their week
    # Then you can take the sum of the amount column, and you'll get a hash
    # from activerecord containing the first day of each week along with the
    # sum of amounts within that week
    # Finally, use Hash#values to get just the values from this
    results = records.group("DATE_TRUNC('week', date)").sum(:amount).values
    # then take the average
    results.reduce(:+).to_f / results.length
  end

end
