class Rrbayes

  attr_reader :categories, :db

  #creates a new classifier, takes 2 hashes of parameters
  #the first hash contains Rrbayes specific options
  #the second hash is passed to the backend Redis#new constructor
  #
  #  Rrbayes.new(:categories => %w(spam ham), {:host => '127.0.0.1'})
  #
  def initialize(options = {}, redis_options = {})
    raise "No categories specified for the classifier" unless options[:categories]
    @categories = options[:categories]
    @db = Redis.new(redis_options)
    @db.connect_to_server
    persist_categories
  end

  #takes a set of values occurrences and an :as parameter to 
  def learn(frequency_map, options)
    category = options[:as]
    evidences_key = evidences_key_for(category)
    @db.pipelined do |pipe|
      frequency_map.each do |value, evidences|
        pipe.incrby(key_for(category, value), evidences)
        pipe.incrby(evidences_key, evidences)
      end
    end
  end

  private

  def persist_categories
    @db.pipelined do |pipe| 
      @categories.each { |category| pipe.sadd('categories', category) }
    end
  end

  def key_for(category, value)
    "#{category}:#{value}"
  end

  def evidences_key_for(category)
    "#{category}_evidences"
  end

end
