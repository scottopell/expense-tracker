class MiscController < ApplicationController
  before_action :authenticate_user!, :except => [:cccdata]
  before_action :authenticate_admin, :only => [:admin,
                                               :drop_data,
                                               :admin_user_viewer,
                                               :admin_password_reset,
                                               :admin_password_reset_post,
                                               :admin_marketwatch_reg,
                                               :seed_data,
                                               :admin_marketwatch]

  # GET '/dashboard'
  # GET '/info'
  def dashboard
    @user = current_user
    if params[:user_id] && current_user.admin
      @user = User.find params[:user_id]
    end

    num_users = User.count

    expenses = @user.expenses.order(date: :asc)

    if expenses.empty?
      notice_text = "User has no expenses to report"
      if current_user.admin
        notice_text = "You forgot to specify a target student's id. Use admin panel."
      end
      redirect_to :root, notice: notice_text
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

      @class_average_categories = Expense.categories.map do |category|
        value = Expense.average_week(nil, category).to_f / User.count
        value = 0 if value.nan?

        value
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
    @dir_options = ['ASC', 'DESC']
    @column_options = ['user', 'date', 'category']

    if params['category-filter'].present?
      @expenses = @expenses.where(category: params['category-filter'])
    end

    if params['user-filter'].present?
      @expenses = @expenses.joins(:user)
        .where("users.name ILIKE ?", "%#{params['user-filter']}%")
    end

    if params[:sort].present? && params[:dir].present?
      @expenses = @expenses.order(params[:sort] => params[:dir])
    end
  end

  # GET /admin/users
  def admin_user_viewer
    @users = User.all
    if params[:email].present?
      @users = User.where('email = ?', params[:email])
    elsif params[:name].present?
      @users = User.where('name ILIKE ?', "%#{params[:name]}%")
    end
  end

  #GET /admin/password_reset
  def admin_password_reset
    if !params[:user_id].present?
      redirect_to admin_user_viewer_path, notice: "No user specified, choose a user here" and return
    end
    @user = User.find(params[:user_id])
  end

  #POST /admin/password_reset
  def admin_password_reset_post
    @user = User.find(params[:user_id])

    if params[:password] != params[:password_confirmation]
      redirect_to admin_password_reset_path(user_id: @user.id), alert: "User's password not set successfully. Password and Confirmation don't match, try again" and return
    end

    if @user.update(password: params[:password])
      redirect_to admin_user_viewer_path, notice: "User's password set successfully!" and return
    else
      redirect_to admin_password_reset_path(user_id: @user.id), alert: "User's password not set successfully. Did you meet the password requirements?" and return
    end
  end


  # POST /admin/drop_data
  def drop_data
    User.where(admin: false).delete_all
    Expense.delete_all
    redirect_to admin_path, notice: "Users and Expenses deleted successfully"
  end

  def seed_data
    Rails.application.load_seed
    redirect_to admin_path, notice: "Fake Users and Expenses created successfully"
  end

  # GET /admin/marketwatch
  def admin_marketwatch
    @errors = []
  end

  # POST /admin/marketwatch
  def admin_marketwatch_reg
    require 'csv'
    require 'json'
    @errors = []
    @successes = []
    @attempt = true

    if !params[:csv].present?
      render :admin_marketwatch, error: 'no csv present, retry the upload' and return
    end

    csv = CSV.new(params[:csv].to_io, headers: true)
    csv.each do |row|
      name = row["Student Name"]
      email = row["Student Email"]
      if !name.present? || !email.present?
        @errors << "Skipping user because of blank name or blank email"
        next
      end
      fname = name.downcase.split.first.gsub(/[^a-z]/,'')
      lname = name.downcase.split.last.gsub(/[^a-z]/,'')

      password_candidate = name.downcase.split.first.gsub(/[^a-z]/,'')

      # truncates the length to the first 15 characters
      password = password_candidate[0..14]
      # pads out the string with the letter a if its less than 5 characters
      if password.length < 5
        password = password + "a" * (5 - password.length)
      end

      result = register_mw_user(fname, lname, email, password)
      @errors << result[1] if result[0] == false
      @successes << result[1] if result[0] == true
    end
    render :admin_marketwatch
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

  private
    def authenticate_admin
      if !current_user.admin
        redirect_to root_path, alert: 'You don\'t have permission to do that'
      end
    end

    def register_mw_user(fname, lname, email, password)
      puts "#{fname} #{lname} #{email} #{password}"
      output = `curl --silent 'https://id.marketwatch.com/epiton/registration/v2/profile' -H 'X-HTTP-Method-Override: POST' --data "profile.firstName=#{fname}&profile.lastName=#{lname}&profile.emailAddress=#{email}&profile.password=#{password}&profile.passwordConfirmation=#{password}&service.prodct=wsj-online&service.templateCode=MARKETWATCH&service.registrationType=FREE_REGISTRATION&profile.newsletterOptIns=330%2C302%2C303&profile.options.featureEmailOptIn=true" --compressed`
      j = JSON.parse output

      if j["status"] != "success"
        return [false, "Couldn't register user with email: '#{email}', first_name: '#{fname}', last_name: '#{lname}', password: '#{password}'"]
      else
        return [true, "Registered user with email: '#{email}', first_name: '#{fname}', last_name: '#{lname}', password: '#{password}'"]
      end

    end

end
