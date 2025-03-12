# frozen_string_literal: true

# Generated via
#  `rails generate dog_biscuits:work Dataset`
class Dataset < DogBiscuits::Dataset
  include VideoEmbedBehavior
  include ::Hyrax::WorkBehavior
  include SlugBug

  self.indexer = ::DatasetIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
  include SlugMetadata
  include DogBiscuits::DatasetMetadata
  before_save :combine_dates

  prepend OrderAlready.for(:creator)
  include IiifPrint.model_configuration(
    pdf_split_child_model: self,
    pdf_splitter_service: IiifPrint::SplitPdfs::AdventistPagesToJpgsSplitter,
    derivative_service_plugins: [
      IiifPrint::TextExtractionDerivativeService
    ]
  )
end

Dataset.instance_variable_set(:@generated_resource_class, nil)
Dataset.resource_class.send(:include, ::Hyrax::BasicMetadata)
