module Devise
  module LDAP
    class Wrapper
      attr_accessor :options, :config
      private :options=, :options, :config=, :config

      def initialize options, config
        self.options = options
        self.config = config
      end

      def connect_to_ldap
        ldap = Net::LDAP.new(options)
	ldap.host = config["host"]
	ldap.port = config["port"]
	ldap.base = config["base"]

	ldap.auth config["admin_user"], config["admin_password"] if options[:admin]
	ldap
      end

      def ldap_connection
        @ldap_connection ||= connect_to_ldap
      end

      def method_missing name, *args, &block
        ldap_connection.send name, *args, &block
      end
    end
  end
end
