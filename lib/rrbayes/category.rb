module Rrbayes

  class Category

    DOCUMENTS_SCOPE = 'documents'
    EVIDENCES_SCOPE = 'evidences'

    attr_reader :name

    def initialize(name, classifier)
      @name = name
      @db = classifier.db
      persist
    end

    def learn(frequency_map)
      @db.pipelined do
        frequency_map.each do |attribute, evidences|
          store_evidences(attribute, evidences)
        end
        increment_documents
      end
    end

    def attributes_score(attributes)
      total = evidences_total.to_f
      attributes.map do |attribute, evidences|
        (evidences_for(attribute) || 0.1).to_f / total
      end.inject(0) do |score, attr_likelyhood|
        score + Math.log(attr_likelyhood)
      end
    end

    def evidences_for(attribute)
      @db.hget(name, attribute)
    end

    def evidences_total
      @db.get(evidences_key)
    end

    def documents_total
      @db.get(documents_key)
    end

    private

    def store_evidences(attribute, evidences)
      @db.hincrby(name, attribute, evidences)
      @db.incrby(evidences_key, evidences)
    end

    def increment_documents
      @db.incr(documents_key)
      @db.incr(DOCUMENTS_SCOPE)
    end

    def evidences_key
      @evidences_key ||= key_for(EVIDENCES_SCOPE, name)
    end

    def documents_key
      @documents_key ||= key_for(DOCUMENTS_SCOPE, name)
    end

    def key_for(*args)
      args.join(':')
    end

    def persist
      @db.sadd('categories', name)
    end

  end

end
