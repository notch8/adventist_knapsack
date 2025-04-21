# frozen_string_literal: true

module AdlSolrDocumentDecorator
  module ClassMethods
    def attribute(name, type, field)
      define_method name do
        type.coerce(self[field])
      end
    end

    def solr_name(*args)
      ActiveFedora.index_field_mapper.solr_name(*args)
    end
  end

  module Solr
    class Array
      # @return [Array]
      def self.coerce(input)
        ::Array.wrap(input)
      end
    end

    class String
      # @return [String]
      def self.coerce(input)
        ::Array.wrap(input).first
      end
    end

    class Date
      # @return [Date]
      def self.coerce(input)
        field = String.coerce(input)
        return if field.blank?
        begin
          ::Date.parse(field)
        rescue ArgumentError
          Rails.logger.info "Unable to parse date: #{field.first.inspect}"
        end
      end
    end
  end

  # Keep these alphebetized; comments indicate those in basic_metadata
  #   see https://github.com/samvera/hyrax/blob/master/app/models/concerns/hyrax/solr_document/metadata.rb
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def self.prepended(base)
    base.attribute :abstract, Solr::Array, base.solr_name('abstract')
    base.attribute :access_provided_by, Solr::Array, base.solr_name('access_provided_by')
    base.attribute :advisor, Solr::Array, base.solr_name('advisor')
    base.attribute :alt, Solr::Array, base.solr_name('alt')
    base.attribute :awarding_institution, Solr::Array, base.solr_name('awarding_institution')
    # based_near and based_near
    base.attribute :content_version, Solr::Array, base.solr_name('content_version')
    # contributor
    # creator
    base.attribute :date, Solr::Array, base.solr_name('date')
    base.attribute :date_accepted, Solr::Array, base.solr_name('date_accepted')
    base.attribute :date_available, Solr::Array, base.solr_name('date_available')
    base.attribute :date_collected, Solr::Array, base.solr_name('date_collected')
    base.attribute :date_copyrighted, Solr::Array, base.solr_name('date_copyrighted')
    base.attribute :date_issued, Solr::Array, base.solr_name('date_issued')
    # date_created
    base.attribute :date_of_award, Solr::Array, base.solr_name('date_of_award')
    base.attribute :date_published, Solr::Array, base.solr_name('date_published')
    base.attribute :date_submitted, Solr::Array, base.solr_name('date_submitted')
    base.attribute :date_updated, Solr::Array, base.solr_name('date_updated')
    base.attribute :date_valid, Solr::Array, base.solr_name('date_valid')
    base.attribute :dc_access_rights, Solr::Array, base.solr_name('dc_access_rights')
    base.attribute :department, Solr::Array, base.solr_name('department')
    # description
    base.attribute :doi, Solr::Array, base.solr_name('doi')
    base.attribute :edition, Solr::Array, base.solr_name('edition')
    base.attribute :editor, Solr::Array, base.solr_name('editor')
    base.attribute :end_date, Solr::Array, base.solr_name('end_date')
    base.attribute :event_date, Solr::Array, base.solr_name('event_date')
    base.attribute :extent, Solr::Array, base.solr_name('extent')
    base.attribute :dc_format, Solr::Array, base.solr_name('dc_format')
    base.attribute :former_identifier, Solr::Array, base.solr_name('former_identifier')
    base.attribute :funder, Solr::Array, base.solr_name('funder')
    base.attribute :resource_type_general, Solr::Array, base.solr_name('resource_type_general')
    base.attribute :has_restriction, Solr::Array, base.solr_name('has_restriction')
    # rubocop:enable Naming/PredicateName

    # identifier
    base.attribute :isbn, Solr::Array, base.solr_name('isbn')
    base.attribute :issue_number, Solr::Array, base.solr_name('issue_number')
    # keyword
    # language
    base.attribute :last_access, Solr::Array, base.solr_name('last_access')
    base.attribute :lat, Solr::Array, base.solr_name('lat')
    # license
    base.attribute :location, Solr::Array, base.solr_name('location')
    base.attribute :long, Solr::Array, base.solr_name('long')
    base.attribute :managing_organisation, Solr::Array, base.solr_name('managing_organisation')
    base.attribute :module_code, Solr::Array, base.solr_name('module_code')
    base.attribute :note, Solr::Array, base.solr_name('note')
    base.attribute :number_of_downloads, Solr::Array, base.solr_name('last_access')
    base.attribute :official_url, Solr::Array, base.solr_name('official_url')
    base.attribute :output_of, Solr::Array, base.solr_name('output_of')
    base.attribute :official_url, Solr::Array, base.solr_name('official_url')
    base.attribute :packaged_by_ids, Solr::Array, base.solr_name('packaged_by_ids', :symbol)
    base.attribute :package_ids, Solr::Array, base.solr_name('package_ids', :symbol)
    base.attribute :pagination, Solr::Array, base.solr_name('pagination')
    base.attribute :part, Solr::Array, base.solr_name('part')
    base.attribute :place_of_publication, Solr::Array, base.solr_name('place_of_publication')
    base.attribute :presented_at, Solr::Array, base.solr_name('presented_at')
    base.attribute :part_of, Solr::Array, base.solr_name('part_of')
    base.attribute :project, Solr::Array, base.solr_name('project')
    base.attribute :publication_status, Solr::Array, base.solr_name('publication_status')
    # publisher
    base.attribute :qualification_level, Solr::Array, base.solr_name('qualification_level')
    base.attribute :qualification_name, Solr::Array, base.solr_name('qualification_name')
    base.attribute :refereed, Solr::Array, base.solr_name('refereed')
    base.attribute :related_url, Solr::Array, base.solr_name('related_url')
    # resource_type
    # rights_statement
    base.attribute :series, Solr::Array, base.solr_name('series')
    # source
    base.attribute :start_date, Solr::Array, base.solr_name('start_date')
    # subject
    base.attribute :subtitle, Solr::Array, base.solr_name('subtitle')
    base.attribute :volume_number, Solr::Array, base.solr_name('volume_number')
    # archivematica
    base.attribute :aip_uuid, Solr::Array, base.solr_name('aip_uuid')
    base.attribute :transfer_uuid, Solr::Array, base.solr_name('transfer_uuid')
    base.attribute :sip_uuid, Solr::Array, base.solr_name('sip_uuid')
    base.attribute :dip_uuid, Solr::Array, base.solr_name('dip_uuid')
    base.attribute :aip_status, Solr::Array, base.solr_name('aip_status')
    base.attribute :dip_status, Solr::Array, base.solr_name('dip_status')
    base.attribute :aip_size, Solr::Array, base.solr_name('aip_size')
    base.attribute :dip_size, Solr::Array, base.solr_name('dip_size')
    base.attribute :aip_current_path, Solr::Array, base.solr_name('aip_current_path')
    base.attribute :dip_current_path, Solr::Array, base.solr_name('dip_current_path')
    base.attribute :aip_current_location, Solr::Array, base.solr_name('aip_current_location')
    base.attribute :dip_current_location, Solr::Array, base.solr_name('dip_current_location')
    base.attribute :aip_resource_uri, Solr::Array, base.solr_name('aip_resource_uri')
    base.attribute :dip_resource_uri, Solr::Array, base.solr_name('dip_resource_uri')
    base.attribute :origin_pipeline, Solr::Array, base.solr_name('origin_pipeline')
    base.attribute :slug, Solr::String, 'slug_tesim'
    base.attribute :fedora_id, Solr::String, 'fedora_id_ssi'
    base.attribute :aark_id, Solr::String, 'aark_id_tesim'
    base.attribute :bibliographic_citation, Solr::String, 'bibliographic_citation_tesim'
    base.attribute :alt, Solr::String, 'alt_tesim'
    base.attribute :file_set_ids, Solr::Array, 'file_set_ids_ssim'
    base.attribute :video_embed, Solr::String, 'video_embed_tesim'

    base.field_semantics.merge!(
      contributor: 'contributor_tesim',
      creator: 'creator_tesim',
      date: 'date_created_tesim',
      description: 'description_tesim',
      identifier: 'aark_id_tesim',
      language: 'language_tesim',
      publisher: 'publisher_tesim',
      relation: 'nesting_collection__pathnames_ssim',
      related_url: 'related_url_tesim',
      rights: 'rights_statement_tesim',
      subject: 'subject_tesim',
      title: 'title_tesim',
      type: 'human_readable_type_tesim'
    )
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # @return [Array<SolrDocument>] a list of solr documents in no particular order
  def load_parent_docs
    # in case the id is a slug, we have to convert it to an id because memberships are stored as ids
    new_id = self["resource_id_ssi"] || self["fedora_id_ssi"] || id

    query("member_ids_ssim:#{new_id}", rows: 1000)
      .map { |res| ::SolrDocument.new(res) }
  end

  def to_param
    slug || id.to_s
  end

  def thumbnail_url
    Addressable::URI.parse("https://#{Site.account.cname}#{thumbnail_path}").to_s
  end

  def remote_url
    self['remote_url_tesim']
  end
end

SolrDocument.singleton_class.prepend(AdlSolrDocumentDecorator::ClassMethods)
SolrDocument.prepend(AdlSolrDocumentDecorator)
