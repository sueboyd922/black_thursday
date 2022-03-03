require_relative '../lib/mathable'
require_relative '../lib/merchants_repository'
require_relative '../lib/items_repository'
require_relative '../lib/invoice_repository'
require_relative '../lib/time_helper'
require_relative '../lib/transaction_repository'
require_relative '../lib/invoice_items_repository'
require_relative '../lib/analysis_aide'

require "bigdecimal"
require "bigdecimal/util"

require 'pry'

class Analyst
  include Mathable
  include TimeHelper
  include AnalysisAide

  def initialize(sales_engine)
    @sales_engine = sales_engine
  end

  def average_items_per_merchant
    average(@sales_engine.items.repository.count.to_f, @sales_engine.merchants.repository.count)
  end

  def average_items_per_merchant_standard_deviation
    merchant_item_numbers = @sales_engine.items.merchant_ids.values.map { |list| list.count }
    stn_dev = standard_devation(merchant_item_numbers, average_items_per_merchant)
  end

  def merchants_with_high_item_count
    big_sellers = @sales_engine.items.merchant_ids.select do |merchant, items|
      items.count > (average_items_per_merchant + average_items_per_merchant_standard_deviation)
    end
    big_sellers.keys.map {|id| @sales_engine.merchants.find_by_id(id)}
  end


  def average_item_price_for_merchant(merchant_id)
    items = @sales_engine.items.find_all_by_merchant_id(merchant_id)
    unit_price_array = items.map { |price| price.unit_price}
    average_price = average(unit_price_array.sum, unit_price_array.count)
    in_dollars = (average_price / 100).round(2)
  end

  def average_average_price_per_merchant
    array_of_prices = @sales_engine.merchants.repository.map do |merchant|
      average_item_price_for_merchant(merchant.id)
    end
    average = average(array_of_prices.sum, array_of_prices.count)
    return average
  end

  def golden_items
    list = @sales_engine.items.repository.map { |item| item.unit_price.to_i}
    mean = average(list.sum, list.count)
    std_dev = standard_devation(list, mean)
    golden_items = @sales_engine.items.repository.select do |gi|
      gi.unit_price.to_i > (mean + (std_dev * 2))
    end
  end

  def average_invoices_per_merchant
    average(@sales_engine.invoices.repository.count.to_f, @sales_engine.merchants.repository.count)
  end

  def average_invoices_per_merchant_standard_deviation
    merchant_invoice_list = @sales_engine.invoices.merchant_ids.map { |id, invoices| invoices.count}
    std_dev = standard_devation(merchant_invoice_list, average_invoices_per_merchant)
  end

  def top_merchants_by_invoice_count
    top_sellers = @sales_engine.invoices.merchant_ids.select do |id, list|
      list.count > (average_invoices_per_merchant + (average_items_per_merchant_standard_deviation * 2))
    end
    top_sellers.keys.map {|id| @sales_engine.merchants.find_by_id(id)}
  end

  def bottom_merchants_by_invoice_count
    bottom_sellers = @sales_engine.invoices.merchant_ids.select do |id, list|
      list.count < (average_invoices_per_merchant - (average_invoices_per_merchant_standard_deviation * 2))
    end
  end

  def top_days_by_invoice_count
    invoices_per_day = @sales_engine.invoices.call_weekdays.map { |day, invoices| invoices.count}
    mean = average(invoices_per_day.sum.to_f, invoices_per_day.count)
    std_dev = standard_devation(invoices_per_day, mean)
    top_days = @sales_engine.invoices.call_weekdays.select do |day, invoices|
      invoices.count > (mean + std_dev)
    end
    top_days.keys
  end

  def invoice_status(status)
    decimal = (@sales_engine.invoices.invoice_status[status].count.to_f / @sales_engine.invoices.repository.count)
    percentage = (decimal * 100).round(2)
  end

  def invoice_paid_in_full?(invoice_id)
    transactions = @sales_engine.transactions.find_all_by_invoice_id(invoice_id)
    return false if transactions.nil?
    if transactions.map {|transaction| transaction.result }.include?(:success)
      true
    else
      false
    end
  end

  def invoice_total(invoice_id)
    invoice_items = @sales_engine.invoice_items.find_all_by_invoice_id(invoice_id)
    sum = 0
    invoice_items.each { |invoice_item| sum += ((invoice_item.unit_price.to_f * invoice_item.quantity.to_f)/100.0) }
    sum
  end


  def most_sold_item_for_merchant(merchant_id)
    m_id = @sales_engine.merchants.find_by_id(merchant_id)
    high_count = merchant_items_hash[m_id].keys.sort.last
    items_with_high_count = merchant_items_hash[m_id][high_count]
  end

  def best_item_for_merchant(merchant_id)
    revenue = find_merchant_revenue_by_items(merchant_id)
    highest_revenue = revenue.keys.sort.last
    revenue[highest_revenue]
  end

  def merchants_with_pending_invoices
  coolio = @sales_engine.invoices.invoice_status[:pending].find_all do |invoice|
            invoice_paid_in_full?(invoice.id) == false
          end
  yeah = coolio.map do |invoice|
    invoice.merchant_id
  end
  array = []
  yeah.each do |merchant_id|
    array << @sales_engine.merchants.find_by_id(merchant_id)
  end
  array.uniq
  end

  def total_revenue_by_date(date)
    invoice_id_by_date = @sales_engine.invoices.find_all_by_date(date).map { |invoice| invoice.id}
    invoice_items_by_date = invoice_id_by_date.map {|invoice_id| @sales_engine.invoice_items.find_all_by_invoice_id(invoice_id)}
    revenue = invoice_items_by_date.flatten.map { |invoice| (invoice.unit_price * invoice.quantity)}.sum / 100
  end

  def top_revenue_earners(x)
    sorted_merchants = merchant_revenues.values.sort.reverse.first(x)
    top_merchants = sorted_merchants.map {|revenue| @sales_engine.merchants.find_by_id(merchant_revenues.key(revenue))}
  end

  def merchants_with_only_one_item
    array_of_m_ids = []
    @sales_engine.items.merchant_ids.each do |id, item|
      array_of_m_ids << id if item.count == 1
    end
    array_of_merchants = array_of_m_ids.map { |id| @sales_engine.merchants.find_by_id(id)}
  end

  def merchants_with_only_one_item_registered_in_month(month)
    merchants_by_month = merchants_with_only_one_item.group_by { |merchant| merchant.created_at.month}
    merchants_by_month[months(month)]
  end
  
  def revenue_by_merchant(merchant_id)
    merchant_revenues[merchant_id]
  end

end
