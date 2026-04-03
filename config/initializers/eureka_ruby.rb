require 'socket'
require 'net/http'
require 'uri'
require 'erb'
require 'securerandom'
require "postal/config"

# Hash lưu thông tin để dùng cho at_exit
@eureka_instance_info = {
  app_id: nil,
  instance_id: nil,
  eureka_url: nil
}

EurekaRuby.configure do |config|
  def get_local_ip
    ip = Socket.ip_address_list.detect do |addr|
      addr.ip? && !addr.ipv4_loopback? && !addr.ipv6_loopback? &&
        !addr.ipv6_linklocal? && addr.ip_address.match?(/^(\d{1,3}\.){3}\d{1,3}$/)
    end
    ip ? ip.ip_address : '127.0.0.1'
  rescue
    '127.0.0.1'
  end

  local_ip = get_local_ip
  server_port = Postal::Config.web_server.default_port.to_i
  base_hostname = ENV.fetch('HOSTNAME', Socket.gethostname)

  # Tạo một hậu tố ngẫu nhiên để phân biệt các instance
  unique_suffix = SecureRandom.hex(2)
  custom_host_name = "#{base_hostname}-#{unique_suffix}"

  # --- Cấu hình Eureka ---
  config.eureka_url = Postal::Config.eureka.url || 'http://localhost:8760/eureka/'
  config.app_id    = (Postal::Config.eureka.app_name || Rails.application.class.module_parent_name).underscore.upcase

  config.host_name = custom_host_name
  config.ip_addr   = local_ip
  config.port      = server_port

  # Công thức mà Gem eureka-ruby sử dụng nội bộ để tạo ID: "#{host_name}:#{ip_addr}:#{port}"
  actual_id_on_eureka = "#{custom_host_name}:#{local_ip}:#{config.port}"

  @eureka_instance_info[:app_id] = config.app_id
  @eureka_instance_info[:instance_id] = actual_id_on_eureka
  @eureka_instance_info[:eureka_url] = config.eureka_url

  puts "=== Eureka Instance Identity ==="
  puts "App ID: #{config.app_id}"
  puts "Instance ID: #{actual_id_on_eureka}"
  puts "================================"
end

if (Rails.env.production? || Rails.env.development? || Rails.env.test?) && Postal::Config.eureka.enabled
  # 1. Đăng ký
  begin
    EurekaRuby.executor.run(:register)
    puts "✅ Registered successfully"
  rescue => e
    puts "❌ Register Error: #{e.message}"
  end

  # 2. Heartbeat
  Thread.new do
    loop do
      begin
        EurekaRuby.executor.run(:send_heatbeat) if EurekaRuby.executor.respond_to?(:run)
      rescue; end
      sleep 30
    end
  end

  # 3. Gỡ đăng ký (Unregister)
  at_exit do
    info = @eureka_instance_info
    next if info[:app_id].nil?

    begin
      base_url = info[:eureka_url].to_s.gsub(/\/$/, '')
      encoded_app_id = ERB::Util.url_encode(info[:app_id])
      encoded_ins_id = ERB::Util.url_encode(info[:instance_id])

      uri = URI.parse("#{base_url}/apps/#{encoded_app_id}/#{encoded_ins_id}")

      puts "🛑 Unregistering from Eureka: #{info[:instance_id]}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 5
      request = Net::HTTP::Delete.new(uri.request_uri)

      response = http.request(request)

      if [200, 204].include?(response.code.to_i)
        puts "✅ Unregistered successfully!"
      else
        puts "❌ Unregister failed (Code: #{response.code})"
      end
    rescue => e
      puts "❌ Error during exit: #{e.message}"
    end
  end
end