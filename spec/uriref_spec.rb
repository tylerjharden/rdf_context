# coding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'webrick'
include WEBrick
#require 'lib/uriref'

describe "URI References" do
  it "should output NTriples" do
    f = URIRef.new("http://tommorris.org/foaf/")
    f.to_ntriples.should == "<http://tommorris.org/foaf/>"
  end
  
  it "should handle Unicode symbols inside URLs" do
    lambda do
      f = URIRef.new("http://example.org/#Andr%E9")
    end.should_not raise_error
  end
  
  it "should return the 'last fragment' name" do
    fragment = URIRef.new("http://example.org/foo#bar")
    fragment.short_name.should == "bar"
    
    path = URIRef.new("http://example.org/foo/bar")
    path.short_name.should == "bar"
    
    nonetest = URIRef.new("http://example.org/")
    nonetest.short_name.should == false
  end
  
  it "should append fragment to uri" do
    URIRef.new("foo", "http://example.org").should == "http://example.org/foo"
  end
  
  it "must not be a relative URI" do
    lambda do
      URIRef.new("foo")
    end.should raise_error
  end
  
  it "should allow another URIRef to be added" do
    uri = URIRef.new("http://example.org/") + "foo#bar"
    uri.to_s.should == "http://example.org/foo#bar"
    uri.class.should == URIRef
    
    uri2 = URIRef.new("http://example.org/") + Addressable::URI.parse("foo#bar")
    uri2.to_s.should == "http://example.org/foo#bar"
  end

  describe "QName" do
      it "should find with trailing /" do
        ex = Namespace.new("http://example.org/foo/", "ex")
        ex.bar.to_qname(ex.uri.to_s => ex).should == "ex:bar"
      end

      it "should find with trailing #" do
        ex = Namespace.new("http://example.org/foo#", "ex")
        ex.bar.to_qname(ex.uri.to_s => ex).should == "ex:bar"
      end

      it "should find with trailing word" do
        ex = Namespace.new("http://example.org/foo", "ex")
        ex.bar.to_qname(ex.uri.to_s => ex).should == "ex:bar"
      end
    end
  
  describe "namespace" do
    it "should find with trailing /" do
      ex = Namespace.new("http://example.org/foo/", "ex")
      ex.bar.namespace(ex.uri.to_s => ex).should == ex
    end

    it "should find with trailing #" do
      ex = Namespace.new("http://example.org/foo#", "ex")
      ex2 = ex.bar.namespace(ex.uri.to_s => ex)
      ex.bar.namespace(ex.uri.to_s => ex).should == ex
    end

    it "should find with trailing word" do
      ex = Namespace.new("http://example.org/foo", "ex")
      ex.bar.namespace(ex.uri.to_s => ex).should == ex
    end
  end
  
  describe "normalization" do
    {
      %w(http://foo ) =>  "http://foo/",
      %w(http://foo a) => "http://foo/a",
      %w(http://foo /a) => "http://foo/a",
      %w(http://foo #a) => "http://foo/#a",

      %w(http://foo/ ) =>  "http://foo/",
      %w(http://foo/ a) => "http://foo/a",
      %w(http://foo/ /a) => "http://foo/a",
      %w(http://foo/ #a) => "http://foo/#a",

      %w(http://foo# ) =>  "http://foo/", # Special case for Addressable
      %w(http://foo# a) => "http://foo/a",
      %w(http://foo# /a) => "http://foo/a",
      %w(http://foo# #a) => "http://foo/#a",

      %w(http://foo/bar ) =>  "http://foo/bar",
      %w(http://foo/bar a) => "http://foo/a",
      %w(http://foo/bar /a) => "http://foo/a",
      %w(http://foo/bar #a) => "http://foo/bar#a",

      %w(http://foo/bar/ ) =>  "http://foo/bar/",
      %w(http://foo/bar/ a) => "http://foo/bar/a",
      %w(http://foo/bar/ /a) => "http://foo/a",
      %w(http://foo/bar/ #a) => "http://foo/bar/#a",

      %w(http://foo/bar# ) =>  "http://foo/bar",
      %w(http://foo/bar# a) => "http://foo/a",
      %w(http://foo/bar# /a) => "http://foo/a",
      %w(http://foo/bar# #a) => "http://foo/bar#a",

      %w(http://foo/bar# #D%C3%BCrst) => "http://foo/bar#D%C3%BCrst",
      %w(http://foo/bar# #Dürst) => "http://foo/bar#D%C3%BCrst",
    }.each_pair do |input, result|
      it "should create <#{result}> from <#{input[0]}> and '#{input[1]}'" do
        URIRef.new(input[1], input[0], :normalize => true).to_s.should == result
      end
    end
  end
  
  it "should create resource hash for RDF/XML" do
    uri = URIRef.new("http://example.org/foo#bar")
    uri.xml_args.should == [{"rdf:resource" => uri.to_s}]
  end
  
  it "should be equivalent to string" do
    URIRef.new("http://example.org/foo#bar").should == "http://example.org/foo#bar"
  end
  
#   TEST turned off until parser is working.  
#   it "should allow the programmer to Follow His Nose" do
#     a = URIRef.new("http://127.0.0.1:3001/test")
#     
#     # server
#     test_proc = lambda { |req, resp|
#       resp['Content-Type'] = "application/rdf+xml"
#       resp.body = <<-EOF;
# <?xml version="1.0" ?>
# <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:foaf="http://xmlns.com/foaf/0.1/">
#   <rdf:Description rdf:about="http://localhost:3001/test">
#     <foaf:name>Testy McTest</foaf:name>
#   </rdf:Description>
# </rdf:RDF>
#       EOF
#     }
#     test = HTTPServlet::ProcHandler.new(test_proc)
#     s = HTTPServer.new(:Port => 3001)
#     s.mount("/test", test)
#     trap("INT"){ s.shutdown }
#     thread = Thread.new { s.start }
#     graph = a.load_graph
#     s.shutdown
#     graph.class.should == RdfContext::Graph
#     graph.size.should == 1
#   end
end
