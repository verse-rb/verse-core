# frozen_string_literal: true

module Verse
  extend self

  def service_id
    @service_id
  end

  def root_path
    @root_path
  end

  def stop
    Verse::Plugin.stop
    Verse::Plugin.finalize
  end

  def start(
    mode = :server,
    root_path: ".",
    logger: Logger.new($stdout),
    config_path: "./config"
  )
    init(
      root_path: root_path,
      logger: logger,
      config_path: config_path
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
    logger.info{ "verse startup sequence completed" }
  end

  def initialize_event_manager!
    em = Config.config.fetch(:em, nil)

    return unless em

    adapter = em.fetch(:adapter)

    @event_manager = Verse::Event::Manager[adapter].new(
      service_name, em.fetch(:config, {}), logger
    )
  end

  def on_boot(&block)
    if @started
      block.call
    else
      (@on_boot_callbacks ||= []) << block
    end
  end

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

    Verse::I18n.init

    Verse::Plugin.load_configuration(Verse::Config.config)
    Verse::Plugin.init
  end
end
