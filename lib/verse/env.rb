# frozen_string_literal: true

module Verse
  extend self

  def logger
    @logger
  end

  def inflector
    @inflector ||= Verse::Util::Inflector.new
  end

  def environment
    @environment
  end
end
