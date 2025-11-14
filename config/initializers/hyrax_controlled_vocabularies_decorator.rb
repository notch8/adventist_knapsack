# frozen_string_literal: true

# OVERRIDE Hyku 6.2.0.rc3 to add custom local authorities for flexible=false

module Hyrax
  module ControlledVocabulariesDecorator
    extend ActiveSupport::Concern
    class_methods do
      def controlled_vocab_mappings
        super.merge(
          {
            'content_version' => 'content_versions',
            'publication_status' => 'publication_statuses',
            'qualification_level' => 'qualification_levels',
            'qualification_name' => 'qualification_names',
            'resource_type_general' => 'resource_type_generals',
          }
        )
      end

      def services
        super.merge(
          {
            'content_versions' => 'AuthorityService::ContentVersionsService',
            'publication_statuses' => 'AuthorityService::PublicationStatusesService',
            'qualification_levels' => 'AuthorityService::QualificationLevelsService',
            'qualification_names' => 'AuthorityService::QualificationNamesService',
            'resource_type_generals' => 'AuthorityService::ResourceTypeGeneralsService'
          }
        )
      end
    end
  end
end

Hyrax::ControlledVocabularies.prepend(Hyrax::ControlledVocabulariesDecorator)
