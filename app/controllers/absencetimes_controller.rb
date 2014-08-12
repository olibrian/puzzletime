# encoding: utf-8
class AbsencetimesController < WorktimesController

  self.permitted_attrs = [:absence_id, :report_type, :work_date, :hours,
                          :from_start_time, :to_end_time, :description]

  before_render_form :set_accounts

  def create
    if params[:absencetime].present? && params[:absencetime][:create_multi].present?
      create_multi_absence
    else
      super
    end
  end

  def update
    if entry.employee_id != @user.id
      redirect_to index_url
    else
      super
    end
  end

  protected

  def create_multi_absence
    @multiabsence = MultiAbsence.new
    @multiabsence.employee = Employee.find_by_id(employee_id)
    @multiabsence.attributes = params[:absencetime]
    if @multiabsence.valid?
      count = @multiabsence.save
      flash[:notice] = "#{count} Absenzen wurden erfasst"
      redirect_to action: 'index', week_date: @multiabsence.work_date
    else
      set_employees
      @create_multi = true
      @multiabsence.worktime.errors.each do |attr, msg|
        entry.errors.add(attr, msg)
      end
      render 'new'
    end
  end

  def set_worktime_defaults
    @worktime.absence_id ||= params[:account_id]
  end

  def set_accounts(all = false)
    @accounts = Absence.list
  end

  def generic_evaluation
    'absences'
  end

end
