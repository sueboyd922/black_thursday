require 'csv'
require 'time'
require 'pry'
require_relative '../lib/invoice'
require_relative '../lib/repository_aide'
require_relative '../lib/time_helper'

class InvoiceRepository
  include RepositoryAide
  include TimeHelper
  attr_reader :repository, :merchant_ids, :invoice_status, :day_invoices

  def initialize(file)
    @repository = read_csv(file).map do |invoice|
          Invoice.new({
            :id => invoice[:id].to_i,
            :customer_id => invoice[:customer_id].to_i,
            :merchant_id => invoice[:merchant_id].to_i,
            :status => invoice[:status].to_sym,
            :created_at => create_time(invoice[:created_at]),
            :updated_at => invoice[:updated_at]
            })
          end
    group_hash
  end

  def group_hash
    @customer_ids = @repository.group_by {|invoice| invoice.customer_id}
    @merchant_ids = @repository.group_by {|invoice| invoice.merchant_id}
    @invoice_status = @repository.group_by {|invoice| invoice.status}
    @day_invoices = @repository.group_by {|invoice| invoice.created_at.wday}
    @date_invoices = @repository.group_by { |invoice| invoice.created_at.strftime("%D")}
  end

  def find_all_by_date(date)
    find(@date_invoices, date.strftime("%D"))
  end

  def call_weekdays
    invoices_by_day = {}
    @day_invoices.map do |day, invoices|
      invoices_by_day[week_day(day)] = invoices
    end
    invoices_by_day
  end

  def find_all_by_customer_id(id)
    find(@customer_ids, id)
  end

  def find_all_by_merchant_id(id)
    find(@merchant_ids, id)
  end

  def find_all_by_status(status)
    find(@invoice_status, status)
  end

  def create(attributes)
    invoice = Invoice.new(create_attribute_hash(attributes))
    @repository << invoice
    group_hash
    invoice
  end
end
