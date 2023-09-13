module Mammoth
    class AltTextAiApiService
      require 'net/http'
      require 'json'
  
      def initialize(options = {})
        @options = options
        @base_url = ENV['ALTTEXT_URL']
        @api_key =  ENV['ALTTEXT_SECRET']
        @payload = @options[:payload] if @options.key?(:payload)
        puts "base url : #{@base_url}, api_key : #{@api_key}, payload : #{@options}"
      end
  
      def get_account
        make_get_request('account')
      end
  
      def create_image
        make_post_request('images')
      end
  
      def make_get_request(endpoint)
        uri = URI.join(@base_url, endpoint)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri, 'Content-Type' => 'application/json')
        request['X-API-Key'] = @api_key
  
        begin
          response = http.request(request)
          resp_body_obj = JSON.parse(response.body, object_class: OpenStruct)
          puts "alttest.ai response body #{resp_body_obj}"
          return resp_body_obj
        rescue StandardError => e
          puts "Error making GET request: #{e.message}"
          return false
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
          resp_body_obj = JSON.parse(response.body, object_class: OpenStruct)
          puts "alttest.ai response body #{resp_body_obj}"
          return resp_body_obj
        rescue StandardError => e
          puts "Error making POST request: #{e.message}"
          return false
        end
      end
    end
  end
  