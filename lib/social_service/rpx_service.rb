#
# Ruby Helper Class for Janrain Engage RPX Service.
#

require 'uri'
require 'net/http'
require 'net/https'
require 'json'


class RpxService
  attr_reader :api_key, :base_url, :realm

  def initialize(api_key, base_url, realm)
    @api_key = api_key
    @base_url = base_url.sub(/\/*$/, '')
    @realm = realm
  end


  ####################
  # Remote providers #
  ####################

  #
  # Returns data about all supported remote authentication providers.
  #
  def signinup_provider_data
    if @providers.nil?
      @providers = []
      @providers << ProviderData.new('facebook', "https://#{RPX_APP_NAME}/facebook/connect_start?ext_perm=publish_stream,email,offline_access&token_url={url}")
      @providers << ProviderData.new('twitter', "https://#{RPX_APP_NAME}/twitter/start?token_url={url}")
      @providers << ProviderData.new('google', "https://#{RPX_APP_NAME}/openid/start?openid_identifier=https://www.google.com/accounts/o8/id&token_url={url}")
      @providers << ProviderData.new('yahoo', "https://#{RPX_APP_NAME}/openid/start?openid_identifier=http://me.yahoo.com&token_url={url}")
      @providers << ProviderData.new('linkedin', "https://#{RPX_APP_NAME}/linkedin/start?token_url={url}")
      @providers << ProviderData.new('openid', "https://#{RPX_APP_NAME}/openid/start?openid_identifier={input}&token_url={url}", true)
#      @providers << ProviderData.new('windowslive', "https://#{RPX_APP_NAME}/liveid/start?token_url={url}")
#      @providers << ProviderData.new('aol', "https://#{RPX_APP_NAME}/openid/start?openid_identifier=https://openid.aol.com/{input}&token_url={url}", true)
#      @providers << ProviderData.new('wordpress', "https://#{RPX_APP_NAME}/openid/start?openid_identifier=http://{input}.wordpress.com&token_url={url}", true)
#      @providers << ProviderData.new('blogger', "https://#{RPX_APP_NAME}/openid/start?openid_identifier={input}&token_url={url}", true)
#      @providers << ProviderData.new('flickr', "https://#{RPX_APP_NAME}/openid/start?openid_identifier=http://me.yahoo.com&token_url={url}")
#      @providers << ProviderData.new('myopenid', "https://#{RPX_APP_NAME}/openid/start?openid_identifier=http://myopenid.com&token_url={url}")
    end
    @providers
  end


  ##############
  # echo Users #
  ##############

  def get_profile_info(token)
    data = api_call 'auth_info', :token => token
    data['profile']
  end

  def get_user_data(identifier)
    data = api_call 'get_user_data', :identifier => identifier
    data['profile']
  end


  ###########################
  # Social account mappings #
  ###########################

  def mappings(primary_key)
    data = api_call 'mappings', :primaryKey => primary_key
    data['identifiers']
  end

  def map(identifier, key)
    api_call 'map', :primaryKey => key, :identifier => identifier
  end

  def unmap(identifier, key)
    api_call 'unmap', :primaryKey => key, :identifier => identifier
  end

  def all_mappings
    data = api_call 'all_mappings', :apiKey => RPX_API_KEY
    data['mappings']
  end

  def delete_mappings(key)
    api_call 'unmap', :all_identifiers => true, :primaryKey => key
  end

  def signin_url(dest)
    "#{rp_url}/openid/signin?token_url=#{CGI.escape(dest)}"
  end


  ##################
  # Social Sharing #
  ##################

  def share_activity(identifier, activity)
    api_call 'activity', :identifier => identifier, :activity => activity, :truncate => true
  end

  def get_provider_auth_url(provider, token_url)
    url = CGI::escape(token_url)
    case provider
      when "facebook" then "https://#{RPX_APP_NAME}/facebook/connect_start?ext_perm=publish_stream,email,offline_access&token_url=#{url}"
      when "twitter" then "https://#{RPX_APP_NAME}/twitter/start?token_url=#{url}"
      when "google" then "https://#{RPX_APP_NAME}/openid/start?openid_identifier=https://www.google.com/accounts/o8/id&token_url=#{url}"
      when "yahoo!" then "https://#{RPX_APP_NAME}/openid/start?openid_identifier=http://me.yahoo.com&token_url=#{url}"
      when "linkedin" then "https://#{RPX_APP_NAME}/linkedin/start?token_url=#{url}"
#      when "openid" then "https://#{RPX_APP_NAME}/openid/start?openid_identifier={input}&token_url=#{url}"
#      when "windowslive" then "https://#{RPX_APP_NAME}/liveid/start?token_url=#{url}"
#      when "aol" then "https://#{RPX_APP_NAME}/openid/start?openid_identifier=https://openid.aol.com/{input}&token_url=#{url}"
#      when "wordpress" then "https://#{RPX_APP_NAME}/openid/start?openid_identifier=http://{input}.wordpress.com&token_url=#{url}"
#      when "blogger" then "https://#{RPX_APP_NAME}/openid/start?openid_identifier={input}&token_url=#{url}"
#      when "flickr" then "https://#{RPX_APP_NAME}/openid/start?openid_identifier=http://me.yahoo.com&token_url=#{url}"
#      when "myopenid" then "https://#{RPX_APP_NAME}/openid/start?openid_identifier=http://myopenid.com&token_url=#{url}"
    end
  end


  private
  def rp_url
    parts = @base_url.split('://', 2)
    parts = parts.insert(1, '://' + @realm + '.')
    parts.join
  end

  def api_call(method_name, partial_query)
    url = URI.parse("#{@base_url}/api/v2/#{method_name}")
    query = partial_query.dup
    query['format'] = 'json'
    query['apiKey'] = @api_key
    http = Net::HTTP.new(url.host, url.port)
    if url.scheme == 'https'
      http.use_ssl = true
    end
    data = query.map { |k,v|
      "#{CGI::escape k.to_s}=#{CGI::escape v.to_s}"
    }.join('&')
    begin
      resp = http.post(url.path, data)
    rescue SocketError
      raise RpxServerException.new, 'Unable to connect to Rpx Server'
    end
    if resp.code == '200'
      begin
        data = JSON.parse(resp.body)
      rescue JSON::ParserError => err
        raise RpxException.new(resp), 'Unable to parse JSON response'
      end
    else
      raise RpxException.new(resp), "Unexpected HTTP status code from server: #{resp.code}"
    end
    if data['stat'] != 'ok'
      raise RpxException.new(resp), 'Unexpected API error'
    end
    data
  end


  class RpxException < StandardError
    attr_reader :http_response
    def initialize(http_response)
      @http_response = http_response
    end
  end
  class RpxServerException < StandardError
  end

end

