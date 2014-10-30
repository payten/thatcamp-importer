class ArchivesSpaceRecordBuilder

  def person(camper, related_agents)
    {
      "agent_type" => "agent_person",
      "names" => [{
                    "primary_name" => camper.name,
                    "title" => camper.title,
                    "name_order" => "direct",
                    "sort_name" => camper.name,
                    "source" => "local"
                  }],
      "related_agents" => related_agents.map {|uri| {
                                                "ref" => uri,
                                                "relator" => "is_associative_with",
                                                "jsonmodel_type" => "agent_relationship_associative"
                                              }}
    }
  end


  def subject(term)
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


  def corporate_entity(org_name)
    {
      "agent_type" => "agent_corporate_entity",
      "names" => [{
                    "primary_name" => org_name,
                    "sort_name" => org_name,
                    "source" => "local"
                  }]
    }
  end


  def resource(campers)
    {
      "title" => "ThatCamp Biographies",
      "level" => "collection",
      "id_0" => "TC",
      "id_1" => "1",
      "publish" => true,
      "language" => "eng",
      "extents" => [{
                      "portion" => "whole",
                      "number" => campers.select(&:has_bio?).length.to_s,
                      "extent_type" => "files"
                    }]
    }
  end

  def archival_object(camper, resource_uri, agent_uri, subject_uris)
    {
      "title" => "Biography for #{camper.name}",
      "level" => "item",
      "resource" => {
        "ref" => resource_uri
      },
      "publish" => true,
      "notes" => [{
                    "jsonmodel_type" => "note_bibliography",
                    "content" => [camper.bio],
                    "label" => "Biography",
                    "publish" => true
                  }],
      "subjects" => subject_uris.map {|uri| { "ref" => uri }},
      "linked_agents" => [{
                            "role" => "subject",
                            "ref" => agent_uri
                          }]
    }
  end


  def repository
    {
      "repo_code" => "ThatCamp",
      "name" => "ThatCamp 2014"
    }
  end

end
