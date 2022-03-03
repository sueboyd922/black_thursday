
module RepositoryAide

  def read_csv(file)
    CSV.read(file, headers: true, header_converters: :symbol)
  end

  def all
    @repository
  end

  def inspect
    "#<#{self.class} #{@merchants.size} rows>"
  end

  def find(search_repo, match)
    return [] if search_repo[match].nil?
    search_repo[match]
  end

  def find_by_id(id)
    @repository.find {|element| element.id == id.to_i}
  end
  
  def new_id
    new_id = @repository.sort_by {|element| element.id}.last.id
    new_id += 1
  end

  def create_attribute_hash(attributes)
    attribute_hash = {}
    attributes.each {|key, value| attribute_hash[key] = value}
    attribute_hash[:id] = new_id
    attribute_hash[:created_at] = Time.new
    attribute_hash[:updated_at] = Time.new
    attribute_hash
  end

  def update(id, attributes)
    update = find_by_id(id)
    unless update.nil?
      attributes.each do |key, value|
        find_by_id(id).instance_variable_set(key.to_s.insert(0, '@').to_sym, value)
      end
      update.updated_at = Time.now
    end
  end

  def delete(id)
    @repository.delete(find_by_id(id))
  end

  def significant_numbers(number)
    number.length
  end
end
