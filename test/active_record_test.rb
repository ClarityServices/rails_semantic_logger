require_relative 'test_helper'

class ActiveRecordTest < Minitest::Test
  describe 'ActiveRecord' do
    before do
      # Use a mock logger that just keeps the last logged entry in an instance variable
      SemanticLogger.default_level   = :trace
      SemanticLogger.backtrace_level = nil
      @mock_logger                   = MockLogger.new
      @appender                      = SemanticLogger.add_appender(logger: @mock_logger, formatter: :raw)
      @logger                        = SemanticLogger['Test']
      @hash                          = {session_id: 'HSSKLEU@JDK767', tracking_number: 12_345}

      if Rails.version.to_f >= 5.2
        ::ActiveRecord::Base.verbose_query_logs = true
      end

      assert_equal [], SemanticLogger.tags
      assert_equal 65_535, SemanticLogger.backtrace_level_index
    end

    after do
      SemanticLogger.remove_appender(@appender)
    end

    describe 'logs' do
      it 'sql' do
        Sample.first

        SemanticLogger.flush
        actual = @mock_logger.message
        assert actual[:message].include?('Sample'), actual[:message]
        assert actual[:payload], actual
        assert actual[:payload][:sql], actual[:payload]

        if Rails.version.to_f >= 5.2
          assert_match /active_record_test.rb:25/, actual[:payload][:query_source]
        end
      end

      it 'single bind value' do
        Sample.where(name: 'Jack').first

        SemanticLogger.flush
        actual = @mock_logger.message
        assert payload = actual[:payload], -> { actual.ai }

        assert payload[:sql], -> { actual.ai }

        assert binds = payload[:binds], -> { actual.ai }
        assert_equal 'Jack', binds[:name], -> { actual.ai }
        assert_equal 1, binds[:limit], -> { actual.ai } if Rails.version.to_f >= 5.0
      end

      it 'multiple bind values' do
        Sample.where(age: 2..21).first

        SemanticLogger.flush
        actual = @mock_logger.message
        assert payload = actual[:payload], -> { actual.ai }

        assert payload[:sql], -> { actual.ai }

        if Rails.version.to_f >= 5.0
          assert binds = payload[:binds], -> { actual.ai }
          assert_equal [2, 21], binds[:age], -> { actual.ai }
          assert_equal 1, binds[:limit], -> { actual.ai }
        end
      end
    end
  end
end
