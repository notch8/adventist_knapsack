# frozen_string_literal: true

# Ensure Knapsack version gets loaded after Hyku's bulkrax.rb
Rails.application.config.after_initialize do
  Bulkrax.setup do |config|
    # WorkType to use as the default if none is specified in the import
    # Default is the first returned by Hyrax.config.curation_concerns
    # config.default_work_type = MyWork
    config.default_work_type = 'GenericWork'

    # Setting the available parsers for Adventist.
    config.parsers = [
      { name: "OAI - Adventist Digital Library", class_name: "Bulkrax::OaiAdventistQdcParser", partial: "oai_adventist_fields" },
      { name: "CSV - Comma Separated Values", class_name: "Bulkrax::CsvParser", partial: "csv_fields" },
    ]

    # Field to use during import to identify if the Work or Collection already exists.
    # Default is 'source'.
    # config.system_identifier_field = 'source'

    # Path to store pending imports
    # config.import_path = 'tmp/imports'

    # Path to store exports before download
    # config.export_path = 'tmp/exports'

    # Server name for oai request header
    # config.server_name = 'my_server@name.com'
    # Uncomment to create works pre-valkyrie works for testing
    # config.object_factory = Bulkrax::ObjectFactory
    # config.factory_class_name_coercer = Bulkrax::FactoryClassFinder::DefaultCoercer

    # Lambda to set the default field mapping
    config.default_field_mapping = lambda do |field|
      return if field.blank?
      {
        field.to_s =>
          {
            from: [field.to_s],
            split: false,
            parsed: Bulkrax::ApplicationMatcher.method_defined?("parse_#{field}"),
            if: nil,
            excluded: false,
            default_thumbnail: false
          }
      }
    end
  end
end
