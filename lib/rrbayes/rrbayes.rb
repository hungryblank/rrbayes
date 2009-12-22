module Rrbayes

  class Classifier

    attr_reader :categories, :db

    #creates a new classifier, takes 2 hashes
    #the first hash contains Rrbayes specific options
    #the second hash is passed to the backend Redis#new constructor
    #
    #  Rrbayes.new(:categories => %w(spam ham), {:host => '127.0.0.1'})
    #
    def initialize(options = {}, redis_options = {})
      raise "No categories specified for the classifier" unless options[:categories] || load_categories
      @db = Redis.new(redis_options)
      @db.connect_to_server
      @categories = options[:categories].map { |c| Category.new(c, self) }
    end

    #given a frequency hash and a category, stores teh frequency data
    #for the given catogory
    #
    #  classifier = Rrbayes.new(:categories => %w(spam ham))
    #  classifier.learn {'viagra' => 1, 'buy' => 1}, :as => 'spam'
    #
    def learn(frequency_map, options)
      category(options[:as]).learn(frequency_map)
    end

    #given a frequency hash tries to guess to which category
    #the hash is most likely to belong to
    #
    #  unknown_data = {'viagra' => 1, 'buy' => 1}
    #  classifier.classify(unknown_data)
    #  => 'spam'
    #
    def classify(frequency_map)
      @categories.map { |c| [c.name, c.attributes_score(frequency_map)] }.sort_by { |c| -c[1] }.first[0]
    end

    #Returns the category objects with the name provided in the argument
    def category(name)
      @categories.find { |c| c.name == name}
    end

    private

    def load_categories
      @db.set_members('categories')
    end

  end

end
