class CamperSource

  include Enumerable

  def initialize(input)
    @input = input
  end

  def each
    File.open(@input) do |fh|
      JSON.load(fh).each {|elt|
        yield(Camper.from_json(elt))
      }
    end
  end

  def organisations
    map(&:organisations).flatten.uniq
  end

  def subjects
    map(&:subjects).flatten.uniq
  end

end
