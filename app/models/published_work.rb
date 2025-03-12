# frozen_string_literal: true

# Generated via
#  `rails generate dog_biscuits:work PublishedWork`
class PublishedWork < DogBiscuits::PublishedWork
  include VideoEmbedBehavior
  include ::Hyrax::WorkBehavior
  include SlugBug
  include DogBiscuits::BibliographicCitation
  include DogBiscuits::DateIssued
  include DogBiscuits::Geo
  include DogBiscuits::Extent
  include DogBiscuits::RemoteUrl

  self.indexer = ::PublishedWorkIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
  include SlugMetadata
  include DogBiscuits::PublishedWorkMetadata
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

PublishedWork.instance_variable_set(:@generated_resource_class, nil)
PublishedWork.resource_class.send(:include, ::Hyrax::BasicMetadata)
