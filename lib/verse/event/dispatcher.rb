# frozen_string_literal: true

module Verse
  module Event
    module Dispatcher
      extend self

      @event_mode = :on_commit

      attr_reader :event_mode

      # Change temporarly the dispatch event mode to manual, then come back to the
      # previous version.
      # During the time of the block, the  events are not going to be
      # processed.
      #
      # On block completion, execute the event callbacks.
      # This is useful in test mode, as transactional events
      # are run in :immediate mode, which can cause issues
      # such as the event being processed before the transaction is committed.
      #
      # If the block raise error, the events are not going to be processed.
      def execute_later(&)
        old_mode = event_mode
        self.event_mode = :manual

        output = yield

        dispatch! if event_mode

        output
      ensure
        self.event_mode = old_mode
      end

      # :nodoc:
      def register_event(&block)
        @events ||= []
        @events << block
      end

      # In case of `:manual` dispatch, this method will dispatch the events.
      def dispatch!
        if @event_mode != :manual
          raise ArgumentError, "event_mode must be set to :manual"
        end

        @events&.each(&:call)
      ensure
        @events&.clear
      end

      # Set the dispatch event strategy for all repositories.
      #
      # @param mode [Symbol] the mode to use.
      #   Modes:
      #   - :immediate: Dispatches the event immediately when the action is triggered.
      #     This is useful in test mode or if you don't use an ACID database/transaction system.
      #     Note: This might cause issues in transactions, as the event could be processed before
      #     the transaction is committed or the transaction could roll back.
      #
      #   - :on_commit: Dispatches the event after the transaction is committed.
      #     This is the default and safest mode, ensuring data integrity in event callback code.
      #     Note: This can cause issues with RSpec or other test units, as the event might not
      #     be dispatched at all if you're using transaction blocks and rollbacks in your tests.
      #
      #   - :manual: Dispatches the event manually using `dispatch!`. This is useful when you want to dispatch
      #     the event at a specific time, such as in test setups to simulate a transaction commit.
      #
      # @raise [ArgumentError] if the mode is not one of :immediate, :on_commit, :manual.
      def event_mode=(mode)
        if !%i[immediate on_commit manual].include?(mode)
          raise ArgumentError, "Invalid event_mode: #{mode}"
        end

        @event_mode = mode
      end
    end
  end
end
