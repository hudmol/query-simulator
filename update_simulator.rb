class UpdateSimulator

  def initialize(opts)
    @thread_count = opts.fetch(:thread_count)
    @output_dir = opts.fetch(:output_dir)
    @updates_per_thread = opts.fetch(:updates_per_thread)
    @aspace_backend_url = URI.parse(opts.fetch(:aspace_backend_url))
    @urls = opts.fetch(:urls)
    @threads = []
  end

  def run
    each_dataset do |dataset|
      @threads << UpdateWorker.new(dataset, @output_dir, @aspace_backend_url).run
    end

    self
  end

  def join
    @threads.each do |t|
      $stderr.puts "Waiting for #{t.id}"
      t.join
    end
  end

  private

  def each_dataset
    @thread_count.times do
      dataset = []
      @updates_per_thread.times do
        dataset << @urls.readline.chomp
      end

      yield(dataset)
    end
  end


  class UpdateWorker

    attr_reader :id

    def initialize(dataset, output_dir, backend_url)
      @dataset = dataset
      @id = SecureRandom.hex
      @output = File.open(File.join(output_dir, @id + ".txt"), "w")
      @result_count = 0
      @aspace_backend_url = backend_url

      @session = login("admin", "admin")
    end

    def run
      $stderr.puts("Starting update worker #{id} hitting #{@dataset.length} URLs")

      @thread = Thread.new do
        @dataset.each do |url|
          begin
            sleep(random_jitter)

            start_time = Time.now
            record = get_record(url)
            log_result("SELECT #{url}", (Time.now.to_f - start_time.to_f) * 1000)
            log_result("UPDATE #{url}", fire_update(url, record))
          rescue
            $stderr.puts("FAILURE IN #{id}: #{$!}")
          end
        end
      end

      self
    end

    def join
      @thread.join
      @output.close
    end

    private

    def login(user, password)
      response = Net::HTTP.post_form(URI.join(@aspace_backend_url, "/users/#{user}/login"),
				     'password' => password)

      raise "Login failed" unless response.code == '200'

      JSON.parse(response.body).fetch('session')
    end

    def get_record(url, opts = {})
      http = Net::HTTP.new(@aspace_backend_url.host, @aspace_backend_url.port)

      request = Net::HTTP::Get.new(url)
      request['X-ArchivesSpace-Session'] = @session
      request.set_form_data(opts)

      response = http.request(request)
      raise "Request failed: #{response.body}" unless response.code == '200'

      JSON.parse(response.body)
    end

    def fire_update(url, record)
      start_time = Time.now
      http = Net::HTTP.new(@aspace_backend_url.host, @aspace_backend_url.port)

      request = Net::HTTP::Post.new(url)
      request['X-ArchivesSpace-Session'] = @session
      request['Content-type'] = "text/json"

      request.body = record.to_json

      response = http.request(request)
      raise "Request failed: #{response.body}" unless response.code == '200'

      (Time.now.to_f - start_time.to_f) * 1000
    end

    def random_jitter
      0
      # rand
    end

    def log_result(url, ms)
      @output.write("#{@result_count}\t#{url}\t#{ms}\n")
      @result_count += 1
    end

  end

end
