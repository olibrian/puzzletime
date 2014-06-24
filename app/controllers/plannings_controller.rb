# encoding: utf-8

class PlanningsController < ApplicationController

  before_action :set_period

  def index
    redirect_to action: 'my_planning'
  end

  def my_planning
    @employee = @user
    @graph = EmployeePlanningGraph.new(@employee, @period)
    render template: 'plannings/employee_planning'
  end

  def my_projects
    @projects = @user.managed_projects.includes(:department)
    render template: 'plannings/projects'
  end

  def existing
    if params[:planning][:start_week_date].present?
      current_week = Week.from_string(params[:planning][:start_week_date]).to_date
      @period = extended_period(current_week)
    # else: use default period
    end
    set_employee
    @graph = EmployeePlanningGraph.new(@employee, @period)
  end

  def employees
    set_employees
  end

  def employee_planning
    set_employee
    if params[:week_date].present?
      @period = extended_period(Date.parse(params[:week_date]))
    # else: use default period
    end
    @graph = EmployeePlanningGraph.new(@employee, @period)
  end

  def employee_lists_planning
    @employee_list = EmployeeList.find_by_id(params[:employee_list_id])
    @employee_list_name = @employee_list.title
    period = @period.present? ? @period : Period.current_month
    @graph = EmployeesPlanningGraph.new(@employee_list.employees.includes(:employments).list, period)
  end

  def projects
    @projects = Project.top_projects.includes(:department)
  end

  def project_planning
    unless params[:project_id]
      return redirect_to(action: 'projects')
    end
    @project = Project.find(params[:project_id])
    @graph = ProjectPlanningGraph.new(@project, @period)
  end

  def departments
    @departmens = Department.list
  end

  def department_planning
    unless params[:department_id]
      return redirect_to(action: 'departments')
    end
    @department = Department.find(params[:department_id])

    employees = planned_employees(@department, @perdiod)
    @graph = EmployeesPlanningGraph.new(employees, @period)
  end

  def company_planning
    period = @period.present? ? @period : Period.current_month
    @graph = EmployeesPlanningGraph.new(Employee.employed_ones(period).includes(:employments).list, period)
  end

  def new
    set_employee
    @employee ||= @user
    @planning = Planning.new(employee: @employee)
    if params[:project_id]
      @planning.project = Project.find(params[:project_id])
    end
    if params[:date]
      week_date = Week.from_string(params[:date])
      @planning.start_week = week_date.to_integer
      @period = extended_period(week_date.to_date)
    else
      @period = extended_period
    end
    build_planning_form
  end

  def create
    # Rails.logger.info("PARAMS: #{params.inspect}")
    set_employees
    @planning = Planning.new
    set_planning_attributes(params[:planning])
    if @planning.save
      flash[:notice] = 'Die Planung wurde erfolgreich erfasst'
      redirect_to action: 'employee_planning', employee_id: @planning.employee
    else
      @employee = @planning.employee
      build_planning_form
      render action: 'new'
    end
  end

  def edit
    @planning = Planning.find(params[:id])
    @employee = @planning.employee
    start_date = Week.from_integer(@planning.start_week).to_date
    @period = extended_period(start_date)
    build_planning_form
  end

  def update
    @planning = Planning.find(params[:id])
    set_planning_attributes(params[:planning])
    @employee = @planning.employee
    if @planning.save
      flash[:notice] = 'Die Planung wurde erfolgreich erfasst'
      redirect_to action: 'employee_planning', employee_id: @employee
    else
      build_planning_form
      render action: 'edit'
    end
  end

  def destroy
    planning = Planning.find(params[:planning])
    if planning.destroy
      flash[:notice] = 'Die Planung wurde entfernt'
    else
      flash[:error] = 'Die Planung konnte nicht geloescht werden'
    end
    redirect_to action: 'employee_planning', employee_id: planning.employee
  end

  private
  def build_planning_form
    set_employees
    @projects = Project.top_projects
    @graph = EmployeePlanningGraph.new(@employee, @period)
  end

  def set_employee
    id = params[:employee_id].presence ||
         (params[:planning] && params[:planning][:employee_id].presence)
    @employee = Employee.find(id) if id
  end

  def set_employees
    unless @period
      @period = Period.current_month
    end
    @employees = Employee.employed_ones(@period)
  end

  def extended_period(date = Date.today)
    Period.new(date - 14, date + 21)
  end

  def planned_employees(department, period)
    # this could be improved with a many-to-many table relation between Department and Employee
    projects = Project.where(department_id: department)
    memberships = Projectmembership.where(project_id: projects.collect { |p|p.id }, active: true)
    employees = Employee.where(id: memberships.collect { |m| m.employee_id }).includes(:employments).list
    period ||= Period.current_month
    employees.select { |e| e.employment_at(period.startDate).present? || e.employment_at(period.endDate).present? }
  end

  def set_planning_attributes(planning_params)
    @planning.employee = Employee.find(planning_params[:employee_id]) if planning_params[:employee_id]
    @planning.project = Project.find(planning_params[:project_id]) if planning_params[:project_id]
    @planning.start_week = Week.from_string(planning_params[:start_week_date]).to_integer if planning_params[:start_week_date]
    @planning.definitive = planning_params[:type] == 'definitive'
    @planning.is_abstract = planning_params[:abstract_concrete] == 'abstract'
    @planning.abstract_amount = (planning_params[:abstract_amount].blank? ? 0 : planning_params[:abstract_amount])
    case planning_params[:repeat_type]
      when 'no'
        @planning.end_week = @planning.start_week
      when 'until'
        @planning.end_week = Week.from_string(planning_params[:end_week_date]).to_integer if planning_params[:end_week_date]
      when 'forever'
        @planning.end_week = nil
    end
    @planning.monday_am = boolean_param(planning_params[:monday_am])
    @planning.monday_pm = boolean_param(planning_params[:monday_pm])
    @planning.tuesday_am = boolean_param(planning_params[:tuesday_am])
    @planning.tuesday_pm = boolean_param(planning_params[:tuesday_pm])
    @planning.wednesday_am = boolean_param(planning_params[:wednesday_am])
    @planning.wednesday_pm = boolean_param(planning_params[:wednesday_pm])
    @planning.thursday_am = boolean_param(planning_params[:thursday_am])
    @planning.thursday_pm = boolean_param(planning_params[:thursday_pm])
    @planning.friday_am = boolean_param(planning_params[:friday_am])
    @planning.friday_pm = boolean_param(planning_params[:friday_pm])
    @planning.description = planning_params[:description]
  end

  def boolean_param(param)
    param.present? ? param : false
  end

end
