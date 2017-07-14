# encoding: UTF-8

require 'test_helper'

class Employees::WorktimesReviewControllerTest < ActionController::TestCase

  def test_edit_as_manager
    login_as(:mark)
    employee = employees(:various_pedro)
    employee.update!(reviewed_worktimes_at: Date.new(2015, 8, 31))
    get :edit, employee_id: employee.id
    assert_template '_form'

    selection = assigns(:dates)
    assert_equal selection.size, 13
    assert_equal selection.first.first, Time.zone.today.end_of_month
    assert_equal assigns(:selected_month), Date.new(2015, 9, 30)
  end

  def test_edit_as_regular_user_is_not_allowed
    login_as(:various_pedro)
    assert_raise(CanCan::AccessDenied) do
      get :edit, employee_id: employees(:various_pedro).id
    end
  end

  def test_edit_as_regular_user_is_not_allowed_for_somebody_else
    login_as(:various_pedro)
    assert_raise(CanCan::AccessDenied) do
      get :edit, employee_id: employees(:mark).id
    end
  end
end