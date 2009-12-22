require 'teststrap'

include Rrbayes

context "a new classifier" do

  setup do
    db = Redis.new :db => 'rrbayes_test'
    db.connect_to_server
    db.flushdb
    @classifier = Classifier.new({:categories => %w(spam ham)}, :db => 'rrbayes_test')
  end

  should("persist categories") { topic.db.set_members('categories') }.equals %w(spam ham)

  should("load categories") { topic.send(:load_categories) }.equals %w(spam ham)

  should("initialize with no categories") { Classifier.new.categories.map { |c| c.name } }.equals %w(spam ham)

  should("initialize with same categories") { Classifier.new(:categories => %w(spam ham)).categories.map { |c| c.name } }.equals %w(spam ham)

  should("detect category mismatch") { Classifier.new({:categories => %w(bad good)}) }.raises(LoadingError)

  context "in training" do

    setup do
      spam_frequencies = {'enlarge' => 1, 'your' => 2 ,'viagra' => 3}
      @classifier.learn(spam_frequencies, :as => 'spam')

      ham_frequencies = {'dear' => 1, 'Jon' => 2 ,'how' => 3}
      @classifier.learn(ham_frequencies, :as => 'ham')
    end

    should("store evidences number") { @classifier.db['spam:viagra'] }.equals '3'

    should("store category evidences total") { @classifier.db['documents:spam'] }.equals '1'

    should("store evidences total") { @classifier.db['documents'] }.equals '2'

    context "for a while" do

      should("classify_spam") { @classifier.classify({'viagra' => 1, 'cheap' => 1}) }.equals 'spam'

      should("classify_ham") { @classifier.classify({'dear' => 1, 'molly' => 2}) }.equals 'ham'

    end

  end

end
