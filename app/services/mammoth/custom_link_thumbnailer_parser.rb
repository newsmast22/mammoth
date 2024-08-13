# frozen_string_literal: true
require 'link_thumbnailer'
require 'open-uri'
require 'net/http'

module Mammoth
  class CustomLinkThumbnailerParser < LinkThumbnailer::Parser
    def parse(url)
      if url.include?('youtube.com') || url.include?('youtu.be')
        # Custom logic to extract YouTube thumbnail
        extract_youtube_thumbnail(url)
      else
        LinkThumbnailer.generate(url)
      end
    end

    private

    def extract_youtube_thumbnail(url)
      video_id = extract_video_id(url)
      link_preview = LinkThumbnailer.generate(url)
      {
        description: link_preview.description,
        url: link_preview.url,
        title: link_preview.title,
        favicon: nil,
        images:[
          src: "https://img.youtube.com/vi/#{video_id}/hqdefault.jpg",# or choose a different thumbnail quality,
          type: "jpg",
          size: get_image_size("https://img.youtube.com/vi/#{video_id}/hqdefault.jpg")
        ],
        videos: []
      }
    end

    def extract_video_id(url)
      uri = URI.parse(url)
      
      if uri.host.include?('youtube.com')
        query_params = CGI.parse(uri.query)
        query_params['v'].first
      elsif uri.host.include?('youtu.be')
        uri.path.split('/').last
      end
    end

    def get_jpeg_dimensions(data)
      # Ensure it's a JPEG file
      raise "Not a JPEG file" unless data[0..1] == "\xFF\xD8"
    
      offset = 2
      while offset < data.size
        # Read marker (2 bytes) and length (2 bytes)
        marker, code, length = data[offset], data[offset + 1], data[offset + 2, 2].unpack1('n')
        
        if marker == "\xFF" && code >= "\xC0" && code <= "\xC3" # SOF0, SOF1, SOF2 markers
          # SOF marker found, extract dimensions
          height, width = data[offset + 5, 2].unpack1('n'), data[offset + 7, 2].unpack1('n')
          return [width, height]
        end
    
        # Move to the next segment
        offset += 2 + length
      end
    
      raise "Could not find JPEG dimensions"
    end
    
    def get_image_size(url)
      uri = URI(url)

      # Fetch the image data
      image_data = Net::HTTP.get(uri)

      # Get image dimensions
      begin
        width, height = get_jpeg_dimensions(image_data)
        puts "Image width: #{width}px, height: #{height}px"
        [width, height]
      rescue => e
        puts "Error: #{e.message}"
      end
      
    end

  end
end
