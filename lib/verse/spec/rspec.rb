# frozen_string_literal: true

require_relative "./helpers/service_helper"

RSpec.configure do |c|
  c.include ServiceHelper, type: :service
end