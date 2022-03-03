
module AnalysisAide

  def num_times_items_ordered
    items_to_count = {}
    @sales_engine.invoice_items.item_ids.each do |id, list|
      items_to_count[@sales_engine.items.find_by_id(id)] = list.count
    end
    items_to_count
  end

  def merchant_items_hash
    merch_items = {}
    num_times_items_ordered.each do |item, count|
      merch_id = @sales_engine.merchants.find_by_id(item.merchant_id)
      merch_items[merch_id] = {} if !merch_items.key?(merch_id)
      merch_items[merch_id][count] = [] if !merch_items[merch_id].key?(count)
      merch_items[merch_id][count] << item
    end
    merch_items
 end

  def find_merchant_revenue_by_items(merchant_id)
    revenue = {}
    merchant_items_hash[@sales_engine.merchants.find_by_id(merchant_id)].each do |count, items|
      items.each {|item| revenue[item.unit_price * count] = item}
    end
    revenue
  end

  def merchant_revenues
    merchant_revenues_hash = {}
    @sales_engine.invoices.all.each do |invoice|
      merchant_id = invoice.merchant_id
      merchant_revenues_hash[merchant_id] = 0 if !merchant_revenues_hash.key?(merchant_id)
      merchant_revenues_hash[merchant_id] += invoice_total(invoice.id) if invoice_paid_in_full?(invoice.id)
    end
    merchant_revenues_hash
  end
end
