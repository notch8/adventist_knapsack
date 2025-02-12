# frozen_string_literal: true

##
# This job is responsible for finding file sets that may need re-processing and then dispatching new
# jobs to perform that processing.
#
# The reasons are two fold, and addressed by the two jobs:
#
# 1. We did not successfully split a PDF; handled by ConditionallyResplitFileSetJob
# 2. We did not successfully attach a PDF; handled by ConditionallyResplitFileSetJob
class FileSetsReprocessJob < ApplicationJob
  ##
  # @param cname [String, Symbol] when given :all, submit one {FileSetsReprocessJob} per tenant.
  #        Otherwise, switch to the given tenant and submit a {FileSetsReprocessJob}
  def self.for_tenant(cname = :all)
    if cname == :all
      Account.all.find_each do |account|
        account.switch!
        FileSetsReprocessJob.perform_later
      end
    else
      Account.switch!(cname)
      FileSetsReprocessJob.perform_later
    end
  end

  class_attribute :solr_page_size, default: 1000
  class_attribute :solr_q_parameter,
                  default: "(mime_type_ssi:application/pdf OR label_ssi:*.pdf) AND has_model_ssim:FileSet"
  class_attribute :solr_fl_parameter, default: 'id,label_ssi,mime_type_ssi'
  class_attribute :desired_mime_type, default: "application/pdf"

  def perform
    count = ActiveFedora::SolrService.count(solr_q_parameter)

    (0..(1 + (count / solr_page_size))).each do |page|
      ActiveFedora::SolrService.query(solr_q_parameter,
                                      fl: solr_fl_parameter,
                                      rows: solr_page_size,
                                      start: page * solr_page_size).each do |document|
        if document[:mime_type_ssi] == desired_mime_type
          # Given that we have a mime_type we can assume that we've successfully attached the file.
          ConditionallyResplitFileSetJob.perform_later(file_set_id: document[:id])
        else
          # We have failed to attach the file to the work.
          ConditionallyReingestFileSetJob.perform_later(file_set_id: document[:id])
        end
      end
    end
  end

  ##
  # A helper module for conditionally finding a file set.
  #
  # @see #find
  module FileSetFinder
    ##
    # @param file_set_id [String]
    # @return [FileSet] when the given :file_set_id is found.
    # @return [FalseClass] when the given :file_set_id is not found.
    def self.find(file_set_id:)
      FileSet.find(file_set_id)
    rescue ActiveFedora::ObjectNotFoundError
      message = "#{self.class}##{__method__} unable to find FileSet with ID=#{file_set_id}.  " \
                "It may have been deleted between the enqueuing of this job and running this job."
      Rails.logger.warning(message)
      false
    end
  end

  ##
  # This job conditionally re-splits a file_set's PDF.  How do we know if we need to re-split
  # it?  See the {#perform} method for details.
  #
  # 1. The file_set is a PDF.
  # 2. The file_set's PDF is one that we would normally split.
  # 3. The file_set's parent does not have child works; the assumption being that if it doesn't
  #    have child works, then
  class ConditionallyResplitFileSetJob < ApplicationJob
    ##
    # @param file_set_id [String]
    #
    # @return [Symbol] A terse explanation of what was done with this job.
    #
    # @raise [ActiveFedora::ObjectNotFoundError] when the given FileSet's parent could not be found.
    # rubocop:disable Layout/LineLength
    def perform(file_set_id:)
      file_set = FileSetFinder.find(file_set_id:)

      # We've logged this (see FileSetFinder.find) so we'll move along.
      return :file_set_not_found unless file_set

      # When we aren't working with a PDF, let's not proceed.
      return :not_a_pdf unless file_set.pdf?

      # When the PDF we are working with isn't something we split, let's bail.
      return :non_splitting_pdf unless IiifPrint::SplitPdfs::AdventistPagesToJpgsSplitter.split_this?(path: file_set.label)

      parent = IiifPrint.parent_for(file_set)

      raise ActiveFedora::ObjectNotFoundError, "Expected #{file_set.class} ID=#{file_set.id} to have a parent record." unless parent

      return :parent_does_not_split unless parent.try(:iiif_print_config).try(:pdf_splitter_service)

      # When the parent has children, assume that we've already previously succeeded on splitting
      # this PDF.
      return :has_children if parent.child_work_ids.any?

      IiifPrint::Jobs::RequestSplitPdfJob.perform_later(file_set_id:, user: User.batch_user)
      :requesting_split
    end
    # rubocop:enable Layout/LineLength
  end

  ##
  #
  class ConditionallyReingestFileSetJob < ApplicationJob
    ##
    # @param file_set_id [String]
    # @return [Symbol] A terse explanation of what was done with this job.
    def perform(file_set_id:)
      file_set = FileSetFinder.find(file_set_id:)

      # We've logged this (see FileSetFinder.find) so we'll move along.
      :file_set_not_found unless file_set

      # TODO: The file set does not appear to have a properly attached file.
    end
  end
end
