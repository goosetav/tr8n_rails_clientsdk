#--
# Copyright (c) 2010-2013 Michael Berkovich, tr8nhub.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'thor'
require 'faraday'
require 'pp'
require 'json'

API_BASE_URL = 'http://tr8nhub.com'

module Tr8nClientSdk
  class Cli < Thor
    include Thor::Actions

    class << self
      def source_root
        File.expand_path('../../',__FILE__)
      end
    end

    map 'l' => :lookup

    desc 'lookup PHRASE', 'Lookup translations for a phrase'
    method_option :description, :type => :string, :aliases => "-d", 
                  :required => false, :banner => "Context in which the phrase is used", :default => ""
    def lookup(query)
      data = http_get('translation_key/lookup', {:query => query, :limit => 10, :only_list => true})
      # pp data

      results = data['results']
      unless results
        say "No results found"
        return
      end      

      if results.size < 10
        say("Found #{results.size} result(s) for search string: \"#{query}\"")
      else
        say("Found many matches for search string: \"#{query}\". Showing first 10 results:")
      end
      say("\n")

      results.each_with_index do |tk, tki|
        line = ["\t", "#{tki+1}). ", "\"#{tk['label']}\""]
        line << " (context: #{tk['description']})" unless tk['description'].nil? or tk['description'].empty?
        if tk['translations'] and tk['translations'].size > 0
          line << " - #{tk['translations'].size} translations"
        else
          line << " - no translations"
        end
        say(line.join(''))

        if tk['translations']
          tk['translations'].each_with_index do |tr, ti|
            line = ["\t", "\t", "#{ti+1}). "]
            line << "\"#{tr['value']}\""
            line << " (locale: #{tr['locale']}, rank: #{tr['rank']})"
            say(line.join(''))
          end
        end

        say("\n") 
      end
      say("\n")
    end

    desc 'itr', 'Interactive Tr8n Shell'
    def itr
      value = ask '->'

      while true do
        opts = value.split(' ')
        params = opts.size > 1 ? opts[1..-1] : []

        case opts.first
        when 'lookup', 'l'
          lookup(*params)
        when 'exit', 'e'
          return
        end

        value = ask '->'
      end
    end

    private

      def http_get(path, params = {})
        conn = Faraday.new(:url => API_BASE_URL) do |faraday|
          faraday.request  :url_encoded             # form-encode POST params
          # faraday.response :logger                  # log requests to STDOUT
          faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        end
        
        response = conn.get("/api/#{path}", params)
        JSON.parse(response.body)
      end

  end
end
