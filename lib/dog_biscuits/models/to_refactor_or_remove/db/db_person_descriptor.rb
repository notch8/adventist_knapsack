# frozen_string_literal: true

class DbPersonDescriptor < ActiveRecord::Base
  belongs_to :db_related_agent
end
