require 'net-ldap'

module Devise
  module LDAP
    class SSLConnextionFactory
      def self.new_ssl_connection(io)
        raise Net::LDAP::LdapError, "OpenSSL is unavailable" unless Net::LDAP::HasOpenSSL
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.ssl_version = :TLSv1
        conn = OpenSSL::SSL::SSLSocket.new(io, ctx)
        conn.connect
        conn.sync_close = true

        conn.extend(Net::LDAP::Connection::GetbyteForSSLSocket) unless conn.respond_to?(:getbyte)

        conn
      end
    end
  end
end


class Net::LDAP::Connection
  def self.wrap_with_ssl(io)
    Devise::LDAP::SSLConnextionFactory.new_ssl_connection(io)
  end
end
