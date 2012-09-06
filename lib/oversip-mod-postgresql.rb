require "oversip-mod-postgresql/version.rb"

require "em-synchrony/pg"  # NOTE: Included in em-pg-client/lib/.


module OverSIP
  module Modules

    module Postgresql

      extend ::OverSIP::Logger

      DEFAULT_POOL_SIZE = 10

      @log_id = "Postgresql module"
      @pools = {}

      def self.add_pool options, db_data
        raise ::ArgumentError, "`options' must be a Hash"  unless options.is_a? ::Hash
        raise ::ArgumentError, "`db_data' must be a Hash"  unless db_data.is_a? ::Hash

        name, pool_size = options.values_at(:name, :pool_size)
        pool_size ||= DEFAULT_POOL_SIZE

        raise ::ArgumentError, "`options[:name]' must be a Symbol"  unless name.is_a? ::Symbol
        raise ::ArgumentError, "`options[:pool_size]' must be a positive Fixnum"  unless pool_size.is_a? ::Fixnum and pool_size > 0

        # Forcing DB autoreconnect.
        # TODO: It does not work!
        db_data[:async_autoreconnect] = true

        block = Proc.new  if block_given?

        OverSIP::SystemCallbacks.on_started do
          log_info "Adding PostgreSQL connection pool (name: #{name.inspect}, size: #{pool_size})..."
          @pools[name] = ::EM::Synchrony::ConnectionPool.new(size: pool_size) do
            conn = ::PG::EM::Client.new(db_data)
            block.call(conn)  if block
            conn
          end
        end
      end

      def self.pool name
        pool = @pools[name]
        raise ::ArgumentError, "no pool with `name' #{name.inspect}"  unless pool
        pool
      end

    end  # module Postgresql

  end
end