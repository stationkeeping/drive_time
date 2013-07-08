module DriveTime
  
  # Load a Spreadsheet from Google Drive
  class SpreadsheetLoader

    class SpreadsheetNotFoundError < StandardError; end
    class WorksheetNotFoundError < StandardError; end

    def initialize
      @session = GoogleDrive.login( ENV['GOOGLE_USERNAME'], ENV['GOOGLE_PASSWORD'])
    end

    def load_spreadsheet(title, use_cache=true)
      Logger.info 'TITLE '+title
      cached_directory = ENV['CACHED_DIR']
      Logger.info 'CACHED DIR '+cached_directory
      spreadsheet_name = "#{title}.yml"
      #spreadsheet_file_path = File.join(cached_directory, spreadsheet_name) if cached_directory

      Logger.info "FILEPATH "+spreadsheet_file_path
      spreadsheet = nil

      # Try and pull the file from the cache
      if cached_directory && use_cache
        
        if File.exist? spreadsheet_file_path
          File.open(spreadsheet_file_path, 'r') do |file|
            Logger.info "Pulling spreadsheet '#{title}' from cache"
            spreadsheet = YAML::load(file)
          end
        end
      end

      # If we haven't loaded a spreadsheet from cache, get it from drive
      unless spreadsheet
        Logger.info "Loading spreadsheet '#{title}' from Drive"
        spreadsheet = @session.spreadsheet_by_title(title)

        raise SpreadsheetNotFoundError, "Spreadsheet #{title} not found" if spreadsheet.nil?
        # Save the file to cache directory
        if cached_directory && use_cache
          # Save the spreadsheet
          Logger.info "Saving spreadsheet '#{title}' to cache"
          File.open(spreadsheet_file_path, 'w') do |file|
            file.puts YAML::dump(spreadsheet)
          end

          # Save its worksheets
          spreadsheet.worksheets.each do |worksheet|
            Logger.info "Saving worksheet '#{worksheet.title}' to cache"
            # Force worksheet to down of cells data
            #worksheet.reload
            worksheet_file_path = File.join(cached_directory, worksheet.title) + '.yml'
            File.open(worksheet_file_path, 'w') do |file|
              file.puts YAML::dump(worksheet)
            end
          end
        end
      end
      
      return spreadsheet
    end

    def load_worksheet_from_spreadsheet(spreadsheet, title, use_cache=true)
      cached_directory = ENV['CACHED_DIR']
      worksheet_name = "#{title}.yml"
      worksheet_file_path = File.join(cached_directory, title)
      worksheet = nil

      # Get the worksheet from the cache
      if cached_directory && use_cache
        if File.exist? worksheet_file_path
          File.open(worksheet_file_path, 'r') do |file|
            Logger.info "Pulling worksheet '#{title}' from cache"
            worksheet = YAML::load(file)
          end
        end
      end

      # If we don't yet have a worksheet, pull it from Google Drive via the Spreadsheet
      unless worksheet
        worksheet = spreadsheet.worksheet_by_title title
        raise WorksheetNotFoundError, "Worksheet '#{title}'' not found in spreadsheet '#{spreadsheet.title}'" if worksheet.nil?
      end

      return worksheet
    end

  end
end