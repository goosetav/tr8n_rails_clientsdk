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
#

require 'faraday'
require 'json'
require 'yaml'

API_VERSION_PATH = '/tr8n/api/v1/'

class Tr8n::Base
  attr_reader :attributes

  def initialize(attrs = {})
    @attributes = {}
    attrs.each do |key, value|
      next unless self.class.attributes.include?(key.to_sym)
      @attributes[key.to_sym] = value
    end
  end

  def self.attributes(*attributes)
    @attributes ||= []
    @attributes += attributes.collect{|a| a.to_sym} unless attributes.nil?
    @attributes
  end

  def method_missing(meth, *args, &block)
    method_name = meth.to_s
    method_suffix = method_name.last
    method_key = method_name.to_sym
    if ['=', '?'].include?(method_suffix)
      method_key = method_name[0..-2].to_sym 
    end

    if self.class.attributes.index(method_key)
      if method_name.last == '='
        attributes[method_key] = args.first
        return attributes[method_key]
      end
      return attributes[method_key]
    end

    super
  end      

  def to_api_hash(*attrs)
    return attributes if attrs.nil?
    attributes.slice(*attrs)
  end

  def to_json
    attributes.to_json
  end

protected

  def self.object_class(opts)
    return unless opts[:class]
    opts[:class].is_a?(String) ? opts[:class].constantize : opts[:class]
  end

  def self.process_response(data, opts)
    if data["results"]
      return data["results"] unless object_class(opts)
      objects = []
      data["results"].each do |data|
        objects << object_class(opts).new(data)
      end
      return objects
    end

    return data unless object_class(opts)
    object_class(opts).new(data)
  end

  def self.get(path, params = {}, opts = {})
    data = api(path, params, opts)
    process_response(data, opts)
  end

  def get(path, params = {}, opts = {})
    self.class.get(path, params, opts)
  end

  def self.post(path, params = {}, opts = {})
    data = api(path, params, opts.merge(:method => :post))
    process_response(data, opts)
  end

  def post(path, params = {}, opts = {})
    self.class.post(path, params, opts)
  end

  def self.error?(data)
    not data["error"].nil?
  end

  def self.api(path, params = {}, opts = {})
    params = params.merge(:client_id => Tr8n::Config.app_key)

    pp [:api, path,  params, opts]

    # TODO: sign request

    conn = Faraday.new(:url => "http://#{Tr8n::Config.host}") do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      # faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
    
    if opts[:method] == :post
      response = conn.post("#{API_VERSION_PATH}#{path}", params)
    else
      response = conn.get("#{API_VERSION_PATH}#{path}", params)
    end

    data = JSON.parse(response.body)

    # pp data

    unless data["error"].nil?
      raise Tr8n::Exception.new("Error: #{data["error"]}")
    end

    data
  end

end
