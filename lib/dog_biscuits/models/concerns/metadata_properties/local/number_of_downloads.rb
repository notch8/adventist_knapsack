# frozen_string_literal: true

module DogBiscuits
  module NumberOfDownloads
    extend ActiveSupport::Concern

    included do
      property :number_of_downloads, predicate: DogBiscuits::Vocab::Generic.numberOfDownloads,
                                     multiple: false do |index|
        index.as :stored_searchable
      end
    end
  end
end
