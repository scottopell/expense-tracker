class MiscController < ApplicationController
  before_action :authenticate_user!, :except => [:cccdata]

  # GET '/dashboard'
  # GET '/info'
  def dashboard
    @user = current_user
    if params[:user_id] && current_user.admin
      @user = User.find params[:user_id]
    end

    num_users = User.count

    expenses = @user.expenses.order(date: asc)

    if expenses.empty?
      redirect_to :root, notice: "User has no expenses to report"
    else
      @first_expense_date = expenses.first.date
      @last_expense_date = expenses.last.date
      @num_expenses = expenses.length

      @user_expenses_total = @user.expenses.sum(:amount)
      @average_expenses_total = Expense.sum(:amount) / num_users

      @user_past_week = Expense.past_week.where(user_id: @user.id).sum(:amount)
      @all_past_week = Expense.past_week.sum(:amount) / num_users

      @user_avg_categories = Expense.categories.map do |category|
        value = Expense.average_week(@user, category).to_f
        value = 0 if value.nan?

        value
      end

      @user_past_week_categories = Expense.categories.map do |category|
        Expense.past_week.where(user: @user).where(category: category).sum(:amount)
      end

      @categories = Expense.categories

      past_week_data = @user_past_week_categories.map.with_index do |value, idx|
        { name: Expense.categories[idx], y: value.to_f }
      end

      @past_week_json_data = past_week_data.to_json.html_safe

      avg_week_data = @user_avg_categories.map.with_index do |value, idx|
        { name: Expense.categories[idx], y: value.to_f }
      end

      @avg_week_json_data = avg_week_data.to_json.html_safe
    end
  end

  # GET /admin
  def admin
    @expenses = Expense.paginate(page: params[:page])
    @category_options = Expense.categories
    @dir_options = ['ASC', 'DESC']
    @column_options = ['user', 'date', 'category']

    if params['category-filter'].present?
      @expenses = @expenses.where(category: params['category-filter'])
    end

    if params['user-filter'].present?
      @expenses = @expenses.where(user: params['user-filter'])
    end

    if params[:sort].present? && params[:dir].present?
      @expenses = @expenses.order(params[:sort] => params[:dir])
    end
  end

  # GET /cccdata
  def cccdata
    require 'open-uri'

    menu_url = 'http://www.consolidatedcredit.org/debt-solutions/american-spending-statistics/'
    page = Nokogiri::HTML(open(menu_url))

    things = []
    page.css('body > div.con.main > article > table tr').each do |el|
      columns = el.css 'td'
      if columns.present?
        category = el.css('td')[0].text
        value = el.css('td')[1].text

        things << { category: category, value: value }
        puts things.last
      end
    end

    render json: things
  end

end
