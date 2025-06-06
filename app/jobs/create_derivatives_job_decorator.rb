# frozen_string_literal: true

# OVERRIDE HYRAX 2.9.6 to conditionally skip derivative generation
module CreateDerivativesJobDecorator
  # @note Override to include conditional validation
  def perform(file_set, file_id, filepath = nil)
    return unless CreateDerivativesJobDecorator.create_derivative_for?(file_set:)
    super
  end

  ##
  # @see https://github.com/notch8/adventist-dl/issues/311 for discussion on structure
  #      of non-Archival PDF.
  NON_ARCHIVAL_PDF_SUFFIXES = [".reader.pdf", ".pdf-r.pdf"].freeze

  ##
  # We should not be creating derivatives for thumbnails.
  FILE_SUFFIXES_TO_SKIP_DERIVATIVE_CREATION = ([] + NON_ARCHIVAL_PDF_SUFFIXES).freeze

  # rubocop:disable Layout/LineLength
  def self.create_derivative_for?(file_set:)
    # Our options appear to be `file_set.label` or `file_set.original_file.original_name`; in
    # favoring `#label` we are avoiding a call to Fedora.  Is the label likely to be the original
    # file name?  I hope so.
    return false if FILE_SUFFIXES_TO_SKIP_DERIVATIVE_CREATION.any? { |suffix| file_set.label.downcase.end_with?(suffix) }

    true
  end
  # rubocop:enable Layout/LineLength
end

CreateDerivativesJob.prepend(CreateDerivativesJobDecorator)
