class Expense < ActiveRecord::Base
  include DateFormats
  belongs_to :client
  belongs_to :category, class_name: 'ExpenseCategory', foreign_key: 'category_id'
  belongs_to :tax1, :foreign_key => 'tax_1', :class_name => 'Tax'
  belongs_to :tax2, :foreign_key => 'tax_2', :class_name => 'Tax'

  paginates_per 10

  acts_as_archival
  acts_as_paranoid

  #scopes
  scope :multiple, lambda { |ids| where('id IN(?)', ids.is_a?(String) ? ids.split(',') : [*ids]) }

  # filter companies i.e active, archive, deleted
  def self.filter(params)
    mappings = {active: 'unarchived', archived: 'archived', deleted: 'only_deleted'}
    method = mappings[params[:status].to_sym]
    #params[:account].expenses.send(method).page(params[:page]).per(params[:per])
    Expense.send(method).page(params[:page]).per(params[:per])
  end

  def self.recover_archived(ids)
    multiple(ids).map(&:unarchive)
  end

  def self.recover_deleted(ids)
    multiple(ids).only_deleted.each { |expense| expense.restore; expense.unarchive }
  end

  def total
    amount + total_tax_amount
  end

  def total_tax_amount
    tax_amount = 0
    tax_amount += amount * (tax1.percentage / 100.0) if tax1.present?
    tax_amount += amount * (tax2.percentage / 100.0) if tax2.present?
    tax_amount
  end

end