# frozen_string_literal: true

CatalogController.include DogBiscuits::Blacklight::Commands
CatalogController.include Hyku::HomePageThemesBehavior

CatalogController.configure_blacklight do |config|
  # Use locally customized AdvSearchBuilder so we can enable blacklight_advanced_search
  config.search_builder_class = AdvSearchBuilder

  # Delete Hyku's default settings
  config.facet_fields.clear

  # solr fields that will be treated as facets by the blacklight application
  #   The ordering of the field names is the order of the display
  config.add_facet_field 'source_sim', label: 'Source', limit: 5, collapse: false, helper_method: :iconify_auto_link
  config.add_facet_field 'human_readable_type_sim', label: "Type", limit: 5, collapse: false
  config.add_facet_field(
    'sorted_year_isi',
    label: 'Date Range',
    range: {
      facet_field_label: 'Date Range',
      num_segments: 10,
      assumed_boundaries: [1100, Time.zone.now.year + 2],
      segments: false,
      slider_js: false,
      maxlength: 4
    },
    facet_field_label: 'Date Range'
  )
  config.add_facet_field 'resource_type_sim', label: "Resource Type", limit: 5
  config.add_facet_field 'creator_sim', label: "Author", limit: 5
  config.add_facet_field 'publisher_sim', limit: 5
  config.add_facet_field 'keyword_sim', limit: 5
  config.add_facet_field 'subject_sim', limit: 5
  config.add_facet_field 'language_sim', limit: 5
  config.add_facet_field 'based_near_label_sim', limit: 5
  config.add_facet_field 'part_sim', limit: 5, label: 'Part'
  config.add_facet_field 'part_of_sim', limit: 5
  # config.add_facet_field 'file_format_sim', limit: 5
  # config.add_facet_field 'contributor_sim', label: "Contributor", limit: 5
  config.add_facet_field 'member_of_collections_ssim', limit: 5, label: 'Collections'
  config.add_facet_field 'refereed_sim', limit: 5

  # Clobber all existing index and show fields that come from Hyku base but skip
  # the non-DogBiscuit keys that Adventist had already configured in a pre-Knapsack state
  # see: https://github.com/notch8/adventist-dl/blob/97bd05946345926b2b6c706bd90e183a9d78e8ef/app/controllers/catalog_controller.rb#L38-L40
  config.index_fields.keys.each do |key|
    next if key == 'all_text_timv'
    next if key == 'all_text_tsimv'
    next if key == 'file_set_text_tsimv'

    config.index_fields.delete(key)
  end

  ##
  # When we specify the index fields, blacklight caches those translations.  However, in the case of
  # dogbiscuits, those are not yet loaded.  Which results in a translation error; even though we
  # later load the dog biscuits translations.
  HykuKnapsack::Engine.load_translations!

  # @todo remove this and list index properties individually
  index_props = DogBiscuits.config.index_properties.collect do |prop|
    { prop => CatalogController.send(:index_options, prop, DogBiscuits.config.property_mappings[prop]) }
  end
  CatalogController.send(:add_index_field, config, index_props)
  config.add_index_field 'based_near_label_tesim', itemprop: 'contentLocation', link_to_facet: 'based_near_label_sim'

  config.search_fields.delete('all_fields')
  config.add_search_field('all_fields',
                          label: 'All Fields',
                          include_in_advanced_search: false,
                          advanced_parse: false) do |field|
    title_name = 'title_tesim'
    all_show_names = (config.show_fields.values.map { |v| v.field.to_s } +
                 DogBiscuits.config.all_properties.map { |p| "#{p}_tesim" }).uniq
    all_show_names |= [title_name]
    field.solr_parameters = {
      qf: "#{all_show_names.join(' ')} file_format_tesim all_text_timv all_text_tsimv",
      pf: title_name.to_s
    }
  end

  # TODO: We may remove this block if Hyku changes the creator label to Author
  config.search_fields.delete('creator')
  config.add_search_field('creator') do |field|
    field.label = "Author"
    solr_name = 'creator_tesim'
    field.solr_local_parameters = {
      qf: solr_name,
      pf: solr_name
    }
  end

  # TODO: We may remove this block if Hyku changes the date_created search field solr_name
  config.search_fields.delete('date_created')
  config.add_search_field('date_created') do |field|
    solr_name = ['date_created_tesim', 'sorted_date_isi', 'sorted_month_isi'].join(' ')
    field.solr_local_parameters = {
      qf: solr_name,
      pf: solr_name
    }
  end

  # Remove spellcheck dictonaries.  This was creating search query errors when attempting to search
  # within collections.
  # TODO: Consider moving this to Hyku.
  config.search_fields.each do |_key, field_config|
    field_config&.solr_parameters&.delete("spellcheck.dictionary".to_sym)
  end

  # Remove all existing sort fields and add the ones we want
  config.sort_fields.keys.each do |key|
    config.sort_fields.delete(key)
  end

  def self.uploaded_field
    ActiveFedora.index_field_mapper.solr_name('system_create', :stored_sortable, type: :date)
  end

  config.add_sort_field "score desc, #{uploaded_field} desc", label: "Relevance"
  # TODO: replace CatalogController.title_field to return 'title_ssi'
  config.add_sort_field "title_ssi asc", label: "Title"
  # TODO: replace CatalogController.creator_field to return 'creator_ssi'
  config.add_sort_field "creator_ssi asc", label: "Author"
  # TODO: replace CatalogController.created_field to return 'created_ssi'
  config.add_sort_field "#{CatalogController.created_field} asc", label: "Published Date (Ascending)"
  config.add_sort_field "#{CatalogController.created_field} desc", label: "Published Date (Descending)"
  config.add_sort_field "#{CatalogController.modified_field} asc", label: "Upload Date (Ascending)"
  config.add_sort_field "#{CatalogController.modified_field} desc", label: "Upload Date (Descending)"
end
