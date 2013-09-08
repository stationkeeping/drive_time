require 'spec_helper'

module DriveTime

  VALID_SPREADSHEET_1_TITLE = 'Fixture 1'
  VALID_SPREADSHEET_2_TITLE = 'Fixture 2'
  INVALID_SPREADSHEET_TITLE = 'Invalid Title xccdtyyehdyd56ejr6'

  describe Loader do

    def last_access_time_for_cached_file(title)
      cached_directory = ENV['CACHED_DIR']
      file_name = "#{title}.yml"
      file_path = File.join(cached_directory, file_name)
      File.atime(file_path).to_i
    end

    def clear_cache_dir
      cached_directory = ENV['CACHED_DIR']
      FileUtils.rm Dir.glob("#{cached_directory}/*")
    end

    def cached_file_exists(file_name)
      cached_directory = ENV['CACHED_DIR']
      file_name = "#{VALID_SPREADSHEET_1_TITLE}.yml"
      file_path = File.join(cached_directory, file_name)
      return File.exists? file_path
    end

    before(:each ) do
      @loader = Loader.new
    end

    context 'When not using cache' do

      context 'when accessing a spreadsheet' do

        it "should raise a SpreadsheetNotFoundError if a spreadsheet doesn't exist" do
          expect{ @loader.load_spreadsheet(INVALID_SPREADSHEET_TITLE, false) }.to raise_error(Loader::SpreadsheetNotFoundError)
        end

        it "should download a Spreadsheet sucessfully" do
          @loader.load_spreadsheet(VALID_SPREADSHEET_1_TITLE, false).title.should == VALID_SPREADSHEET_1_TITLE
        end

      end

      context 'when accessing a worksheet from with a loaded spreadsheet' do

        before(:each) do
          @spreadsheet = @loader.load_spreadsheet(VALID_SPREADSHEET_1_TITLE, false)
        end

        it "should raise a SpreadsheetNotFoundError if a worksheet doesn't exist" do
          expect{ @loader.load_worksheet_from_spreadsheet(@spreadsheet, 'nmgsgscg', false) }.to raise_error(Loader::WorksheetNotFoundError)
        end

        it "should download a Worksheet sucessfully" do
          @loader.load_worksheet_from_spreadsheet(@spreadsheet, 'Label', false).title.should == 'Label'
        end

      end
    end

    context 'When using cache' do

      before(:each) do
        @spreadsheet = @loader.load_spreadsheet(VALID_SPREADSHEET_1_TITLE, false)
        # Save the time so we can check file access
        @before = Time.now.to_i
      end

      context 'when accessing a spreadsheet' do
        it "should pull a Spreadsheet from the cache if it exists" do
          @loader.load_spreadsheet(VALID_SPREADSHEET_1_TITLE).title.should == VALID_SPREADSHEET_1_TITLE
          last_access_time_for_cached_file(VALID_SPREADSHEET_1_TITLE).should <= @before
        end

        it "should download a Spreadsheet if it isn't in the cache" do
          clear_cache_dir
          @loader.load_spreadsheet(VALID_SPREADSHEET_1_TITLE, false).title.should == VALID_SPREADSHEET_1_TITLE
        end

        it "should save the spreadsheet to the cache" do
          clear_cache_dir
          @loader.load_spreadsheet(VALID_SPREADSHEET_1_TITLE)
          cached_file_exists(VALID_SPREADSHEET_1_TITLE).should be_true
        end

        it "should save the spreadsheet's worksheets to the cache" do
          clear_cache_dir
          @loader.load_spreadsheet(VALID_SPREADSHEET_1_TITLE)
          cached_file_exists('Label').should be_true
          cached_file_exists('Act').should be_true
          cached_file_exists('Album').should be_true
          cached_file_exists('Group').should be_true
        end

      end

      context 'when accessing a worksheet from with a loaded spreadsheet' do

        it "should download a Spreadsheet sucessfully" do
          @loader.load_worksheet_from_spreadsheet(@spreadsheet, 'Label').title.should == 'Label'
        end

      end

    end
  end
end
