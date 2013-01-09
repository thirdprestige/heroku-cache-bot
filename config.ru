require 'heroku-api'
require 'openssl'

# RESPONSES

SKIPPING =   [
  200,
  { 'Content-Type' => 'text/plain' },
  ["no #bust in git logs, skipping cache bust\n"]
]

SUCCESSFUL  = [
  200,
  { 'Content-Type' => 'text/plain' },
  ["hey, heroku! cache busted\n"]
]

UNACCEPTABLE = [
  406,
  { 'Content-Type' => 'text/plain' },
  ["unacceptable! include head, git_log in request\n"]
]

UNAVAILABLE  = [
  503,
  { 'Content-Type' => 'text/plain' },
  ["currently unavailable!\n"]
]

UNAUTHORIZED = [
  405,
  { 'Content-Type' => 'text/plain' },
  ["unauthorized method!\n"]
]

#
# THE APP
#

run lambda { |env|
  # No $HEROKU_API_KEY or $SECRET_TOKEN, fail fast
  next UNAVAILABLE unless [
    ENV['HEROKU_API_KEY'],
    ENV['SECRET_TOKEN']
  ].none?(&:nil?)

  # No GET requests, thank you, fail fast
  next UNAUTHORIZED unless Rack::Request.new(env).post? || ENV['RACK_ENV'] == 'development'

  # We need 3 variables from the request:
  # * The latest release number. This will be turned into the RAILS_CACHE_ID
  # * The git log from the latest deploy.  Determines if we should bust the cache.
  # * The path of the request,
  @release, @log, @path = Rack::Request.new(env).params['head'],
    Rack::Request.new(env).params['git_log'],
    Rack::Request.new(env).path

  next UNACCEPTABLE if [@release, @log, @path].any?(&:nil?)

  # Only bust the cache if requested
  puts "Logs for #{@path}: #{@log}"
  next SKIPPING unless @log.to_s.include?('#bust')

  # We can figure out which app to use by decrypting the path.
  @decoded  = Base64.decode64(@path[1..-1]) # `[1..-1]` skips the leading '/' in the path variable
  @app      = OpenSSL::Cipher.new('AES-256-CFB').tap do |cipher|
    cipher.decrypt
    cipher.key = ENV['SECRET_TOKEN']
  end.update(@decoded)

  puts "Adding new cache ID ##{@release} to #{@app}"
  Heroku::API.new(api_key: ENV['HEROKU_API_KEY']).tap do |heroku|
    begin
      heroku.put_config_vars @app, 'RAILS_CACHE_ID' => @release

      puts "Successfully added cache ID ##{@release} to #{@app}."
    rescue Exception => e
      puts ["\n" * 3, e.class.name, e.message, *e.backtrace, "\n" * 3].join "\n"

      # TODO:
      # Heroku stumbled, automatically re-try?
    end
  end

  SUCCESSFUL
}
