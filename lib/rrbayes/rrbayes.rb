module Rrbayes

  class LoadingError < ArgumentError
  end

  class Classifier

    attr_reader :categories, :db

    #creates a new classifier, takes 2 hashes
    #the first hash contains Rrbayes specific options
    #the second hash is passed to the backend Redis#new constructor
    #
    #  Rrbayes.new(:categories => %w(spam ham), {:host => '127.0.0.1'})
    #
    def initialize(options = {}, redis_options = {})
      @db = Redis.new(redis_options)
      @categories = find_categories(options).map { |c| Category.new(c, self) }
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
      @categories.sort_by { |c| -c.attributes_score(frequency_map) }.first.name
    end

    #Returns the category objects with the name provided in the argument
    def category(name)
      @categories.find { |c| c.name == name}
    end

    private

    def load_categories
      @db.smembers('categories')
    end

    def find_categories(options)
      categories = load_categories
      if categories.empty?
        categories = options[:categories]
        raise LoadingError, "No categories specified for the classifier" unless categories
      elsif options[:categories] && options[:categories].sort != categories.sort
        raise LoadingError, "you specified categories #{options[:as].inspect} but #{categories.inspect} were found in the db"
      end
      categories
    end

  end

end
