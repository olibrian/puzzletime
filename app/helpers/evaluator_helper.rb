# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module EvaluatorHelper
  def evaluation_detail_params
    params.slice(:evaluation, :category_id, :division_id, :start_date, :end_date, :page)
  end

  def evaluation_path(evaluation, options = {})
    url_for(options.merge(controller: '/evaluator', action: evaluation))
  end

  def detail_th_align(field)
    case field
    when :work_date, :hours, :times then 'right'
    end
  end

  def detail_td(worktime, field)
    case field
    when :work_date then content_tag(:td, f(worktime.work_date), class: 'right nowrap', style: 'width: 160px;')
    when :hours then content_tag(:td, format_hour(worktime.hours), class: 'right nowrap', style: 'width: 70px;')
    when :times then content_tag(:td, worktime.time_string, class: 'right nowrap', style: 'width: 150px;')
    when :employee then content_tag(:td, worktime.employee.shortname, style: 'width: 50px;')
    when :account then content_tag(:td, worktime.account.label_verbose)
    when :billable then content_tag(:td, worktime.billable ? '$' : ' ', style: 'width: 20px;')
    when :ticket then content_tag(:td, worktime.ticket)
    when :description
      content_tag(:td, worktime.description, title: worktime.description, class: 'truncated')
    end
  end

  def collect_times(periods, method, *division)
    periods.collect do |p|
      @evaluation.send(method, p, *division)
    end
  end

  def worktime_controller
    @evaluation.absences? ? 'absencetimes' : 'ordertimes'
  end

  #### division supplement functions

  def overtime(employee)
    format_hour(@period ?
        employee.statistics.overtime(@period) :
        employee.statistics.current_overtime)
  end

  def remaining_vacations(employee)
    format_days(@period ?
        employee.statistics.remaining_vacations(@period.end_date) :
        employee.statistics.current_remaining_vacations)
  end

  def overtime_vacations_tooltip(employee)
    transfers = employee.overtime_vacations.
                where(@period ? ['transfer_date <= ?', @period.end_date] : nil).
                order('transfer_date').
                to_a
    tooltip = ''
    unless transfers.empty?
      tooltip = '<a href="#" class="has-tooltip">&lt;-&gt;<span>Überzeit-Ferien Umbuchungen:<br/>'
      transfers.collect! do |t|
        " - #{f(t.transfer_date)}: #{format_hour(t.hours)}"
      end
      tooltip += transfers.join('<br />')
      tooltip += '</span></a>'
    end
    tooltip.html_safe
  end

  def worktime_commits(employee)
    content = content_tag(:span, id: "committed_worktimes_at_#{employee.id}") do
      worktime_commits_icon(employee) << ' ' << format_attr(employee, :committed_worktimes_at)
    end

    if can?(:update_committed_worktimes, employee)
      content << ' &nbsp; '.html_safe << link_to(picon('edit'),
                                                 edit_employee_worktimes_commit_path(employee),
                                                 data: { modal: '#modal',
                                                         title: 'Freigabe bearbeiten',
                                                         update: 'element',
                                                         element: "#committed_worktimes_at_#{employee.id}",
                                                         remote: true,
                                                         type: :html })
    end
    content
  end

  def worktime_commits_icon(employee)
    if employee.recently_committed_worktimes?
      picon('disk', class: 'green')
    else
      picon('square', class: 'red')
    end
  end

  def order_month_end_completions(work_item)
    order = work_item.order
    content = content_tag(:span, id: "order_month_end_completion_#{order.id}") do
      order_month_end_completions_icon(order) << ' ' << format_attr(order, :completed_month_end_at)
    end
    if can?(:update_month_end_completions, order)
      content << ' &nbsp; '.html_safe << link_to(picon('edit'),
                                                 edit_order_month_end_completion_path(order),
                                                 data: { modal: '#modal',
                                                         title: 'Monatsabschluss bearbeiten',
                                                         update: 'element',
                                                         element: "#order_month_end_completion_#{order.id}",
                                                         remote: true,
                                                         type: :html })
    end
    content
  end

  def order_month_end_completions_icon(order)
    if order.recently_completed_month_end?
      picon('disk', class: 'green')
    else
      picon('square', class: 'red')
    end
  end

  ### period and time helpers

  def period_link(label, shortcut)
    link_to label, action: 'change_period', shortcut: shortcut, back_url: params[:back_url]
  end

  def time_info
    stat = @user.statistics
    infos = @period ?
            [[['Überzeit', stat.overtime(@period).to_f, 'h'],
              ['Bezogene Ferien', stat.used_vacations(@period), 'd'],
              ['Soll Arbeitszeit', stat.musttime(@period), 'h']],
             [['Abschliessend', stat.current_overtime(@period.end_date), 'h'],
              ['Verbleibend', stat.remaining_vacations(@period.end_date), 'd']]] :
            [[['Überzeit Gestern', stat.current_overtime, 'h'],
              ['Bezogene Ferien', stat.used_vacations(Period.current_year), 'd'],
              ['Monatliche Arbeitszeit', stat.musttime(Period.current_month), 'h']],
             [['Überzeit Heute', stat.current_overtime(Time.zone.today), 'h'],
              ['Verbleibend', stat.current_remaining_vacations, 'd'],
              ['Verbleibend', 0 - stat.overtime(Period.current_month).to_f, 'h']]]
    render partial: 'timeinfo', locals: { infos: infos }
  end
end
