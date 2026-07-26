module Search
  class ReindexAll
    INDEXED_MODELS = [ Member, Performance ].freeze

    def self.call
      new.call
    end

    def call
      Member.clear_index!
      Performance.clear_index!
      Performance.reindex!
      Member.reindex!

      INDEXED_MODELS.map(&:name)
    end
  end
end
