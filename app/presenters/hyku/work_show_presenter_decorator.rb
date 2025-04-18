# frozen_string_literal: true
# Override Hyku 5.0.1

module Hyku
  module WorkShowPresenterDecorator
    # Supports varying label on show page attributes by class
    def part_of_label
      klass = model_klass
      klass == JournalArticle ? 'Periodical' : 'Part Of'
    end

    # OVERRIDE incorporates fallback to PDF.js viewer via fileset's import_url, allowing
    # works with an import url to be displayed in the PDF.js viewer even if the file
    # failed to attach correctly.
    # see also pdf_js_helper_decorator
    # This also omits the show_pdf_viewer logic that is in hyku, as it is not currently fully functional for adventist and prevents PDFs from displaying when they should in some cases.
    # @return [Boolean] render a PDF.js viewer
    def show_pdf_viewer?
      return false unless Flipflop.default_pdf_viewer? || !iiif_viewer?
      # return false unless show_pdf_viewer
      # return false unless file_set_presenters.any?(&:pdf?) || pdf_extension?
      file_set_presenters.any?(&:pdf?) || pdf_extension?
      # show_for_pdf?(show_pdf_viewer)
    end

    # OVERRIDE Hyku TenantConfig to fall back to PDFjs viewer if we have a pdf that hasn't been split so we don't get a blank viewer
    # @return [Boolean] render a IIIF viewer
    def iiif_viewer?
      no_child_works = member_presenters.all? { |presenter| presenter.is_a? Hyrax::FileSetPresenter }
      # Fall back to PDFjs viewer if we have a pdf that hasn't been split
      return false if no_child_works && (file_set_presenters.any?(&:pdf?) || pdf_extension?)
      # Use the standard behavior from TenantConfig
      Hyrax.config.iiif_image_server? &&
        representative_id.present? &&
        representative_presenter.present? &&
        iiif_media? &&
        members_include_iiif_viewable?
    end

    def pdf_extension?
      # Valkyrie works are apparently not getting label assigned, but earlier works
      # used label for file name. Using a combination of both.
      file_set_presenters.any? do |fsp|
        (fsp.solr_document['original_filename_tesi'] || fsp.solr_document['label_ssi'])&.downcase&.end_with?('.pdf')
      end
    end

    private

    def model_klass
      model_name.instance_variable_get(:@klass)
    end
  end
end

Hyku::WorkShowPresenter.prepend Hyku::WorkShowPresenterDecorator
Hyku::WorkShowPresenter.delegate :bibliographic_citation, :alt, to: :solr_document
