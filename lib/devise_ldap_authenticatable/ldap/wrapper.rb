module Devise
  module LDAP
    class Wrapper
      attr_accessor :options, :config
      private :options=, :options, :config=, :config

      def initialize options, config
        self.options = options
        self.config = config
      end

      def failover?
        config.key? 'servers'
      end

      def current_server
        0
      end

      def connect_port
        return config['port'] unless failover?
        current_server['port']
      end

      def connect_host
        return config['host'] unless failover?
        current_server['host']
      end

      def current_server
        return config unless failover?
        servers[current_server_index]
      end

      def servers
        raise "Failover is not configured" unless failover?
        config['servers']
      end

      def current_server_index
        @current_server_index ||= 0
      end

      def connect_to_ldap
        ldap = Net::LDAP.new options
        ldap.host = connect_host
        ldap.port = connect_port
        ldap.base = config["base"]

        ldap.auth config["admin_user"], config["admin_password"] if options[:admin]
        ldap
      end

      def select_next_server
        @current_server_index = (@current_server_index + 1) % servers.size
      end

      def failover
        disconnect
        select_next_server
      end

      def ldap_connection
        @ldap_connection ||= connect_to_ldap
      end

      def disconnect
        begin
          ldap_connection.close
        rescue
        end
        @ldap_connection = nil
      end

      def each_server
        i = current_server
        loop do
          begin
            ::DeviseLdapAuthenticatable::Logger.send "CURRENT SERVER = #{current_server.inspect}"
            return yield ldap_connection
          rescue StandardError => error
            failover
            if current_server == i
              ::DeviseLdapAuthenticatable::Logger.send "I have exhaused all servers, raising exception"
              raise error, "#{error.message}. Tried all servers"
            end
            ::DeviseLdapAuthenticatable::Logger.send "FAILING OVER to #{current_server.inspect}"
          end
        end
      end

      def method_missing name, *args, &block
        each_server do |s|
          ::DeviseLdapAuthenticatable::Logger.send "TRYING SERVER #{s.inspect}"
          s.send name, *args, &block
        end
      end
    end
  end
end
