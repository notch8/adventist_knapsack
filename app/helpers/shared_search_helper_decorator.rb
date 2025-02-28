# frozen_string_literal: true

# Override Hyku 6.0.x to remove the persistent search & highlighting
# until we can ensure consistent behavior
module SharedSearchHelperDecorator
  def append_query_params(url, _model, _params)
    url
  end
end

SharedSearchHelper.prepend(SharedSearchHelperDecorator)
