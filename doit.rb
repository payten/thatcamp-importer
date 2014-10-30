#!/usr/bin/ruby

require 'net/http'
require 'json'
require 'uri'

SERVICE_URL = "http://192.168.1.128:4567"

def login
  puts "Logging In"
  uri = URI.join(SERVICE_URL, "users/admin/login")

  puts uri.inspect

  http = Net::HTTP.new(uri.host, uri.port)
  post = Net::HTTP::Post.new(uri.request_uri)
  post.body = URI.encode_www_form(:password => "admin")
  response = http.request(post)

  @session_id = JSON.parse(response.body)["session"]
end

def parse_scraped_data(filename)
  file = File.open(filename)
  contents = ""
  file.each {|line|
    contents << line
  }

  JSON.parse(contents)
end


def build_person(camper)
  {
    "agent_type" => "agent_person",

    "names" => [{
      "primary_name" => camper["name"],
      "title" => camper["title"],
      "name_order" => "direct",
      "sort_name" => camper["name"],
      "source" => "local"
    }],

    "related_agents" => extract_organisations([camper]).map{|org_name| @corporate_entity_map.fetch(org_name)}.map{|uri| {
      "ref" => uri, 
      "relator" => "is_associative_with",
      "jsonmodel_type" => "agent_relationship_associative"
    }}
  }
end


def build_subject(term)
  {
    "vocabulary" => "/vocabularies/1",
    "source" => "local",
    "terms" => [
      {
        "term" => term,
        "term_type" => "topical",
        "vocabulary" => "/vocabularies/1"
      }
    ]
  }
end


def build_corporate_entity(org_name)
  {
    "agent_type" => "agent_corporate_entity",
    "names" => [{
      "primary_name" => org_name,
      "sort_name" => org_name,
      "source" => "local"
    }]
  }
end


def build_resource(data)
  {
    "title" => "ThatCamp Biographies",
    "level" => "collection",
    "id_0" => "TC",
    "id_1" => "1",
    "publish" => true,
    "language" => "eng",
    "extents" => [{
      "portion" => "whole",
      "number" => data.map{|camper| camper["bio"]}.compact.length.to_s,
      "extent_type" => "files"
    }]
  }
end

def build_archival_object(camper, resource_uri)
  {   
    "title" => "Biography for #{camper["name"]}",
    "level" => "item",
    "resource" => {
      "ref" => resource_uri
    },
    "publish" => true,
    "notes" => [{
      "jsonmodel_type" => "note_bibliography",
      "content" => [camper["bio"]],
      "label" => "Biography",
      "publish" => true
    }],
    "subjects" => extract_subjects([camper]).map{|term| {
      "ref" => @subject_map[term]
    }},
    "linked_agents" => [{
      "role" => "subject",
      "ref" => camper["uri"]
    }]
  }
end


def build_repository
  {
    "repo_code" => "ThatCamp",
    "name" => "ThatCamp 2014"
  }
end


def postJSON(endpoint_url, json)
  uri = URI.join(SERVICE_URL, endpoint_url)

  puts "--"
  puts "#{endpoint_url}: #{json}"

  http = Net::HTTP.new(uri.host, uri.port)

  post = Net::HTTP::Post.new(uri.request_uri, {
    "X-ARCHIVESSPACE-SESSION" => @session_id
  })
  post.body = json.to_json

  response = http.request(post)

  puts "#{response.code} - #{response.body.inspect}"

  JSON.parse(response.body)["uri"]
end


def extract_organisations(data)
  data.map {|camper|
    [camper["institution"] ? camper["institution"].downcase : nil] + camper["tags"].map{|tag| (tag["tag-type"] === "organization") ? tag["content"].downcase : nil}
  }.flatten.compact.uniq
end


def extract_subjects(data)
  data.map {|camper|
    camper["tags"].map{|tag| (tag["tag-type"] != "organization") ? tag["content"].downcase : nil}
  }.flatten.compact.uniq
end


def do_it
  puts "--- STARTING ---"
  login

  puts "--- LOAD DATA FILE ---"
  data = parse_scraped_data(ARGV[0])

  @corporate_entity_map = {}
  @subject_map = {}

  puts "--- EXTRACT AND CREATE CORPORATE ENTITIES ---"
  extract_organisations(data).each {|org_name|
    @corporate_entity_map[org_name] = postJSON("/agents/corporate_entities", build_corporate_entity(org_name))
  }
  puts "--- EXTRACT AND CREATE SUBJECTS ---"
  extract_subjects(data).each {|term| 
    @subject_map[term] = postJSON("/subjects", build_subject(term))
  }
  puts "--- CREATE PEOPLE ---"
  data.each {|camper| 
    camper["uri"] = postJSON("/agents/people", build_person(camper))
  }

  puts "--- CREATE A REPOSITORY ---"
  repository_uri = postJSON("/repositories", build_repository)

  puts "--- CREATE A RESOURCE ---"
  resource_uri = postJSON("#{repository_uri}/resources", build_resource(data))

  puts "--- CREATE ARCHIVAL OBJECTS ---"  
  data.each {|camper| 
    postJSON("#{repository_uri}/archival_objects", build_archival_object(camper, resource_uri))
  }

  puts "--- DONE!!! ---"
end


do_it
