# frozen_string_literal: true

# OVERRIDE Hyrax 5.0 to force POST for nested collection queries
# @todo - remove when Hyrax supports POST for nested collection queries
module Hyrax
  module Collections
    ##
    # A query service handling nested collection queries.
    module NestedCollectionQueryServiceDecorator
      extend ActiveSupport::Concern

      class_methods do
        private

        def query_solr(collection:, access:, scope:, limit_to_id:, nest_direction:)
          scope.blacklight_config.http_method = :post
          super
        end
      end
    end
  end
end

Hyrax::Collections::NestedCollectionQueryService.prepend(Hyrax::Collections::NestedCollectionQueryServiceDecorator)
