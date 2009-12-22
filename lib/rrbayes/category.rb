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
      @db.pipelined do |pipe|
        frequency_map.each do |attribute, evidences|
          pipe.incrby(attribute_key(attribute), evidences)
          pipe.incrby(evidences_key, evidences)
        end
        pipe.incr(documents_key)
        pipe.incr(DOCUMENTS_SCOPE)
      end
    end

    def attributes_score(attributes)
      total = total_evidences.to_f
      attributes.map do |attribute, evidences|
        (evidences_for(attribute) || 0.1).to_f / total
      end.inject(0) do |score, attr_likelyhood|
        score + Math.log(attr_likelyhood)
      end
    end

    def evidences_for(attribute)
      @db.get(attribute_key(attribute))
    end

    def total_evidences
      @db.get(evidences_key)
    end

    private

    def attribute_key(attribute)
      key_for(name, attribute)
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
