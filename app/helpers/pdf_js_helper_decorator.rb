# frozen_string_literal: true
# Override Hyku 5

module PdfJsHelperDecorator
  def pdf_js_url(file_set_presenter)
    # Use import_url if file set is not yet characterized
    # assumes that the download path exists if the file set has been characterized
    url = if file_set_presenter.try(:mime_type)
            "/pdf.js/viewer.html?file=#{hyrax.download_path(file_set_presenter.id)}"

          else
            Array.wrap(file_set_presenter.solr_document["import_url_ssim"]).first
          end

    url + "##{query_param}"
  end

  def pdf_file_set_presenter(presenter)
    # currently only supports one pdf per work, falls back to the first pdf file set in ordered members

    # Commenting this line out because even PDFs that were not split will still have a representative media
    # which will be used first in this logic, consider uncommenting once all imports finish
    # representative_presenter(presenter) ||
    external_pdf(presenter)
  end

  def external_pdf(presenter)
    reader, archival = pdf_file_set_presenters(presenter.file_set_presenters).partition do |fsp|
      fsp.solr_document["import_url_ssim"]&.first&.include? "READER"
    end

    reader.first || archival.first
  end

  def pdf_file_set_presenters(presenters)
    presenters.select(&:pdf?).presence || presenters.select do |fsp|
      (fsp.solr_document['original_filename_tesi'] || fsp.solr_document['label_ssi'])&.downcase&.end_with?('.pdf')
    end
  end

  def representative_presenter(presenter)
    presenter.file_set_presenters.find { |file_set_presenter| file_set_presenter.id == presenter.representative_id }
  end

  def query_param
    search_params = current_search_session.try(:query_params) || {}
    q = search_params['q'].presence || ''

    "search=#{q}&phrase=true"
  end

  # overide the default behavior to deactivate checkboxes.
  # They do not seem to work for the work types defined in Hyrax or Hyku
  # and are preventing the PDF.js viewer from displaying.
  def render_show_pdf_behavior_checkbox?
    false
  end
end

PdfJsHelper.prepend(PdfJsHelperDecorator)
