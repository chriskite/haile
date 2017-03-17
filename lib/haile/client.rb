require 'uri'
require 'multi_json'
require 'colorize'

module Haile
  class Client
    include HTTParty

    headers(
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    )

    query_string_normalizer proc { |query| ::MultiJson.dump(query) }
    maintain_method_across_redirects
    default_timeout 5

    EDITABLE_APP_ATTRIBUTES = %w(
      cmd constraints container cpus env executor id instances mem ports uris
    )

    def initialize(url = nil, user = nil, pass = nil, proxy = nil)
      @host = url || ENV['MARATHON_URL'] || 'http://localhost:8080'
      @default_options = {}

      if user && pass
        @default_options[:basic_auth] = {:username => user, :password => pass}
      end

      if proxy
        @default_options[:http_proxyaddr] = proxy[:addr]
        @default_options[:http_proxyport] = proxy[:port]
        @default_options[:http_proxyuser] = proxy[:user] if proxy[:user]
        @default_options[:http_proxypass] = proxy[:pass] if proxy[:pass]
      end
    end

    def list
      wrap_request(:get, '/v2/apps')
    end

    def list_tasks(id)
      wrap_request(:get, URI.escape("/v2/apps/#{id}/tasks"))
    end

    def search(id = nil, cmd = nil)
      params = {}
      params[:id] = id unless id.nil?
      params[:cmd] = cmd unless cmd.nil?

      wrap_request(:get, "/v2/apps?#{query_params(params)}")
    end

    def endpoints(id = nil)
      if id.nil?
        url = "/v2/tasks"
      else
        url = "/v2/apps/#{id}/tasks"
      end

      wrap_request(:get, url)
    end

    def upstart(config_file)
      body = JSON.parse(open(config_file).read)
      id = body['id']
      app = wrap_request(:get, "/v2/apps/#{id}").parsed_response['app']
      if !!app
        puts "Updating app #{id}...".green
        resp = wrap_request(:put, "/v2/apps/#{id}", :body => body)
      else
        puts "Starting app #{id}...".blue
        resp = wrap_request(:post, '/v2/apps/', :body => body)
      end

      puts "#{id}: #{resp.to_s}"
    end

    def docker_deploy(id, image)
      # Fetch current state and update only the 'container['docker']['image']'
      # attribute. Since the API only supports PUT, the full representation
      # of the app must be supplied to update even just a single attribute.

      app = wrap_request(:get, "/v2/apps/#{id}").parsed_response['app']
      app.select! {|k, v| EDITABLE_APP_ATTRIBUTES.include?(k)}

      begin
        app['container']['docker']['image'] = image
      rescue
        msg = "App doesn't have a docker image configured. Make sure " \
              "the ID is correct and that this app is already configured " \
              "with a docker image."
        return Haile::Response.error(msg)
      end
      wrap_request(:put, "/v2/apps/#{id}", :body => app)
    end

    def scale(id, num_instances)
      # Fetch current state and update only the 'instances' attribute. Since the
      # API only supports PUT, the full representation of the app must be
      # supplied to update even just a single attribute.
      app = wrap_request(:get, "/v2/apps/#{id}").parsed_response['app']
      app.select! {|k, v| EDITABLE_APP_ATTRIBUTES.include?(k)}

      app['instances'] = num_instances
      wrap_request(:put, "/v2/apps/#{id}", :body => app)
    end

    def kill(id)
      wrap_request(:delete, "/v2/apps/#{id}")
    end

    def kill_tasks(appId, params = {})
      if params[:task_id].nil?
        wrap_request(:delete, "/v2/apps/#{appId}/tasks?#{query_params(params)}")
      else
        query = params.clone
        task_id = query[:task_id]
        query.delete(:task_id)

        wrap_request(:delete, "/v2/apps/#{appId}/tasks/#{task_id}?#{query_params(query)}")
      end
    end

    private

    def wrap_request(method, url, options = {})
      options = @default_options.merge(options)
      http = self.class.send(method, @host + url, options)
      Haile::Response.new(http)
    rescue => e
      Haile::Response.error(e.message)
    end

    def query_params(hash)
      hash = hash.select { |k,v| !v.nil? }
      URI.escape(hash.map { |k,v| "#{k}=#{v}" }.join('&'))
    end
  end
end
