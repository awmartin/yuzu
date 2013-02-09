require 'date'

module Wren::Filters
  class PostDateFilter < Filter
    def initialize
      @directive = "DATE"
      @name = :post_date
    end

    def default(website_file)
      website_file.modified_at.strftime("%Y-%m-%d")
    end

    def get_value(website_file)
      date = match(website_file.raw_contents)
      date ||= extract_date_from_filename(website_file)
      date ||= extract_date_from_folder_structure(website_file)
      date ||= default(website_file)
      format_date(date)
    end

    def extract_date_from_filename(website_file)
      post_filename = website_file.filename
      m = post_filename.match(/[0-9]{4}\-[0-9]{2}\-[0-9]{2}/)
      m.nil? ? nil : m[0]
    end

    def extract_date_from_folder_structure(website_file)
      m = website_file.path.relative.match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}/)
      m.nil? ? nil : m[0].gsub("/", "-")
    end

    def format_date(date)
      months = {
        "01" => "January",
        "02" => "February",
        "03" => "March",
        "04" => "April", 
        "05" => "May",
        "06" => "June",
        "07" => "July",
        "08" => "August", 
        "09" => "September",
        "10" => "October",
        "11" => "November",
        "12" => "December"
      }
      year, month, day = date.split("-")[0..2]
      month = months[month]
      return "#{year} #{month} #{day}"
    end
  end
  Filter.register(:post_date => PostDateFilter)
end

