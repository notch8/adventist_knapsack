# frozen_string_literal: true

module DogBiscuits
  module DateCreated
    extend ActiveSupport::Concern

    included do
      property :date_created, predicate: ::RDF::Vocab::DC.created do |index|
        index.as :stored_searchable, :facetable, :stored_sortable
      end
    end
  end
end
