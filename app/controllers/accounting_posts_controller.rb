# encoding: utf-8
class AccountingPostsController < CrudController

  self.permitted_attrs = [:closed, :offered_hours, :offered_rate, :discount_percent, :discount_fixed,
                          :portfolio_item_id, :reference, :billable, :description_required, :ticket_required,
                          work_item_attributes: [:name, :shortname, :description]]

  before_filter :order # make sure order is initialized before destroy/accessing in template
  before_save :check_book_on_order
  before_update :remember_old_work_item_id
  after_update :move_work_times

  helper_method :order, :book_on_order_allowed?

  private

  attr_reader :old_work_item_id

  def index_url
    cockpit_order_path(id: order.id)
  end

  def check_book_on_order
    if book_on_order_requested? && !book_on_order_allowed?
      flash[:alert] = "'Direkt auf Auftrag buchen' gewählt, aber es existieren bereits (andere) Buchungspositionen"
      false
    end
  end

  def build_entry
    super.tap { |p| p.build_work_item }
  end

  def book_on_order_requested?
    params['book_on_order'] == 'true'
  end

  def book_on_order_allowed?
    [[], [entry.id]].include?(order.accounting_posts.pluck(:id))
  end

  def book_on_order?
    book_on_order_requested? && book_on_order_allowed?
  end

  def book_on_order_change?
    book_on_order? ^ (entry.booked_on_order?)
  end

  def assign_attributes
    if entry.new_record?
      entry.work_item = book_on_order? ? order.work_item : WorkItem.new(work_item_attributes)
    else
      if book_on_order_change?
        entry.work_item = book_on_order? ? order.work_item : WorkItem.new(work_item_attributes)
      elsif !book_on_order?
        entry.attributes = model_params.slice(:work_item_attributes)
      end
    end
    entry.attributes = model_params.except(:work_item_attributes)
  end

  def work_item_attributes
    parent_id = book_on_order? ? order.work_item.parent_id : order.work_item_id
    (model_params[:work_item_attributes] || {}).merge(parent_id: parent_id)
  end

  def order
    @order ||= entry.new_record? ? Order.find(params.require(:order_id)) : entry.order
  end

  def remember_old_work_item_id
    @old_work_item_id = entry.work_item_id_was
  end

  def move_work_times
    if entry.work_item_id != old_work_item_id
      Worktime.where(work_item_id: old_work_item_id).update_all(work_item_id: entry.work_item_id)
      WorkItem.find(old_work_item_id).destroy unless old_work_item_id == order.work_item_id
    end
  end


end