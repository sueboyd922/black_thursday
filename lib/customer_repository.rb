require 'csv'
require './lib/customer'
require './lib/repository_aide'

class CustomerRepository
  include RepositoryAide
  attr_reader :repository

  def initialize(file)
    @repository = read_csv(file).map do |customer|
        Customer.new({
          :id => customer[:id].to_i,
          :first_name => customer[:first_name],
          :last_name => customer[:last_name],
          :created_at => customer[:created_at],
          :updated_at => customer[:updated_at]
          })
        end
    group_hash
  end

  def group_hash
    @first_names = @repository.group_by {|customer| customer.first_name}
    @last_names = @repository.group_by {|customer| customer.last_name}
  end

  def find_all_by_first_name(name)
    find(@first_names, name)
  end

  def find_all_by_last_name(name)
    find(@last_names, name)
  end

  def create(attributes)
    customer = Customer.new(create_attribute_hash(attributes))
    @repository << customer
    customer
  end

  def update(id, attributes)
    customer = find_by_id(id)
    customer.first_name = attributes[:first_name]
    customer.last_name = attributes[:last_name]
    customer.updated_at = Time.now
  end
end
