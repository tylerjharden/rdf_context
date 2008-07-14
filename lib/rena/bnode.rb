class BNode
  attr_accessor :identifier
  def initialize(identifier = nil)
    if identifier != nil && self.valid_id?(identifier) != false
      @identifier = identifier
    else
      @identifier = "bn" + self.hash.to_s
    end
  end
  
  def eql? (eql)
    if self.identifier == eql.identifier
      true
    else
      false
    end
  end
  
  ## 
  # Exports the BNode in N-Triples form.
  #
  # ==== Example
  #   b = BNode.new; b.to_n3  # => returns a string of the BNode in n3 form
  #
  # ==== Returns
  # @return [String] The BNode in n3.
  #
  # @author Tom Morris
  
  def to_n3
    "_:" + @identifier
  end
  
  
  ## 
  # Exports the BNode in N-Triples form.
  #
  # ==== Example
  #   b = BNode.new; b.to_ntriples  # => returns a string of the BNode in N-Triples form
  #
  # ==== Returns
  # @return [String] The BNode in N-Triples.
  #
  # @author Tom Morris
  
  def to_ntriples
    self.to_n3
  end
  
  def to_s
    @identifier
  end  
  
  # TODO: add valid bnode name exceptions?
  protected
  def valid_id? name
    if name =~ /^[a-zA-Z_][a-zA-Z0-9]*$/
      true
    else
      false
    end
  end
end