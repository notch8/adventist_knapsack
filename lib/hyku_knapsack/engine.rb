# frozen_string_literal: true

module HykuKnapsack
  class Engine < ::Rails::Engine
    isolate_namespace HykuKnapsack

    def self.load_translations!
      HykuKnapsack::Engine.root.glob("config/locales/**/*.yml").each do |path|
        I18n.load_path << path.to_s
      end

      # Let's have unique load_paths.  Later entries in the I18n.load_path array take precendence
      # over earlier entries (e.g. lower array index means lower precedence).  So we need to reverse
      # the array, then call uniq (which will drop duplicates that show up later in the array).
      # Then reverse again.  (You know, kind of like an Uno reverse battle.)
      # I18n.load_path = I18n.load_path.reverse.uniq.reverse
      I18n.backend.reload!
    end

    initializer :append_migrations do |app|
      # only add the migrations if they are not already copied
      # via the rake task. Allows gem to work both with the install:migrations
      # and without it.
      if app.root.to_s != HykuKnapsack::Engine.root.to_s &&
         app.root.join('db/migrate').children.none? { |path| path.fnmatch?("*.hyku_knapsack.rb") }
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    config.before_initialize do
      config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]

      if Hyku::Application.respond_to?(:user_devise_parameters=)
        Hyku::Application.user_devise_parameters = %i[
          database_authenticatable
          invitable
          recoverable
          rememberable
          trackable
          validatable
          omniauthable
        ]
      end
    end

    # rubocop:disable Metrics/BlockLength
    config.after_initialize do
      # need collection model first
      collection_decorator = HykuKnapsack::Engine.root.join("app", "models", "collection_decorator.rb").to_s
      Rails.configuration.cache_classes ? require(collection_decorator) : load(collection_decorator)

      # By default plain text files are not processed for text extraction.  In adding
      # Adventist::TextFileTextExtractionService to the beginning of the services array we are
      # enabling text extraction from plain text files.
      #
      # https://github.com/notch8/adventist-dl/blob/97bd05946345926b2b6c706bd90e183a9d78e8ef/config/application.rb#L68-L73
      Hyrax::DerivativeService.services = [
        Adventist::TextFileTextExtractionService,
        IiifPrint::DerivativeRodeoService,
        Hyrax::FileSetDerivativesService
      ]

      # This is the opposite of what you usually want to do.  Normally app views override engine
      # views but in our case things in the Knapsack override what is in the application.
      # Furthermore we need to account for when the ApplicationController and it's descendants set
      # their individual view_paths.  By looping through all descendants, we ensure that we have
      # the Knapsack views at the beginning of the list of view_paths.
      #
      # In the load sequence, when we load ApplicationController, we establish the view_path for all
      # future descendants.  When we then encounter a descendant, we copy the
      # ApplicationController's view_path to the descendant; then later after we've encountered most
      # all of the descendants we updated the ApplicationController's view_path, but that does not
      # propogate to the descendants' copied view_path.
      ([::ApplicationController] + ::ApplicationController.descendants).each do |klass|
        paths = klass.view_paths.collect(&:to_s)
        paths = [HykuKnapsack::Engine.root.join('app', 'views').to_s] + paths
        klass.view_paths = paths.uniq
      end
      ::ApplicationController.send :helper, HykuKnapsack::Engine.helpers

      ##
      # Ensure that all knapsack locales are the "first choice" of keys.  We've already done this in
      # the catalog controller to appease the Blacklight constraint of having translations loaded.
      # However, between loading those translations in the catalog controller and now, the
      # underlying application and even other engines might have further amended the load path.
      # This is our "best" chance to do it at the latest possible moment.
      config.after_initialize do
        HykuKnapsack::Engine.load_translations!
      end

      DerivativeRodeo::Generators::HocrGenerator.additional_tessearct_options = "-l eng_best"
      # See: https://github.com/notch8/adventist-dl/issues/676
      IiifPrint::DerivativeRodeoService.named_derivatives_and_generators_filter =
        lambda do |_file_set:, filename:, named_derivatives_and_generators:|
          named_derivatives_and_generators.reject do |named_derivative, _generators|
            named_derivative != :thumbnail && filename.downcase.ends_with?(HykuKnapsack::Engine::THUMBNAIL_FILE_SUFFIX)
          end
        end

      config.active_record.yaml_column_permitted_classes = [
        OpenStruct, Symbol, Time, URI, BigDecimal, Date, DateTime,
        ActiveSupport::TimeWithZone, ActiveSupport::Duration,
        ActiveSupport::TimeZone, ActiveSupport::HashWithIndifferentAccess,
        ActiveSupport::OrderedHash
      ]
      THUMBNAIL_FILE_SUFFIX = '.tn.jpg'

      if Rails.env.development?
        ##
        # In the development environment we may not have AWS credentials.  When we do, let's use s3.  When
        # we don't, we'll use local files (which almost certainly will fail).  This means we'd be locally
        # using the derivative rodeo's splitting process (which should work without a preprocess lcoation).
        # rubocop:disable Layout/LineLength
        IiifPrint::DerivativeRodeoService.preprocessed_location_adapter_name = if DerivativeRodeo.config.aws_s3_access_key_id.present? && DerivativeRodeo.config.aws_s3_secret_access_key.present?
                                                                                 's3'
                                                                               else
                                                                                 'file'
                                                                               end
        # rubocop:enable Layout/LineLength
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
