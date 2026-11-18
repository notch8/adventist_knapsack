# frozen_string_literal: true

# OVERRIDE Hyrax 5.0-flexible to accept the admin_set_id: keyword Bulkrax 9.4+ passes to
# ResourceForm.for. Remove once Hyrax accepts it.
module Hyrax
  module Forms
    module ResourceFormDecorator
      def for(deprecated_resource = nil, resource: nil, admin_set_id: nil) # rubocop:disable Lint/UnusedMethodArgument
        super(deprecated_resource, resource:)
      end
    end
  end
end

Hyrax::Forms::ResourceForm.singleton_class.prepend(Hyrax::Forms::ResourceFormDecorator) unless Hyrax::Forms::ResourceForm.method(:for).parameters.any? { |_type, name| name == :admin_set_id }
