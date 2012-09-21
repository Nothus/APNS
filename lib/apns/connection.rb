module APNS
  class Connection
    attr_accessor :socket, :ssl

    def initialize(opts)
      self.socket = TCPSocket.new(opts[:host], opts[:port])

      configure_ssl opts[:pem], opts[:pass]
    end

    def close
      ssl.close
      socket.close
    end

  private

    def configure_ssl(pem, pass)
      #raise "The path to your pem file does not exist!" unless File.exist?(pem)

      context      = OpenSSL::SSL::SSLContext.new
      context.cert = OpenSSL::X509::Certificate.new(pem)
      context.key  = OpenSSL::PKey::RSA.new(pem, pass)
    
      self.ssl     = OpenSSL::SSL::SSLSocket.new(socket, context)
      ssl.connect
    end

  end

  class NotificationConnection < Connection
    APNS_DEFAULT_PUSH_HOST = 'gateway.sandbox.push.apple.com'
    APNS_DEFAULT_PUSH_PORT = 2195

    def initialize(opts)
      opts[:host] ||= APNS_DEFAULT_PUSH_HOST
      opts[:port] ||= APNS_DEFAULT_PUSH_PORT

      self.socket = TCPSocket.new(opts[:host], opts[:port])

      configure_ssl opts[:pem], opts[:pass]
    end

    def send_notifications(notifications)
      notifications.each do |n|
        ssl.write n.packaged_notification
      end
    end
  end

  class FeedbackConnection < Connection
    APNS_DEFAULT_FEEDBACK_HOST = 'feedback.sandbox.push.apple.com'
    APNS_DEFAULT_FEEDBACK_PORT = 2196

    def initialize(opts)
      opts[:host] ||= APNS_DEFAULT_FEEDBACK_HOST
      opts[:port] ||= APNS_DEFAULT_FEEDBACK_PORT

      self.socket = TCPSocket.new(opts[:host], opts[:port])

      configure_ssl opts[:pem], opts[:pass]
    end
    def feedback
      apns_feedback = []
      
      while line = socket.gets   # Read lines from the socket
        line.strip!
        f = line.unpack('N1n1H140')
        apns_feedback << [Time.at(f[0]), f[2]]
      end
     
      apns_feedback
    end
  end
end