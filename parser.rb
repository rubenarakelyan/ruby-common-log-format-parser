require 'cgi'
require 'csv'
require 'faraday'

COMMON_LOG_FORMAT_REGEX = /(\S+)\s+("-")\s+("-")\s+(\S+\s\d+\s\S+\s\d+\s\d+:\d+:\d+\s\S+)\s+(\S+)\s(\S+)\s+(\d+)/
NON_LOWERCASE_BASE_PATH_REGEX = /[A-Z]+/
LOG_FILE_NAME = ARGV[0]
CSV_OUTPUT_FILE_NAME = ARGV[1]

CSV.open(CSV_OUTPUT_FILE_NAME, "wb") do |csv|
  csv << ["datetime", "base_path", "mixed_case_http_status", "lowercase_http_status"]
  File.foreach(LOG_FILE_NAME) do |log_entry|
    begin
      parsed_log_line = COMMON_LOG_FORMAT_REGEX.match(log_entry)
      base_path = CGI::unescape(parsed_log_line[6].split('?')[0]) # Strip off the query string
      base_path = base_path.split('"')[0] # Ignore URLs with random data in them
      if !!(base_path =~ NON_LOWERCASE_BASE_PATH_REGEX) &&
        !base_path.start_with?('/..') && # Ignore "hacking" attempts
        !base_path.start_with?('/courses/') && # Ignore weird requests for "courses"
        !base_path.start_with?('/cgi-bin/') && # Ignore requests for non-existant folders
        !base_path.start_with?('/government/uploads') && # Ignore uploaded files
        !base_path.include?('/y/') && # Ignore smart answers (has user-entered data in URL)
        base_path != '/AutoDiscover/autodiscover.xml' # Not interested in this file
          # We have a mixed-case base path
          # Find out if the lowercase version (also) works
          begin
            url = "https://www.gov.uk#{base_path.downcase}"
            response = Faraday.get(url)
            response_status = response.status
          rescue URI::InvalidURIError, Faraday::ConnectionFailed
            # Make invalid URLs a 404 for consistency
            response_status = 404
          end
          csv << [parsed_log_line[4], base_path, parsed_log_line[7], response_status]
          puts "#{base_path}: #{parsed_log_line[7]} -> #{response_status}"
      end
    rescue ArgumentError
      # Do nothing
    end
  end
end
