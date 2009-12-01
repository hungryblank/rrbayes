require 'teststrap'

context "creating a new classifier" do

  setup do
    db = Redis.new
    db.connect_to_server
    db.flushall
    Rrbayes.new :categories => %w(spam ham)
  end

  should("cache categories") { topic.categories }.equals %w(spam ham)

  should("persist categories") { topic.db.set_members('categories') }.equals %w(spam ham)

end

context "training a classifier" do

  setup do
    db = Redis.new
    db.connect_to_server
    db.flushall
    @classifier = Rrbayes.new :categories => %w(spam ham)
  end

  context "learning spam" do

    setup do
      spam_frequencies = {'enlarge' => 1, 'your' => 2 ,'viagra' => 3}
      @classifier.learn(spam_frequencies, :as => 'spam')
    end

    should("store evidences number") { @classifier.db['spam:viagra'] }.equals '3'

  end

end
