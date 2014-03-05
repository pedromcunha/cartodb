# encoding: utf-8

require_relative '../../lib/synchronizer/file-providers/dropbox'

describe Dropbox do

  def get_config
    {
      app_key: '',
      app_secret: ''
    }
  end #get_config

  describe '#filters' do
    it 'test that filter options work correctly' do
      dropbox_provider = CartoDB::Synchronizer::FileProviders::Dropbox.get_new(get_config)

      # No filter = all formats allowed
      expected_formats = []
      CartoDB::Synchronizer::FileProviders::Dropbox::FORMATS_TO_SEARCH_QUERIES.each do |id, search_queries|
        search_queries.each do |search_query|
          expected_formats = expected_formats.push(search_query)
        end
      end
      dropbox_provider.setup_formats_filter()
      dropbox_provider.formats.should eq expected_formats

      # Filter to 'documents'
      expected_formats = []
      format_ids = [
          CartoDB::Synchronizer::FileProviders::Dropbox::FORMAT_CSV,
          CartoDB::Synchronizer::FileProviders::Dropbox::FORMAT_EXCEL
      ]
      CartoDB::Synchronizer::FileProviders::Dropbox::FORMATS_TO_SEARCH_QUERIES.each do |id, search_queries|
        if format_ids.include?(id)
          search_queries.each do |search_query|
            expected_formats = expected_formats.push(search_query)
          end
        end
      end
      dropbox_provider.setup_formats_filter(format_ids)
      dropbox_provider.formats.should eq expected_formats
    end
  end #run

end
