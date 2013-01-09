require 'base64'
require 'heroku-api'
require 'openssl'
require 'rake'

task :dependencies do
  # Fail fast, we don't have a DEPLOYHOOKS_HTTP_URL
  raise 'Please set $DEPLOYHOOKS_HTTP_URL with a %s at the end' unless
    ENV['DEPLOYHOOKS_HTTP_URL'].to_s =~ /\%s\Z/i
end

desc 'Calculate an example URL hook for testing'
task example: :dependencies do
  encrypted = OpenSSL::Cipher.new('AES-256-CFB').tap do |cipher|
    cipher.encrypt
    cipher.key = ENV['SECRET_TOKEN']
  end.update('cache-bot')

  encoded   = Base64.encode64(encrypted)
  url       = ENV['DEPLOYHOOKS_HTTP_URL'] % encoded

  puts "Example URL: #{url.chomp}"
  puts "Test with: curl -d 'head=23xzh7&git_log=%23bust' #{url.chomp}"
end

desc 'Ensure a web hook is set up for all collaborators'
task hooks: :dependencies do
  # Set up deploy hooks
  Heroku::API.new(api_key: ENV['HEROKU_API_KEY']).tap do |heroku|
    # List each app we are a collaborator on
    heroku.get_apps.body.map do |response|
      response['name']
    end.reject do |app|
      # Already includes a deploy hook?
      # We must have set it up already
      heroku.get_addons(app).body.map do |addons|
        addons['name']
      end.include?('deployhooks:http')
    end.reject do |app|
      heroku.get_config_vars(app).body.any? do |(key, value)|
        #TODO:
        # yell if the variable is set, but doesn't match our hook
        key == 'DEPLOYHOOKS_HTTP_URL'
      end
    end.each do |app|
      # Alright, a new app! Let's install the add-on

      # First, calculate the deploy hook URL
      # based on the app name
      # We'll decrypt this later,
      # then use it to update the correct app
      encrypted = OpenSSL::Cipher.new('AES-256-CFB').tap do |cipher|
        cipher.encrypt
        cipher.key = ENV['SECRET_TOKEN']
      end.update(app)

      encoded   = Base64.encode64(encrypted)
      url       = ENV['DEPLOYHOOKS_HTTP_URL'] % encoded

      puts "Adding deployhook to #{app}: #{url}"
      heroku.post_addon(
        app,
        'deployhooks:http',
        url: url
      )

      # TODO:
      # notify other collaborators that cache-bot is set up
    end
  end
end
