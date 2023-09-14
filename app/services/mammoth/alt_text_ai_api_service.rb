module Mammoth
  class AltTextAiApiService
    require 'net/http'
    require 'json'

    def initialize(options = {})
      @options = options
      @base_url = ENV['ALTTEXT_URL']
      @api_key =  ENV['ALTTEXT_SECRET']
      @payload = @options[:payload] if @options.key?(:payload)
    end

    def get_account
      respon = make_get_request('account')
      return respon
    end

    def create_image
      respon = make_post_request('images')
      return respon
    end

    def make_get_request(endpoint)
      uri = URI.join(@base_url, endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
      request['X-API-Key'] = @api_key

      begin
        response = http.request(request)
        resp_body_obj = Mammoth::AlttextGetAccount.new(JSON.parse(response.body))
        puts "alttest.ai get account info resp body >> #{resp_body_obj.to_json}"
        return resp_body_obj
      rescue StandardError => e
        puts "Error making GET request: #{e.message}" 
      end
    end

    def make_post_request(endpoint)
      uri = URI.join(@base_url, endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      request['X-API-Key'] = @api_key
      request.body = @payload.to_json
      begin
        response = http.request(request)
        resp_body_obj = Mammoth::AlttextCreateImage.new(JSON.parse(response.body))
        puts "alttest.ai create image resp body >> #{resp_body_obj.to_json}"
        return resp_body_obj
      rescue StandardError => e
        puts "Error making POST request: #{e.message}"
      end
    end
  end
end
  