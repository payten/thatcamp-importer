class Tag < Struct.new(:tag_type, :content)
end


class Camper

  attr_reader :name, :title, :bio

  def self.from_json(elt)
    tags = elt['tags'].map {|tag| Tag.new(tag['tag-type'], tag['content'])}

    self.new(elt['name'], elt['title'], elt['institution'], elt['bio'], tags)
  end

  def initialize(name, title, institution, bio, tags)
    @name = name
    @title = title
    @institution = institution
    @bio = bio
    @tags = tags
  end

  def has_bio?
    !@bio.empty?
  end

  def organisations
    organisations = [@institution]
    @tags.select {|tag| tag.tag_type === "organization"}.each do |tag|
      organisations << tag.content
    end

    organisations.compact.map(&:downcase).uniq
  end

  def subjects
    @tags.select {|tag| tag.tag_type != "organization"}.map(&:content).compact.map(&:downcase).uniq
  end

end
