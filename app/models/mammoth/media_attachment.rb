module Mammoth
    class MediaAttachment < MediaAttachment
        IMAGE_ALLOW_TYPES = %w(image/jpeg image/png image/gif image/webp image/bmp).freeze

        def can_generate_alt?
            is_valid_content_type? && check_file_size? && generate_alt_text? && check_user_desc?
        end
        
        def check_user_desc?
            !self.description.present? && !self.auto_generated_description.present?
        end

        def generate_alt_text?
            ENV['GENERATE_ALT_TEXT'] ||= false
        end

        def is_valid_content_type?
            IMAGE_ALLOW_TYPES.include?(self.file_content_type)
        end

        def check_file_size?
            self.file_file_size <= 10.megabytes
        end
    end
end