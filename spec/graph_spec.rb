require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Graphs" do
  before(:all) do
    @ex = Namespace.new("http://example.org/", "ex")
    @foaf = Namespace.new("http://xmlns.com/foaf/0.1/", "foaf")
    @bn_ctx = {}
  end
  
  subject { Graph.new(:store => ListStore.new) }
  it "should allow you to add one or more triples" do
    lambda do
      subject.add_triple(BNode.new, URIRef.new("http://xmlns.com/foaf/0.1/knows"), BNode.new)
    end.should_not raise_error
  end
  
  it "should support << as an alias for add_triple" do
    lambda do
      subject << Triple.new(BNode.new, URIRef.new("http://xmlns.com/foaf/0.1/knows"), BNode.new)
    end.should_not raise_error
    subject.size.should == 1
  end
  
  it "should return bnode subjects" do
    bn = BNode.new
    subject.add_triple(bn, URIRef.new("http://xmlns.com/foaf/0.1/knows"), bn)
    subject.subjects.should == [bn]
  end
  
  it "should be able to determine whether or not it has existing BNodes" do
    foaf = Namespace.new("http://xmlns.com/foaf/0.1/", "foaf")
    john = BNode.new('john', @bn_ctx)
    jane = BNode.new('jane', @bn_ctx)
    jack = BNode.new('jack', @bn_ctx)
    
    subject << Triple.new(john, foaf.knows, jane)
    subject.has_bnode_identifier?(john).should be_true
    subject.has_bnode_identifier?(jane).should be_true
    subject.has_bnode_identifier?(jack).should_not be_true
  end
  
  it "should allow you to create and bind Namespace objects" do
    subject.bind(Namespace.new("http://xmlns.com/foaf/0.1/", "foaf")).should be_a(Namespace)
    subject.nsbinding["foaf"].uri.should == "http://xmlns.com/foaf/0.1/"
  end
  
  it "should bind namespace" do
    foaf = Namespace.new("http://xmlns.com/foaf/0.1/", "foaf")
    subject.bind(foaf).should == foaf
  end
  
  it "should not allow you to bind things other than namespaces" do
    lambda do
      subject.bind(false)
    end.should raise_error
  end
    
  it "should follow the specification as to output identical triples" do
    subject.add_triple(@ex.a, @ex.b, @ex.c)
    subject.add_triple(@ex.a, @ex.b, @ex.c)
    subject.size.should == 1
  end
  
  it "should parse into existing graph" do
    n3_string = "<http://example.org/> <http://xmlns.com/foaf/0.1/name> \"Gregg Kellogg\" . "
    graph = subject.parse(n3_string, nil, :type => :n3)
    graph.should == subject
    graph.identifier.should be_a(BNode)
    subject.size.should == 1
    subject[0].subject.to_s.should == "http://example.org/"
    subject[0].predicate.to_s.should == "http://xmlns.com/foaf/0.1/name"
    subject[0].object.to_s.should == "Gregg Kellogg"
  end
  
  it "should add multiple triples" do
    subject.add(Triple.new(@ex.a, @ex.b, @ex.c), Triple.new(@ex.a, @ex.b, @ex.d))
    subject.size.should == 2
  end
  
  it "should freeze when destroyed" do
    subject.destroy
    subject.frozen?.should be_true
  end

  describe "with identifier" do
    before(:all) { @identifier = URIRef.new("http://foo.bar") }
    subject { Graph.new(:identifier => @identifier) }
    
    it "should retrieve identifier" do
      subject.identifier.should == @identifier
      subject.identifier.should == @identifier.to_s
    end
  end
  
  describe "with named store" do
    before(:all) do
      @identifier = URIRef.new("http://foo.bar")
      @store = ListStore.new(:identifier => @identifier)
    end
    
    subject {
      g = Graph.new(:identifier => @identifier, :store => @store)
      g.add_triple(@ex.john, @foaf.knows, @ex.jane)
      g.add_triple(@ex.john, @foaf.knows, @ex.rick)
      g.add_triple(@ex.jane, @foaf.knows, @ex.rick)
      g.bind(@foaf)
      g
    }
    
    it "should retrieve identifier" do
      subject.identifier.should == @identifier
      subject.identifier.should == @identifier.to_s
    end
    
    it "should be same as graph with same store and identifier" do
      g = Graph.new(:store => @store, :identifier => @identifier)
      subject.should == g
    end
  end
  
  describe "with XML Literal objects" do
    subject {
      dc = Namespace.new("http://purl.org/dc/elements/1.1/", "dc")
      xhtml = Namespace.new("http://www.w3.org/1999/xhtml", "")
      g = Graph.new(:store => ListStore.new)
      g << Triple.new(
        URIRef.new("http://www.w3.org/2006/07/SWD/RDFa/testsuite/xhtml1-testcases/0011.xhtml"),
        URIRef.new("http://purl.org/dc/elements/1.1/title"),
        Literal.typed("E = mc<sup xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">2</sup>: The Most Urgent Problem of Our Time",
                      "http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral",
                      g.nsbinding)
      )
      g.bind(dc)
      g.bind(xhtml)
      g
    }
    
    it "should output NTriple" do
      nt = '<http://www.w3.org/2006/07/SWD/RDFa/testsuite/xhtml1-testcases/0011.xhtml> <http://purl.org/dc/elements/1.1/title> "E = mc<sup xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">2</sup>: The Most Urgent Problem of Our Time"^^<http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral> .' + "\n"
      subject.to_ntriples.should == nt
    end

    it "should output RDF/XML" do
      rdfxml = <<-HERE
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xml=\"http://www.w3.org/XML/1998/namespace\" xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:xhv=\"http://www.w3.org/1999/xhtml/vocab#\">
  <rdf:Description rdf:about="http://www.w3.org/2006/07/SWD/RDFa/testsuite/xhtml1-testcases/0011.xhtml">
    <dc:title rdf:parseType="Literal">E = mc<sup xmlns="http://www.w3.org/1999/xhtml" xmlns:dc="http://purl.org/dc/elements/1.1/">2>/sup>: The Most Urgent Problem of Our Time</dc:title>
  </rdf:Description>
</rdf:RDF>
HERE
      subject.to_rdfxml.should include("E = mc<sup xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">2</sup>: The Most Urgent Problem of Our Time")
    end
  end
  
  describe "with bnodes" do
    subject {
      g = Graph.new(:store => ListStore.new)
      a = BNode.new("a")
      b = BNode.new("b")
      
      g << Triple.new(a, @foaf.name, Literal.untyped("Manu Sporny"))
      g << Triple.new(a, @foaf.knows, b)
      g << Triple.new(b, @foaf.name, Literal.untyped("Ralph Swick"))
      g.bind(@foaf)
      g
    }
    
    it "should return bnodes" do
      subject.bnodes.keys.length.should == 2
      subject.bnodes.values.should == [2, 2]
    end

    it "should output RDF/XML" do
      rdfxml = <<-HERE
<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xml="http://www.w3.org/XML/1998/namespace" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:xhv="http://www.w3.org/1999/xhtml/vocab#">
  <rdf:Description rdf:nodeID="a">
    <foaf:name>Manu Sporny</foaf:name>
    <foaf:knows rdf:nodeID="b"/>
  </rdf:Description>
  <rdf:Description rdf:nodeID="b">
    <foaf:name>Ralph Swick</foaf:name>
  </rdf:Description>
</rdf:RDF>
HERE
      xml = subject.to_rdfxml
      xml.should include("Ralph Swick")
      xml.should include("Manu Sporny")
    end

    it "should find bnodes" do
      subject.bnodes.length.should == 2
    end
    
    it "should find predicate bnodes" do
      subject.allow_n3 = true
      c = BNode.new("c")
      subject << Triple.new(URIRef.new("http://foo"), c, Literal.untyped("BNode predicate"))
      subject.bnodes.length.should == 3
      subject.bnodes.should include(c)
    end
  end
  
  describe "with namespaces" do
    subject { Graph.new(:store => ListStore.new) }
    
    it "should use namespace with trailing slash" do
      ns = Namespace.new("http://www.example.com/ontologies/test/", "test")
      subject.bind(ns)
      subject.add_triple("http://example.com", ns.hasChallenge, "Interesting Title")
      subject.to_rdfxml.should =~ /<test:hasChallenge/
    end
    
    it "should use namespace with trailing #" do
      ns = Namespace.new("http://www.example.com/ontologies/test#", "test")
      subject.bind(ns)
      subject.add_triple("http://example.com", ns.hasChallenge, "Interesting Title")
      subject.to_rdfxml.should =~ /<test:hasChallenge/
    end

    it "should use namespace with trailing word" do
      ns = Namespace.new("http://www.example.com/ontologies/test", "test")
      subject.bind(ns)
      subject.add_triple("http://example.com", ns.hasChallenge, "Interesting Title")
      subject.to_rdfxml.should =~ /<test:hasChallenge/
    end
  end
  
  describe "with triples" do
    subject {
      g = Graph.new(:store => ListStore.new)
      g.add_triple(@ex.john, @foaf.knows, @ex.jane)
      g.add_triple(@ex.john, @foaf.knows, @ex.rick)
      g.add_triple(@ex.jane, @foaf.knows, @ex.rick)
      g.bind(@foaf)
      g
    }

    it "should detect included triple" do
      subject.contains?(subject[0]).should be_true
    end
    
    it "should tell you how large the graph is" do
      subject.size.should == 3
    end
  
    it "should return unique subjects" do
      subject.subjects.should == [@ex.john.uri.to_s, @ex.jane.uri.to_s]
    end
    
    it "should return unique predicates" do
      subject.predicates.should == [@foaf.knows.uri.to_s]
    end
    
    it "should return unique objects" do
      subject.objects.should == [@ex.jane.uri.to_s, @ex.rick.uri.to_s]
    end
    
    it "should allow you to select resources" do
      subject.triples(Triple.new(@ex.john, nil, nil)).size.should == 2
    end

    it "should allow iteration" do
      count = 0
      subject.triples do |t|
        count = count + 1
        t.class.should == Triple
      end
      count.should == 3
    end

    it "should allow iteration over a particular subject" do
      count = 0
      subject.triples(Triple.new(@ex.john, nil, nil)) do |t|
        count = count + 1
        t.class.should == Triple
        t.subject.should == @ex.john
      end
      count.should == 2
    end

    it "should give you a list of resources of a particular type" do
      subject.add_triple(@ex.john, RDF_TYPE, @foaf.Person)
      subject.add_triple(@ex.jane, RDF_TYPE, @foaf.Person)

      subject.get_by_type("http://xmlns.com/foaf/0.1/Person").should == [@ex.john, @ex.jane]
    end
    
    it "should remove a triple" do
      subject.add(Triple.new(@ex.john, RDF_TYPE, @foaf.Person))
      subject.size.should == 4
      subject.remove(Triple.new(@ex.john, RDF_TYPE, @foaf.Person))
      subject.size.should == 3
    end

    it "should remove all triples" do
      subject.remove(Triple.new(nil, nil, nil))
      subject.size.should == 0
    end

    describe "properties" do
      subject { Graph.new }
      
      it "should get asserted properties" do
        subject.add_triple(@ex.a, @ex.b, @ex.c)
        subject.properties(@ex.a).should be_a(Hash)
        subject.properties(@ex.a).size.should == 1
        subject.properties(@ex.a).has_key?(@ex.b.to_s).should be_true
        subject.properties(@ex.a)[@ex.b.to_s].should == [@ex.c]
      end
      
      it "should get asserted properties with 2 properties" do
        subject.add_triple(@ex.a, @ex.b, @ex.c)
        subject.add_triple(@ex.a, @ex.b, @ex.d)
        subject.properties(@ex.a).should be_a(Hash)
        subject.properties(@ex.a).size.should == 1
        subject.properties(@ex.a).has_key?(@ex.b.to_s).should be_true
        subject.properties(@ex.a)[@ex.b.to_s].should include(@ex.c, @ex.d)
      end

      it "should get asserted properties with 3 properties" do
        subject.add_triple(@ex.a, @ex.b, @ex.c)
        subject.add_triple(@ex.a, @ex.b, @ex.d)
        subject.add_triple(@ex.a, @ex.b, @ex.e)
        subject.properties(@ex.a).should be_a(Hash)
        subject.properties(@ex.a).size.should == 1
        subject.properties(@ex.a).has_key?(@ex.b.to_s).should be_true
        subject.properties(@ex.a)[@ex.b.to_s].should include(@ex.c, @ex.d, @ex.e)
      end

      it "should get asserted type with single type" do
        subject.add_triple(@ex.a, RDF_TYPE, @ex.Audio)
        subject.properties(@ex.a)[RDF_TYPE.to_s].should == [@ex.Audio]
        subject.type_of(@ex.a).should == [@ex.Audio]
      end
    
      it "should get nil with no type" do
        subject.add_triple(@ex.a, @ex.b, @ex.c)
        subject.properties(@ex.a)[RDF_TYPE.to_s].should == nil
        subject.type_of(@ex.a).should == []
      end
      
      it "should sync properties to graph" do
        props = subject.properties(@ex.a)
        props.should be_a(Hash)
        props[RDF_TYPE.to_s] = @ex.Audio
        props[DC_NS.title.to_s] = "title"
        props[@ex.b.to_s] = [@ex.c, @ex.d]
        subject.sync_properties(@ex.a)
        subject.contains?(Triple.new(@ex.a, RDF_TYPE, @ex.Audio)).should be_true
        subject.contains?(Triple.new(@ex.a, DC_NS.title, "title")).should be_true
        subject.contains?(Triple.new(@ex.a, @ex.b, @ex.c)).should be_true
        subject.contains?(Triple.new(@ex.a, @ex.b, @ex.d)).should be_true
      end
    end
    
    describe "find triples" do
      it "should find subjects" do
        subject.triples(Triple.new(@ex.john, nil, nil)).size.should == 2
        subject.triples(Triple.new(@ex.jane, nil, nil)).size.should == 1
      end
      
      it "should find predicates" do
        subject.triples(Triple.new(nil, @foaf.knows, nil)).size.should == 3
      end
      
      it "should find objects" do
        subject.triples(Triple.new(nil, nil, @ex.rick)).size.should == 2
      end
      
      it "should find object with regexp" do
        subject.triples(Triple.new(nil, nil, @ex.rick)).size.should == 2
      end
      
      it "should find combinations" do
        subject.triples(Triple.new(@ex.john, nil, @ex.rick)).size.should == 1
      end
    end
    
    describe "encodings" do
      it "should output NTriple" do
        nt = "<http://example.org/john> <http://xmlns.com/foaf/0.1/knows> <http://example.org/jane> .\n<http://example.org/john> <http://xmlns.com/foaf/0.1/knows> <http://example.org/rick> .\n<http://example.org/jane> <http://xmlns.com/foaf/0.1/knows> <http://example.org/rick> .\n"
        subject.to_ntriples.should == nt
      end
    
      it "should output RDF/XML" do
        rdfxml = <<-HERE
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:ex="http://example.org/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about="http://example.org/john">
    <foaf:knows>
      <rdf:Description rdf:about="http://example.org/jane">
        <foaf:knows rdf:resource="http://example.org/rick"/>
      </rdf:Description>
    </foaf:knows>
    <foaf:knows rdf:resource="http://example.org/rick"/>
  </rdf:Description>
</rdf:RDF>
HERE
        subject.to_rdfxml.should be_equivalent_xml(rdfxml)
      end
    end

    describe "rdf:_n sequences" do
      subject {
        g = Graph.new(:store => ListStore.new)
        g.add_triple(@ex.Seq, RDF_TYPE, RDF_NS.Seq)
        g.add_triple(@ex.Seq, RDF_NS._1, @ex.john)
        g.add_triple(@ex.Seq, RDF_NS._2, @ex.jane)
        g.add_triple(@ex.Seq, RDF_NS._3, @ex.rick)
        g.bind(@ex)
        g
      }
      
      it "should return object list" do
        subject.seq(@ex.Seq).should == [@ex.john, @ex.jane, @ex.rick]
      end
    end
    
    describe "rdf:first/rdf:rest sequences" do
      it "should return object list" do
        a, b = BNode.new("a"), BNode.new("b"), BNode.new("c")
        g = Graph.new(:store => ListStore.new)
        g.add_triple(@ex.List, RDF_NS.first, @ex.john)
        g.add_triple(@ex.List, RDF_NS.rest, a)
        g.add_triple(a, RDF_NS.first, @ex.jane)
        g.add_triple(a, RDF_NS.rest, b)
        g.add_triple(b, RDF_NS.first,  @ex.rick)
        g.add_triple(b, RDF_NS.rest, RDF_NS.nil)
        g.bind(@ex)

        #puts g.seq(@ex.List).inspect
        g.seq(@ex.List).should == [@ex.john, @ex.jane, @ex.rick]
      end
      
      it "should generate a list of resources" do
        g = Graph.new(:store => ListStore.new)
        g.add_seq(@ex.List, RDF_NS.first, [@ex.john, @ex.jane, @ex.rick])
        g.seq(@ex.List).should == [@ex.john, @ex.jane, @ex.rick]
      end
      
      it "should generate an empty list" do
        g = Graph.new(:store => ListStore.new)
        g.add_seq(@ex.List, RDF_NS.first, [])
        g.seq(@ex.List).should == []
      end
    end
  end

  describe "which are merged" do
    it "should be able to integrate another graph" do
      subject.add_triple(BNode.new, URIRef.new("http://xmlns.com/foaf/0.1/knows"), BNode.new)
      g = Graph.new(:store => ListStore.new)
      g.merge!(subject)
      g.size.should == 1
    end
    
    it "should not merge with non graph" do
      lambda do
        h.merge!("")
      end.should raise_error
    end
    
    # One does not, in general, obtain the merge of a set of graphs by concatenating their corresponding
    # N-Triples documents and constructing the graph described by the merged document. If some of the
    # documents use the same node identifiers, the merged document will describe a graph in which some of the
    # blank nodes have been 'accidentally' identified. To merge N-Triples documents it is necessary to check
    # if the same nodeID is used in two or more documents, and to replace it with a distinct nodeID in each
    # of them, before merging the documents.
    it "should remap bnodes to avoid duplicate bnode identifiers" do
      subject.add_triple(BNode.new("a1", @bn_ctx), URIRef.new("http://xmlns.com/foaf/0.1/knows"), BNode.new("a2", @bn_ctx))
      g = Graph.new(:store => ListStore.new)
      g.add_triple(BNode.new("a1", @bn_ctx), URIRef.new("http://xmlns.com/foaf/0.1/knows"), BNode.new("a2", @bn_ctx))
      g.merge!(subject)
      g.size.should == 2
      s1, s2 = g.triples.map {|s| s.subject}
      p1, p2 = g.triples.map {|p| p.predicate}
      o1, o2 = g.triples.map {|o| o.object}
      s1.should_not == s2
      p1.should == p1
      o1.should_not == o2
    end

    it "should remove duplicate triples" do
      subject.add_triple(@ex.a, URIRef.new("http://xmlns.com/foaf/0.1/knows"), @ex.b)
      g = Graph.new(:store => ListStore.new)
      g.add_triple(@ex.a, URIRef.new("http://xmlns.com/foaf/0.1/knows"), @ex.b)
      g.merge!(subject)
      g.size.should == 1
    end
  end
  
  describe "that can be compared" do
    {
      "ListStore" => :list_store,
      "MemoryStore" => :memory_store
    }.each_pair do |t, s|
      describe "using #{t}" do
        subject { Graph.new(:store => s)}
        
        it "should be true for empty graphs" do
          subject.should == Graph.new(:store => s, :identifier => subject.identifier)
        end

        it "should be false for different graphs" do
          f = Graph.new(:store => s, :identifier => subject.identifier)
          f.add_triple(URIRef.new("http://example.org/joe"), URIRef.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), URIRef.new("http://xmlns.com/foaf/0.1/Person"))
          subject.should_not == f
        end
    
        it "should be true for equivalent graphs with different BNode identifiers" do
          subject.add_triple(@ex.a, @foaf.knows, BNode.new("a1", @bn_ctx))
          subject.add_triple(BNode.new("a1", @bn_ctx), @foaf.knows, @ex.a)

          f = Graph.new(:store => s, :identifier => subject.identifier)
          f.add_triple(@ex.a, @foaf.knows, BNode.new("a2", @bn_ctx))
          f.add_triple(BNode.new("a2", @bn_ctx), @foaf.knows, @ex.a)
          subject.should == f
        end
    
        it "should be true for equivalent graphs with different BNode predicates" do
          subject.allow_n3 = true
          subject.add_triple(@ex.a, BNode.new("knows", @bn_ctx), @ex.b)
          subject.add_triple(@ex.b, BNode.new("knows", @bn_ctx), @ex.a)

          f = Graph.new(:store => s, :identifier => subject.identifier, :allow_n3 => true)
          f.add_triple(@ex.a, BNode.new("knows", @bn_ctx), @ex.b)
          f.add_triple(@ex.b, BNode.new("knows", @bn_ctx), @ex.a)
          subject.should == f
        end
    
        it "should be true for graphs with literals" do
          subject.add_triple(@ex.a, @foaf.knows, Literal.untyped("foo"))

          f = Graph.new(:store => s, :identifier => subject.identifier)
          f.add_triple(@ex.a, @foaf.knows, Literal.untyped("foo"))
          subject.should == f
        end
      end
    end
  end
  
  describe "Bnode Permutation matching" do
    {
      "a1"  => %w(aA),
      "a1b1"  => %w(aAbB aBbA),
      "a2b1"  => %w(aAbB),
      "a2b2c1"  => %w(aAbBcC aBbAcC),
      "a2b2c3d3e1f4" => %w(
        aAbBcCdDeEfF
        aBbAcCdDeEfF
        aAbBcDdCeEfF
        aBbAcDdCeEfF
      )
    }.each_pair do |list, perms|
      it "should permute #{list} as #{perms.to_sentence}" do
        h_source = list.scan(/\w\d/).inject({}) {|hash, ad| hash[ad[0,1]] = ad[1,1]; hash}
        h_dest = list.upcase.scan(/\w\d/).inject({}) {|hash, ad| hash[ad[0,1]] = ad[1,1]; hash}
        subject.send(:bnode_permutations, h_source, h_dest) do |hash|
          perm = ""
          #puts hash.inspect
          hash.keys.sort.each {|k| perm << "#{k}#{hash[k]}"}
          perms.should include(perm)
          perms -= [perm]
        end
        perms.should be_empty
      end
    end
  end
end
