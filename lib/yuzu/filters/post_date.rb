require 'helpers/import'
require 'date'

import 'yuzu/filters/base'

module Yuzu::Filters
  class PostDateFilter < Filter
    def initialize
      @directive = "DATE"
      @name = :post_date
    end

    def default(website_file)
      website_file.modified_at
    end

    def get_value(website_file)
      date = match(website_file.raw_contents)

      if not date.nil?
        begin
          date = Date.parse(date)
        rescue => e
          date = nil
        end
      end

      date ||= extract_date_from_filename(website_file)
      date ||= extract_date_from_folder_structure(website_file)
      date ||= default(website_file)
      
      date.is_a?(Date) ? date : Date.parse(date.to_s)
    end

    def extract_date_from_filename(website_file)
      post_filename = website_file.filename
      m = post_filename.match(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}/)
      m.nil? ? nil : Date.parse(m[0])
    end

    def extract_date_from_folder_structure(website_file)
      m = website_file.path.relative.match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}/)
      m.nil? ? nil : Date.parse(m[0].gsub("/", "-"))
    end

  end
  Filter.register(:post_date => PostDateFilter)
end

