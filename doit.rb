#!/usr/bin/ruby

require 'net/http'
require 'json'
require 'uri'

require_relative 'lib/archivesspace_builder'
require_relative 'lib/archivesspace_client'
require_relative 'lib/camper'
require_relative 'lib/camper_source'


class THATCampLoader

  def initialize(input_file)
    @input = input_file
  end

  def call
    client = ArchivesSpaceClient.new
    builder = ArchivesSpaceRecordBuilder.new

    puts "--- STARTING ---"
    client.login

    puts "--- LOAD DATA FILE ---"
    campers = CamperSource.new(@input)

    puts "--- EXTRACT AND CREATE CORPORATE ENTITIES ---"
    campers.organisations.each {|org_name|
      client.create_corporate_entity(org_name, builder.corporate_entity(org_name))
    }

    puts "--- EXTRACT AND CREATE SUBJECTS ---"
    campers.subjects.each {|term|
      client.create_subject(term, builder.subject(term))
    }

    puts "--- CREATE PEOPLE ---"
    campers.each {|camper|
      related_agents = camper.organisations.map {|org_name| client.find_corporate_entity(org_name)}
      client.create_person(camper.name, builder.person(camper, related_agents))
    }

    puts "--- CREATE A REPOSITORY ---"
    repo_uri = client.create_repository(builder.repository)

    puts "--- CREATE A RESOURCE ---"
    resource_uri = client.create_resource(builder.resource(campers), repo_uri)

    puts "--- CREATE ARCHIVAL OBJECTS ---"
    campers.each {|camper|
      camper_uri = client.find_person(camper.name)
      subjects = camper.subjects.map {|subject| client.find_subject(subject)}
      archival_object = builder.archival_object(camper, resource_uri, camper_uri, subjects)

      client.create_archival_object(archival_object, repo_uri)
    }

    puts "--- DONE!!! ---"
  end

end

if __FILE__ == $0
  THATCampLoader.new(ARGV[0]).call
end
