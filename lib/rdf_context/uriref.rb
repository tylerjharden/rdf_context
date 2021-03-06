require 'net/http'

module RdfContext
  class URIRef
    attr_accessor :uri
    attr_reader   :namespace
    
    # Create a URIRef from a URI  or a fragment and a URI
    #
    # ==== Example
    #   u = URIRef.new("http://example.com")
    #   u = URIRef.new("foo", u) => "http://example.com/foo"
    # 
    # Last argument may be an options hash to set:
    # @options[:normalize]:: Normalize URI when transforming to string, defaults to true
    # @options[:namespace]:: Namespace used to create this URI, useful for to_qname
    def initialize (*args)
      options = args.last.is_a?(Hash) ? args.pop : { :normalize => true }
      @normalize = options[:normalize]
      @namespace = options[:namespace]

      args.each {|s| test_string(s)}
      if args.size == 1
        uri = Addressable::URI.parse(args[0].to_s)
      else
        uri = Addressable::URI.join(*args.map{|s| s.to_s}.reverse)
      end

      raise ParserException, "<" + uri.to_s + "> is a relative URI" if uri.relative?

      # Unique URI through class hash to ensure that URIRefs can be easily compared
      @@uri_hash ||= {}
      @uri = @@uri_hash["#{uri}#{@normalize}"] ||= begin
        # Special case if URI has no path, and the authority ends with a '#'
        uri = Addressable::URI.parse($1) if @normalize && uri.to_s.match(/^(.*)\#$/)

        @normalize ? uri.normalize : uri
      end.freeze
    end
    
    # Create a URI, either by appending a fragment, or using the input URI
    def + (input)
      input_uri = Addressable::URI.parse(input.to_s)
      return URIRef.new(input_uri, self.to_s)
    end
    
    # short_name of URI for creating QNames.
    #   "#{base]{#short_name}}" == uri
    def short_name
      @short_name ||= if @namespace
        self.to_s.sub(@namespace.uri.to_s, "")
      elsif @uri.fragment()
        @uri.fragment()
      elsif @uri.path.split("/").last.class == String and @uri.path.split("/").last.length > 0
        @uri.path.split("/").last
      else
        false
      end
    end
    
    # base of URI for creating QNames.
    #   "#{base]{#short_name}}" == uri
    def base
      @base ||= begin
        uri_base = self.to_s
        sn = short_name.to_s
        uri_base[0, uri_base.length - sn.length]
      end
    end
  
    def eql?(other)
      self.to_s == other.to_s
    end
    alias_method :==, :eql?
    
    def <=>(other)
      self.to_s <=> other.to_s
    end
  
    # Needed for uniq
    def hash; to_s.hash; end
  
    def to_s
      @to_s ||= @uri.to_s
    end
  
    def to_n3
      "<" + self.to_s + ">"
    end
    alias_method :to_ntriples, :to_n3
  
    # Output URI as QName using URI binding
    def to_qname(uri_binding = {})
      ns = namespace(uri_binding)
      "#{ns.prefix}:#{short_name}"
    end
    
    def namespace(uri_binding = {})
      @namespace ||= begin
        uri = uri_binding.keys.detect {|u| self.to_s.index(u) == 0 }
        raise RdfException, "Couldn't find namespace for #{@uri}" unless uri
        uri_binding[uri]
      end
    end
    
    def inspect
      "#{self.class}[#{self.to_n3}]"
    end
    
    # Output URI as resource reference for RDF/XML
    def xml_args
      [{"rdf:resource" => self.to_s}]
    end
    
    protected
    def test_string (string)
      string.to_s.each_byte do |b|
        if b >= 0 and b <= 31
          raise ParserException, "URI '#{string}' must not contain control characters"
        end
      end
    end
  end
end
