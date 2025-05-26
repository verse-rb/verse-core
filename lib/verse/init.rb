# frozen_string_literal: true

require "logger"
require "securerandom"

require_relative "./util/registry"
require_relative "./util/errors" # Ensure errors are loaded for registry/accessors
require_relative "./util/impl/memory/distributed_hash" # Renamed
require_relative "./util/impl/memory/distributed_lock"
require_relative "./util/impl/memory/distributed_counter"
require_relative "./util/inflector"

# Register default in-memory adapters
Verse::Util::Registry.register(:distributed_hash, :memory, Verse::Util::Impl::Memory::DistributedHash) # Renamed
Verse::Util::Registry.register(:distributed_lock, :memory, Verse::Util::Impl::Memory::DistributedLock)
Verse::Util::Registry.register(:distributed_counter, :memory, Verse::Util::Impl::Memory::DistributedCounter)
Verse::Util::Registry.register(:inflector, :default, Verse::Util::Inflector)

module Verse
  extend self

  def service_id
    @service_id
  end

  def root_path
    @root_path
  end

  def stop
    @on_stop_callbacks&.each(&:call)
    @on_stop_callbacks&.clear

    Verse.event_manager&.stop
    Verse::Plugin.stop
    Verse::Plugin.finalize

    @started = false
  end

  def start(
    mode = :server,
    root_path: ".",
    logger: Logger.new($stdout),
    config_path: "./config"
  )
    init(
      root_path:,
      logger:,
      config_path:
    )
    logger.info{ "init sequence... `#{mode}` mode" }

    initialize_event_manager!

    @started = true

    logger.info{ "running post-init callbacks" }
    @on_boot_callbacks&.each(&:call)
    @on_boot_callbacks&.clear

    Verse::I18n.load_i18n

    logger.info{ "notifying plugins start" }
    Verse::Plugin.start(mode)
    logger.info{ "starting event manager" }
    @event_manager&.start unless mode == :task

    logger.info{ "Verse startup sequence completed" }
  end

  def initialize_event_manager!
    em = Config.config.fetch(:em, nil)

    return unless em

    adapter = em.fetch(:adapter)

    @event_manager = Verse::Event::Manager[adapter].new(
      service_name:, service_id:, config: em.fetch(:config, {}), logger:
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
  def distributed_hash = Verse::Util::Registry.resolve(:distributed_hash) # Renamed
  # Accessor for DistributedLock utility
  def distributed_lock = Verse::Util::Registry.resolve(:distributed_lock)
  # Accessor for DistributedCounter utility
  def distributed_counter = Verse::Util::Registry.resolve(:distributed_counter)
  # Accessor for Inflector utility
  def inflector = Verse::Util::Registry.resolve(:inflector)

  protected

  def initialize_utilities!
    # Config values will have defaults from schema if the :utilities key exists.
    # If :utilities is entirely missing, `dig` returns nil, so we default to memory.
    base_utils_config = Verse::Config.config.dig(:utilities) || {}

    dh_conf = base_utils_config[:distributed_hash] || { adapter: :memory, config: {} } # Renamed ds_conf to dh_conf and key
    Verse::Util::Registry.set_default_adapter(:distributed_hash, dh_conf[:adapter]) # Renamed
    Verse::Util::Registry.adapter_config(:distributed_hash, dh_conf[:adapter], dh_conf[:config] || {}) # Renamed

    dl_conf = base_utils_config[:distributed_lock] || { adapter: :memory, config: {} }
    Verse::Util::Registry.set_default_adapter(:distributed_lock, dl_conf[:adapter])
    Verse::Util::Registry.adapter_config(:distributed_lock, dl_conf[:adapter], dl_conf[:config] || {})

    dc_conf = base_utils_config[:distributed_counter] || { adapter: :memory, config: {} }
    Verse::Util::Registry.set_default_adapter(:distributed_counter, dc_conf[:adapter])
    Verse::Util::Registry.adapter_config(:distributed_counter, dc_conf[:adapter], dc_conf[:config] || {})

    inflector_conf = base_utils_config[:inflector] || { adapter: :default, config: {} }
    Verse::Util::Registry.set_default_adapter(:inflector, inflector_conf[:adapter])
    Verse::Util::Registry.adapter_config(:inflector, inflector_conf[:adapter], inflector_conf[:config] || {})
  end

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

    Verse::I18n.init

    Verse::Plugin.load_configuration(Verse::Config.config)
    Verse::Plugin.init

    initialize_utilities!
  end
end
