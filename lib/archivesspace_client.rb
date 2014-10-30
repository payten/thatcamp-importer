class ArchivesSpaceClient

  DEFAULT_URL = "http://localhost:8089"

  def initialize(url = DEFAULT_URL)
    @url = url
    @corporate_entity_map = {}
    @subject_map = {}
    @person_map = {}
  end

  def login
    puts "Logging In"
    uri = URI.join(@url, "users/admin/login")

    puts uri.inspect

    http = Net::HTTP.new(uri.host, uri.port)
    post = Net::HTTP::Post.new(uri.request_uri)
    post.body = URI.encode_www_form(:password => "admin")
    response = http.request(post)

    @session = JSON.parse(response.body)["session"]
  end


  def create_corporate_entity(org_name, record)
    @corporate_entity_map[org_name] = postJSON("/agents/corporate_entities", record)
  end

  def find_corporate_entity(org_name)
    @corporate_entity_map.fetch(org_name)
  end

  def create_subject(term, record)
    @subject_map[term] = postJSON("/subjects", record)
  end

  def find_subject(subject)
    @subject_map.fetch(subject)
  end

  def create_person(name, record)
    @person_map[name] = postJSON("/agents/people", record)
  end

  def find_person(name)
    @person_map.fetch(name)
  end

  def create_repository(record)
    postJSON("/repositories", record)
  end

  def create_resource(record, repository_uri)
    postJSON("#{repository_uri}/resources", record)
  end

  def create_archival_object(record, repository_uri)
    postJSON("#{repository_uri}/archival_objects", record)
  end


  private

  def postJSON(endpoint_url, json)
    uri = URI.join(@url, endpoint_url)

    puts "--"
    puts "#{endpoint_url}: #{json}"

    http = Net::HTTP.new(uri.host, uri.port)

    post = Net::HTTP::Post.new(uri.request_uri, {
                                 "X-ARCHIVESSPACE-SESSION" => session
                               })
    post.body = json.to_json

    response = http.request(post)

    puts "#{response.code} - #{response.body.inspect}"

    JSON.parse(response.body)["uri"]
  end


  def session
    if @session
      @session
    else
      raise "Not logged in!"
    end
  end

end
