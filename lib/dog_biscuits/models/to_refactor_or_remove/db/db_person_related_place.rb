# frozen_string_literal: true

class DbPersonRelatedPlace < ActiveRecord::Base
  belongs_to :db_related_agent
end
