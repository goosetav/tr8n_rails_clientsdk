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

class HomeController < ApplicationController
  
  before_filter :redirect_if_not_logged_in

  def index    

  end

  def info
    render(:text => Tr8n::Config.application.to_json, :content_type => "text/json")
  end

  def names
    file_path = "/Users/michael/Projects/Tr8n/tr8n_core/spec/fixtures/translations/ru/names.json"
    if request.post?
      names = {}
      params[:names].keys.each do |name|
        names[name] = params[:names][name]
      end
      File.open(file_path, "w") do |output|
        output.write(names.to_json)
      end
      trfn("File has been saved")
    end
    @names = Tr8n::Helper.load_json(file_path)
  end

end
