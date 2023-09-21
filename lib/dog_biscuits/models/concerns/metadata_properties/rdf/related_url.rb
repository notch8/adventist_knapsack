# frozen_string_literal: true

module DogBiscuits
  module RelatedUrl
    extend ActiveSupport::Concern

    included do
      property :related_url, predicate: ::RDF::RDFS.seeAlso do |index|
        index.as :stored_searchable
      end
    end
  end
end
