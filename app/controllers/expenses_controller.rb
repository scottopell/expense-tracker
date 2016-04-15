class ExpensesController < ApplicationController
  before_action :set_expense, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, :except => [:index]

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

  def show
  end

  # GET /expenses/new
  def new
    @expense = Expense.new
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
      params.require(:expense).permit(:amount, :category, :date, :user_id)
    end
end
