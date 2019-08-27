# frozen_string_literal: true

require_relative "./postgresql"

module Addons
  class Factory
    ADDONS_MAPPING = {
      "postgresql" => Addons::Postresql
    }.freeze

    def self.get(addon_name)
      ADDONS_MAPPING.fetch(addon_name).new
    end
  end
end
