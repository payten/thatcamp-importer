#!/usr/bin/env ruby1.9.3

require 'rspec'
require_relative 'doit'


describe "THATCamp importer" do
  let(:camper) {
    Camper.from_json({
                       "bio" => "This is a bio",
                       "institution" => "Freelance",
                       "name" => "That Camper",
                       "tags" => [
                         {
                           "content" => "Earth",
                           "tag-type" => "organization"
                         },
                         {
                           "content" => "Balloons",
                           "tag-type" => "subject"
                         },
                       ],
                       "title" => "Camper"
                     })
  }


  let(:expected_posts) {
    [{:endpoint=>"/agents/corporate_entities",
      :json=>{"agent_type"=>"agent_corporate_entity",
              "names"=>[{"primary_name"=>"freelance", "sort_name"=>"freelance", "source"=>"local"}]}},

     {:endpoint=>"/agents/corporate_entities",
      :json=>{"agent_type"=>"agent_corporate_entity",
              "names"=>[{"primary_name"=>"earth", "sort_name"=>"earth", "source"=>"local"}]}},

     {:endpoint=>"/subjects",
      :json=>{"vocabulary"=>"/vocabularies/1",
              "source"=>"local",
              "terms"=>
              [{"term"=>"balloons", "term_type"=>"topical", "vocabulary"=>"/vocabularies/1"}]}},


     {:endpoint=>"/agents/people",
      :json=>{"agent_type"=>"agent_person",
              "names"=>[{"primary_name"=>"That Camper",
                         "title"=>"Camper",
                         "name_order"=>"direct",
                         "sort_name"=>"That Camper",
                         "source"=>"local"}],
              "related_agents"=>[{"ref"=>"/my/fake-uri", "relator"=>"is_associative_with", "jsonmodel_type"=>"agent_relationship_associative"},
                                 {"ref"=>"/my/fake-uri", "relator"=>"is_associative_with", "jsonmodel_type"=>"agent_relationship_associative"}]}},

     {:endpoint=>"/repositories",
      :json=>{"repo_code"=>"ThatCamp", "name"=>"ThatCamp 2014"}},

     {:endpoint=>"/my/fake-uri/resources",
      :json=>{"title"=>"ThatCamp Biographies",
              "level"=>"collection",
              "id_0"=>"TC",
              "id_1"=>"1",
              "publish"=>true,
              "language"=>"eng",
              "extents"=>[{"portion"=>"whole",
                           "number"=>"1",
                           "extent_type"=>"files"}]}},

     {:endpoint=>"/my/fake-uri/archival_objects",
      :json=>{"title"=>"Biography for That Camper",
              "level"=>"item",
              "resource"=>{"ref"=>"/my/fake-uri"},
              "publish"=>true,
              "notes"=>[{"jsonmodel_type"=>"note_bibliography",
                         "content"=>["This is a bio"],
                         "label"=>"Biography",
                         "publish"=>true}],
              "subjects"=>[{"ref"=>"/my/fake-uri"}],
              "linked_agents"=>[{"role"=>"subject",
                                 "ref"=>"/my/fake-uri"}]}}]
  }



  it "imports our camper" do
    allow_any_instance_of(ArchivesSpaceClient).to receive(:login) { "mysession" }

    posts = []
    allow_any_instance_of(ArchivesSpaceClient).to receive(:postJSON) {|obj, endpoint, json|
      posts << {:endpoint => endpoint, :json => json}
      "/my/fake-uri"
    }

    allow_any_instance_of(CamperSource).to receive(:each) {|&block|
      block.call(camper)
    }

    THATCampLoader.new(:ignored).call

    expect(posts).to eq(expected_posts)
  end

end
