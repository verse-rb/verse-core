# frozen_string_literal: true

require "logger"
require "securerandom"

require_relative "./util/error" # Ensure errors are loaded for registry/accessors
require_relative "./util/inflector"

require_relative "./distributed/errors"
require_relative "./distributed/counter"
require_relative "./distributed/kv_store"
require_relative "./distributed/lock"

require_relative "./distributed/impl/local_lock"
require_relative "./distributed/impl/memory_counter"
require_relative "./distributed/impl/memory_kv_store"

module Verse
  extend self

  attr_reader :service_id, :root_path, :mode

  def stop
    return unless @started

    @on_stop_callbacks&.each(&:call)
    @on_stop_callbacks&.clear

    Verse.event_manager&.stop
    Verse::Plugin.stop
    Verse::Plugin.finalize

    # Allow to switch via config.
    @kvstore = nil
    @lock = nil
    @counter = nil

    @started = false
  end

  def started?
    !!@started
  end

  def start(
    mode = :server,
    root_path: ".",
    logger: Logger.new($stdout),
    config_path: "./config"
  )
    @started = true
    @mode = mode

    init(
      root_path:,
      logger:,
      config_path:
    )
    logger.info{ "init sequence... `#{mode}` mode" }

    initialize_event_manager!

    logger.info{ "running post-init callbacks" }
    @on_boot_callbacks&.each(&:call)
    @on_boot_callbacks&.clear

    logger.info{ "notifying plugins start" }
    Verse::Plugin.start(mode)
    logger.info{ "starting event manager" }
    @event_manager&.start unless mode == :task

    logger.info{ "Verse startup sequence completed" }
  end

  def initialize_event_manager!
    em = Config.config.em

    return unless em

    adapter = em.adapter

    @event_manager = Verse::Event::Manager[adapter].new(
      service_name:, service_id:, config: em.config || {}, logger:
    )
  end


  def on_boot(&block)
    if @started
      block.call
    else
      (@on_boot_callbacks ||= []) << block
    end
  end

  def on_stop(&block)
    if !@started
      block.call
    else
      (@on_stop_callbacks ||= []) << block
    end
  end

  # Accessor for DistributedHash utility
  def kvstore
    @kvstore ||= begin
      kvstore = Verse.config.kv_store
      Util::Reflection.constantize(kvstore.adapter).new(kvstore.config)
    end
  end

  # Accessor for DistributedLock utility
  def lock
    @lock ||= begin
      lock = Verse.config.lock
      Util::Reflection.constantize(lock.adapter).new(lock.config)
    end
  end

  # Accessor for DistributedCounter utility
  def counter
    @counter ||= begin
      counter = Verse.config.counter
      Util::Reflection.constantize(counter.adapter).new(counter.config)
    end
  end

  def config = Verse::Config.config

  def inflector
    # Inflector is not defined in config because it doesn't require
    # configuration which change between environments.
    @inflector ||= Verse::Util::Inflector.new
  end

  attr_writer :counter, :kvstore, :lock, :inflector

  protected

  # Initialize the microservice within the current path
  def init(
    root_path:,
    logger:,
    config_path:
  )
    # Generate unique ID for the lifetime of the service.
    @service_id = SecureRandom.alphanumeric(12)
    @environment  = ENV.fetch("APP_ENVIRONMENT", "development").to_sym
    @root_path    = root_path
    @logger       = logger

    Verse::Config.init(config_path)

    Config.config.dig(:logging, :level)&.tap do |level|
      @logger.level = level.to_sym
    end

    Verse::Plugin.load_configuration(Verse::Config.config)
    Verse::Plugin.init
  end
end
