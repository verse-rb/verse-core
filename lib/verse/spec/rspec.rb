# frozen_string_literal: true

require_relative "./helpers/service_helper"

RSpec.configure do |c|
  c.include Verse::Spec::ServiceHelper, type: :service
  c.include Verse::Spec::ContextHelper
end
