require 'teststrap'

include Rrbayes

DB_NUM = 0

context "a new spam/ham classifier" do

  setup do
    db = Redis.new :db => DB_NUM
    db.connect_to_server
    db.flushdb
    @classifier = Classifier.new({:categories => %w(spam ham)}, :db => DB_NUM)
  end

  asserts("categories") { topic.db.set_members('categories') }.equals %w(spam ham)

  asserts("loaded categories") { topic.send(:load_categories) }.equals %w(spam ham)

  asserts("recognized categories") { Classifier.new({}, :db => DB_NUM).categories.map { |c| c.name } }.equals %w(spam ham)


  asserts("initialize with same categories") { Classifier.new({:categories => %w(spam ham)}, :db => DB_NUM).categories.map { |c| c.name } == %w(spam ham) }

  should("detect category mismatch") { Classifier.new({:categories => %w(bad good)}, :db => DB_NUM) }.raises(LoadingError)

  context "trained with spam and ham" do

    setup do
      spam_frequencies = {'enlarge' => 1, 'your' => 2 ,'viagra' => 3}
      @classifier.learn(spam_frequencies, :as => 'spam')

      ham_frequencies = {'dear' => 1, 'Jon' => 2 ,'how' => 3}
      @classifier.learn(ham_frequencies, :as => 'ham')
    end

    asserts("evidences number") { @classifier.db['spam:viagra'] }.equals '3'

    asserts("category evidences total") { @classifier.db['documents:spam'] }.equals '1'

    asserts("evidences total") { @classifier.db['documents'] }.equals '2'

    should("classify spam") { @classifier.classify({'viagra' => 1, 'cheap' => 1}) == 'spam' }

    should("classify ham") { @classifier.classify({'dear' => 1, 'molly' => 2}) == 'ham' }

  end

end
