# Patch the Rails::Server log_to_stdout so that it logs via SemanticLogger
Rails::Server
module Rails
  class Server
    private

    def log_to_stdout
      wrapped_app # touch the app so the logger is set up

      SemanticLogger.add_appender(io: $stdout, formatter: :color)
    end
  end
end
