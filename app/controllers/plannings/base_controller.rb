# encoding: utf-8

module Plannings
  class BaseController < ListController

    include WithPeriod

    define_render_callbacks :show, :new, :update

    before_action :authorize_class
    before_action :set_period

    before_render_show :set_board
    before_render_update :set_board

    helper_method :entry

    def show
      @plannings = load_plannings
    end

    # new row for plannings
    def new
      @employee = Employee.find(params[:employee_id])
      @work_item = WorkItem.find(params[:work_item_id])
      plannings = load_plannings.where(employee_id: @employee.id,
                                        work_item_id: @work_item.id)
      absencetimes = load_absencetimes(@employee)
      board = Plannings::Board.new(@period, plannings, absencetimes)
      board.default_row(@employee.id, @work_item.id)
      @items = board.rows.values.first
    end

    def update
      creator = Plannings::Creator.new(params)
      respond_to do |format|
        if creator.create_or_update
          format.js { @plannings = full_plannings_row(creator.plannings) }
        else
          format.js { render :errors, locals: { errors: creator.errors } }
        end
      end
    end

    def destroy
      destroy_plannings
      respond_to do |format|
        format.js do
          @plannings = full_plannings_row(@plannings)
          render :update
        end
      end
    end

    private

    def load_plannings
      Planning.in_period(@period).list
    end

    def load_absencetimes(employe_ids = @employees)
      Absencetime.in_period(@period).includes(:absence).where(employee_id: employe_ids)
    end

    def destroy_plannings
      Planning.transaction do
        @plannings = Planning.where(id: Array(params[:planning_ids]))
        @plannings.each(&:destroy)
      end
    end

    def full_plannings_row(plannings)
      condition = ['']
      plannings.collect { |p| [p.work_item_id, p.employee_id] }.uniq.each do |work_item_id, employee_id|
        condition[0] += ' OR ' unless condition.first.blank?
        condition[0] += '(plannings.work_item_id = ? AND plannings.employee_id = ?)'
        condition << work_item_id << employee_id
      end
      load_plannings.where(condition)
    end

    def set_board
      @employees = load_employees
      @accounting_posts = load_accounting_posts
      @absencetimes = load_absencetimes
      @board = Plannings::Board.new(@period, @plannings, @absencetimes)
    end

    def set_period
      convert_predefined_period
      period = super
      @period = period.limited? ? period.extend_to_weeks : default_period
    end

    def convert_predefined_period
      return if params[:period].blank?

      @period = Period.parse(params.delete(:period))
      if @period
        params[:start_date] = I18n.l(@period.start_date)
        params[:end_date] = I18n.l(@period.end_date)
      end
    end

    def default_period
      today = Time.zone.today
      Period.retrieve(today.at_beginning_of_week, (today + 3.month).at_end_of_week)
    end

    def authorize_class
      authorize!(action_name.to_sym, Planning)
    end

  end
end
