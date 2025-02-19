require './lib/sales_analyst'
require './lib/sales_engine'
require 'rspec'
require 'bigdecimal'

describe Analyst do
  before (:each) do
    @sales_engine = SalesEngine.from_csv({
  :items     => "./data/items.csv",
  :merchants => "./data/merchants.csv",
  :invoice_items => "./data/invoice_items.csv",
  :invoices => "./data/invoices.csv",
  :customers => "./data/customers.csv",
  :transactions => "./data/transactions.csv"
  })
    @sales_analyst = Analyst.new(@sales_engine)
  end

  it 'exists' do
    se = @sales_engine.analyst
    expect(se.class).to eq(Analyst)
  end

  it "finds average" do
    expect(@sales_analyst.average_items_per_merchant).to eq(2.88)
  end

  it "finds standard_devation" do
    expect(@sales_analyst.average_items_per_merchant_standard_deviation).to eq(3.26)
  end

  it "finds merchants_with_high_item_count" do
    expect(@sales_analyst.merchants_with_high_item_count.count).to eq(52)
  end

  it "finds average item price per merchant" do
    expect(@sales_analyst.average_item_price_for_merchant(12334185)).to eq(10.78)
    expect(@sales_analyst.average_item_price_for_merchant(12334185)).to be_a(BigDecimal)
  end

  it "finds average_average_price_per_merchant" do
    expect(@sales_analyst.average_average_price_per_merchant).to eq(350.29)
    expect(@sales_analyst.average_average_price_per_merchant).to be_a(BigDecimal)
  end

  it "finds the golden items" do
    expect(@sales_analyst.golden_items.count).to eq(5)
  end

  it "finds the average_invoices_per_merchant" do
    expect(@sales_analyst.average_invoices_per_merchant).to eq(10.49)
  end

  it "finds the average invoices per merchant standard_devation" do
    expect(@sales_analyst.average_invoices_per_merchant_standard_deviation).to eq(3.29)
  end

  it "find merchants with high invoice count" do
    expect(@sales_analyst.top_merchants_by_invoice_count.count).to eq(12)
  end

  it "finds merchants with low invoice count" do
    expect(@sales_analyst.bottom_merchants_by_invoice_count.count).to eq(4)
  end

  it "can tell the day of the week" do
    expect(@sales_analyst.top_days_by_invoice_count).to eq(["Wednesday"])
  end

  it "can find invoices by status and returns a percent" do
    expect(@sales_analyst.invoice_status(:pending)).to eq(29.55)
    expect(@sales_analyst.invoice_status(:shipped)).to eq(56.95)
    expect(@sales_analyst.invoice_status(:returned)).to eq(13.5)
  end

  it "determines if invoice has been paid in full" do
    expect(@sales_analyst.invoice_paid_in_full?(46)).to eq(true)
    expect(@sales_analyst.invoice_paid_in_full?(204)).to eq(false)
  end

  it "returns total $ amount of invoice with corresponding invoice_id" do
    expect(@sales_analyst.invoice_total(1)).to eq(21067.77)
  end

  it 'can find the most sold item for a merchant' do
    items = @sales_analyst.most_sold_item_for_merchant(12336965)
    expect(items.count).to eq(2)
    expect(items.first.class).to eq(Item)
  end

  it 'can find the item that generates the most revenue per merchant' do
    item = @sales_analyst.best_item_for_merchant(12336965)
    all_items = @sales_analyst.find_merchant_revenue_by_items(12336965)
    expect(all_items.values.include?(item)).to be true
    highest_item = all_items.keys.sort.last
    expect(all_items[highest_item]).to eq(item)
  end

  it "returns total revenue for given date" do
    date = Time.parse("2009-12-09")
    expected = @sales_analyst.total_revenue_by_date(date)
    expect(expected).to eq 30158.61
    expect(expected.class).to eq BigDecimal
  end

  it "finds top earning merchants" do
      top_merchants = @sales_analyst.top_revenue_earners(5)

      expect(top_merchants.count).to eq(5)
      expect(top_merchants.first.class).to eq Merchant
      expect(top_merchants.first.id).to eq 12334634
  end

  it "returns an array of merchants with pending invoices" do
    expect(@sales_analyst.merchants_with_pending_invoices.count).to eq(343)
  end

  it "returns merchants_with_only_one_item" do
    expect(@sales_analyst.merchants_with_only_one_item.count).to eq(243)
  end

  it "returns an array of merchant/oneitem/month" do
    expect(@sales_analyst.merchants_with_only_one_item_registered_in_month("March").count).to be(21)
    expect(@sales_analyst.merchants_with_only_one_item_registered_in_month("June").count).to be(18)
  end

  it "returns total revenue of merchant" do
    expect(@sales_analyst.revenue_by_merchant(12335938)).to eq(126300.9)
  end

end
