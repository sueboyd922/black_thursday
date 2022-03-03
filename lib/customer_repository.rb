require 'csv'
require_relative '../lib/customer'
require_relative '../lib/repository_aide'

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
    search_name_fragment(@first_names, name)
  end

  def find_all_by_last_name(name)
    search_name_fragment(@last_names, name)
  end

  def search_name_fragment(search_repo, search_name)
    included_names = []
    search_repo.each do |name, info|
      included_names << info if name.downcase.include?(search_name.downcase)
    end
    included_names.flatten
  end

  def create(attributes)
    customer = Customer.new(create_attribute_hash(attributes))
    @repository << customer
    group_hash
    customer
  end
end
