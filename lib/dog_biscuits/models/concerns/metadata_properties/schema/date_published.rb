# frozen_string_literal: true

module DogBiscuits
  module DatePublished
    extend ActiveSupport::Concern

    included do
      property :date_published, predicate: RDF::Vocab::SCHEMA.datePublished do |index|
        index.as :stored_searchable, :facetable, :stored_sortable
      end
    end
  end
end
