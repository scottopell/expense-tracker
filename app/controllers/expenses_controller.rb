class ExpensesController < ApplicationController
  before_action :set_expense, only: [:show, :edit, :update, :destroy]

  # GET /expenses
  # GET /expenses.json
  def index
    @total_expenses = Expense.sum(:amount)

    @categories = Expense.categories
    @avg_categories = Expense.categories.map do |category|
      Expense.average_week(nil, category).to_f
    end

    @avg_weekly_expenses = Expense.average_week.to_f
    @past_week_expenses = Expense.past_week.sum(:amount)

    @past_week_categories = Expense.categories.map do |category|
      Expense.past_week.where(category: category).sum(:amount)
    end
  end

  # GET /info
  def user_info
    @user = params[:user]
    num_users = Expense.distinct.count(:user)

    expenses = Expense.where(user: @user).order(date: :asc)

    if expenses.empty?
      redirect_to :root, notice: "User has no expenses to report"
    else
      @first_expense_date = expenses.first.date
      @last_expense_date = expenses.last.date
      @num_expenses = expenses.length

      @user_expenses_total = Expense.where(user: @user).sum(:amount)
      @average_expenses_total = Expense.sum(:amount) / num_users

      @user_past_week = Expense.past_week.where(user: @user).sum(:amount)
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

  def show
  end

  # GET /expenses/new
  def new
    @expense = Expense.new
    @category_options = Expense.categories
  end

  def edit
  end

  # POST /expenses
  # POST /expenses.json
  def create
    @expense = Expense.new(expense_params)

    respond_to do |format|
      if @expense.save
        format.html { redirect_to :root, notice: 'Expense was successfully created.' }
        format.json { render :index, status: :created }
      else
        format.html { render :new }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @expense.update(expense_params)
        format.html { redirect_to @expense, notice: 'Expense was successfully updated.' }
        format.json { render :show, status: :ok, location: @expense }
      else
        format.html { render :edit }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @expense.destroy
    respond_to do |format|
      format.html { redirect_to expenses_url, notice: 'Expense was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_expense
      @expense = Expense.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def expense_params
      params.require(:expense).permit(:amount, :category, :date, :user)
    end
end
