require 'socket'

EurekaRuby.configure do |config|
  def get_local_ip
    # Get IP from network interface
    ip = Socket.ip_address_list.detect do |addr|
      addr.ip? &&
        !addr.ipv4_loopback? &&
        !addr.ipv6_loopback? &&
        !addr.ipv6_linklocal? &&
        addr.ip_address.match?(/^(\d{1,3}\.){3}\d{1,3}$/) # Chỉ lấy IPv4
    end

    ip ? ip.ip_address : '127.0.0.1'
  rescue
    '127.0.0.1'
  end

  # Get IP from command
  def get_ip_from_command
    `hostname -I`.strip.split.first || '127.0.0.1'
  rescue
    '127.0.0.1'
  end


  local_ip = get_local_ip

  # --- Lấy port tự động ---
  server_port = ENV.fetch('PORT', 3000).to_i
  if defined?(Rails::Server) && Rails::Server.respond_to?(:options)
    options = Rails::Server.options
    server_port = options[:Port] || server_port
  end

  # Lấy tên host
  host_name = ENV.fetch('HOSTNAME', local_ip)

  # --- Cấu hình Eureka ---
  config.eureka_url      = ENV['EUREKA_URL'] || 'http://localhost:8761/eureka/'
  config.app_id          = ENV['EUREKA_APP_ID'] || Rails.application.class.module_parent_name.underscore.upcase
  config.host_name       = ENV['EUREKA_HOST_NAME'] || host_name
  config.ip_addr         = ENV['EUREKA_IP_ADDR'] || local_ip
  config.port            = ENV.fetch('EUREKA_PORT', server_port).to_i
  config.scheme          = ENV.fetch('EUREKA_SCHEME', 'http')


  # Metadata bổ sung
  config.info_response   = {
    "framework" => "Postal API",
    "language" => "Ruby",
    "ruby_version" => RUBY_VERSION,
    "rails_version" => Rails::VERSION::STRING,
    "environment" => Rails.env,
    "pid" => Process.pid
  }

  # Health check endpoint
  config.health_path     = ENV.fetch('EUREKA_HEALTH_PATH', '/health')
  config.health_response = 'OK'
  #Create instance ID
  config.info_response= {
    "instance_id" => "#{host_name}:#{server_port}:#{SecureRandom.hex(4)}"
  }

  puts "=== Eureka Client Configuration ==="
  puts "App ID: #{config.app_id}"
  puts "Host: #{config.host_name}"
  puts "IP: #{config.ip_addr}"
  puts "Port: #{config.port}"
  puts "Eureka URL: #{config.eureka_url}"
  puts "==================================="
end
eureka_enabled  = ENV['EUREKA_ENABLED'] || false
# Khởi động Eureka client khi Rails server chạy
if defined?(Rails::Server) && (Rails.env.production? || Rails.env.development? || Rails.env.test?) && eureka_enabled
  # Đăng ký instance với Eureka
  begin
    EurekaRuby.executor.run(:register)
    puts "✅ Đã đăng ký thành công với Eureka Server!"
  rescue => e
    puts "❌ Lỗi đăng ký Eureka: #{e.message}"
  end

  # Thread gửi heartbeat
  Thread.new do
    loop do
      begin
        EurekaRuby.executor.run(:send_heartbeat)
        Rails.logger.debug "❤️ Đã gửi heartbeat tới Eureka"
      rescue => e
        Rails.logger.error "Lỗi gửi heartbeat: #{e.message}"
      end
      sleep ENV.fetch('EUREKA_HEARTBEAT_INTERVAL', 30).to_i
    end
  end
end