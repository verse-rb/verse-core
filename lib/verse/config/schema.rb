# frozen_string_literal: true

require_relative "../validation/contract"

module Verse
  module Config
    class Schema < Verse::Validation::Contract
      SERVICE_NAME = /[a-z0-9_-]+/.freeze
      PLUGIN_NAME = /[a-z0-9_]+( \<[a-zA-Z0-9\:]+\>)?/.freeze

      params do
        required(:service_name).filled(:string)

        optional(:description).filled(:string)
        optional(:version).filled(:string)

        optional(:plugins).array do
          hash do
            required(:name).filled(:string)
            optional(:config).filled(:hash)
            optional(:dep).filled(:hash)
          end
        end
      end

      rule(:service_name) do
        key.failure(:bad_format) unless value =~ SERVICE_NAME
      end

      rule(:plugins).each do |index:|
        unless value[:name] =~ PLUGIN_NAME
          key([:plugin, :name, index]).failure(:bad_format)
        end
      end

    end
  end
end
