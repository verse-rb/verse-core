module Verse
  module_function

  # Initialize the microservice within the current path
  protected def init(
    root_path:,
    logger:,
    config_path:
  )
    # Generate unique ID for the lifetime of the service.
    @service_id   = SecureRandom.alphanumeric(12)
    @environment  = ENV.fetch("APP_ENVIRONMENT", "development").to_sym
    @root_path    = root_path
    @logger       = logger

    Verse::Config.init(config_path)
    Verse::I18n.init

    Verse::Plugin.load_configuration(Verse::Config.config)
    Verse::Plugin.init
  end

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

    Verse::I18n.load_i18n

    Verse::Plugin.start(mode)
  end
end
