require_relative '../lib/make_index/text_index'

describe TextIndex do



  before :each do

    @text = <<EOF
This is a test of ((Foo)).
That is to say, we went to the ((bar)).
However, ((Foo)) was nowhere to be found!
EOF



  end

  context 'basic index' do

    it 'can be initialized from a string', :string_setup do
      ti = TextIndex.new(string: @text)
      expect(ti.lines.count).to eq(3)
    end

    it 'can be initialized from a file', :file_setup do
      ti = TextIndex.new(string: @text)
      expect(ti.lines.count).to eq(3)
    end

    it 'scans the array lines, producing an array of index terms', :scan  do

      ti = TextIndex.new(string: @text)
      ti.scan
      expect(ti.term_array).to eq(["Foo", "bar", "Foo"])


    end

    it 'scans a string, producing and array of its terms', :scan_string do
      terms = TextIndex.scan_string('This is a test of ((Foo)). Afterwards we will go to the ((bar)).')
      expect(terms).to eq(["Foo", "bar"])
    end

    it 'produces a list of index terms from a piece of text' , :index_map do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      expect(ti.index_map).to be_instance_of(Hash)
      expect(ti.index_map["Foo"]).to eq([0,2])
      expect(ti.index_map["bar"]).to eq([1])
    end

    it 'transforms a string, replacing terms with the corresponding asciidoc element', :transform_line do
      input = 'This is a test of ((Foo)). Afterwards we will go to the ((bar)).'
      ti = TextIndex.new(string: input)
      ti.scan
      ti.make_index_map
      output = ti.transform_line(input)
      expected_output =  "This is a test of index_term::['Foo', 0, mark]. Afterwards we will go to the index_term::['bar', 1, mark]."
      expect(output).to eq(expected_output)
    end


    it 'transforms an array of lines, writing the output to a file', :transform_lines do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      ti.transform_lines('out.adoc')
      output = File.read('out.adoc')
      expected_output = <<EOF
This is a test of index_term::['Foo', 0, mark].
That is to say, we went to the index_term::['bar', 1, mark].
However, index_term::['Foo', 2, mark] was nowhere to be found!
EOF
      expect(output).to eq(expected_output)
    end

    it 'creates the data structure for the index', :index_array  do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      expected_index_array  = [[["bar"], [1]], [["Foo"], [0, 2]]]
      expect(ti.index_array).to eq(expected_index_array)

    end


    it 'creates the data structure for the index', :xindex_array  do
      str = "((foo)), (((foo, bar))), (((foo, bar, baz)))"
      ti = TextIndex.new(string: str)
      ti.scan
      ti.make_index_map
      expected_index_array  = [[["foo"], [0]], [["foo", "bar"], [1]], [["foo", "bar", "baz"], [2]]]
      expect(ti.index_array).to eq(expected_index_array)

    end

    it 'creates an Asciidoc version of the index', :ad_version do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      ti.make_index
      expected_index_text = "\n\n.B\n* <<index_term_1, bar>>\n\n\n.F\n* <<index_term_0, Foo>>\n"
      expect(ti.index).to eq(expected_index_text)
    end

    it 'transforms the marked index terms and appends an index to the generated asciidoc file', :preprocess do
      ti = TextIndex.new(string: @text)
      ti.preprocess('out.adoc')
      output = File.read('out.adoc')
      expected_output = <<EOF
This is a test of index_term::['Foo', 0, mark].
That is to say, we went to the index_term::['bar', 1, mark].
However, index_term::['Foo', 2, mark] was nowhere to be found!


:!numbered:

== Index

[.index_style]
--


.B
* <<index_term_1, bar>>


.F
* <<index_term_0, Foo>>

--
EOF

      expect(output).to eq(expected_output)
    end

  end

  context 'expanded index term', :expanded  do

    before :each do

      @text = <<EOF
This is a test of ((Foo)).
That is to say, we went to the ((bar)).
The (((stool, bar, bar stools)))
were very high.
However, ((Foo)) was nowhere to be found!
EOF

    end

      it 'scans a string, producing and array of its terms', :scan_string2 do
      str = 'This is a test of ((Foo)). Afterwards we will go to the ((bar))'
      str << 'and sit on the (((bar stools, stool, bar))).'
      terms = TextIndex.scan_string(str)
      expect(terms).to eq(["Foo", "bar", "(bar stools, stool, bar)"])
    end

    it 'scans the array lines, producing an array of index terms', :scan2  do

      ti = TextIndex.new(string: @text)
      ti.scan
      expect(ti.term_array).to eq(["Foo", "bar", "(stool, bar, bar stools)", "Foo"])

    end

    it 'produces a list of index terms from a piece of text' , :index_map2 do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      expect(ti.index_map).to be_instance_of(Hash)
      expect(ti.index_map["Foo"]).to eq([0,3])
      expect(ti.index_map["bar"]).to eq([1])
      expect(ti.index_map["(stool, bar, bar stools)"]).to eq([2])
    end

    it 'transforms a string, replacing terms with the corresponding asciidoc element', :transform_line2 do
      input = 'This is a test of ((Foo)). Afterwards we will go to the ((bar))'
      input << ' and sit on the (((stool, bar, bar stools))).'
      ti = TextIndex.new(string: input)
      ti.scan
      ti.make_index_map
      output = ti.transform_line(input)
      expected_output =   "This is a test of index_term::['Foo', 0, mark]. Afterwards we will go to the index_term::['bar', 1, mark] and sit on the index_term::['stool, bar, bar stools', 2, invisible]."
      expect(output).to eq(expected_output)
    end

    it 'transforms an array of lines, writing the output to a file', :transform_lines2 do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      puts 'XXX'
      puts @index_map.to_s
      puts 'XXX'
      ti.transform_lines('out.adoc')
      output = File.read('out.adoc')
      expected_output = <<EOF
This is a test of index_term::['Foo', 0, mark].
That is to say, we went to the index_term::['bar', 1, mark].
The index_term::['stool, bar, bar stools', 2, invisible]
were very high.
However, index_term::['Foo', 3, mark] was nowhere to be found!
EOF
      expect(output).to eq(expected_output)
    end

    it 'creates the data structure for the index', :index_array2  do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      expected_index_array  = [[["bar"], [1]], [["Foo"], [0, 3]], [["stool", "bar", "bar stools"], [2]]]
      expect(ti.index_array).to eq(expected_index_array)

    end

    it 'creates an Asciidoc version of the index', :ad_version2 do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      ti.make_index
      expected_index_text = "\n\n.B\n* <<index_term_1, bar>>\n\n\n.F\n* <<index_term_0, Foo>>\n\n\n.S\n* stool\n** bar\n*** <<index_term_2, bar stools>>\n"
      expect(ti.index).to eq(expected_index_text)
    end

    it 'transforms the marked index terms and appends an index to the generated asciidoc file', :preprocess2 do
      ti = TextIndex.new(string: @text)
      ti.preprocess('out.adoc')
      output = File.read('out.adoc')
      expected_output = <<EOF
This is a test of index_term::['Foo', 0, mark].
That is to say, we went to the index_term::['bar', 1, mark].
The index_term::['stool, bar, bar stools', 2, invisible]
were very high.
However, index_term::['Foo', 3, mark] was nowhere to be found!


:!numbered:

== Index

[.index_style]
--


.B
* <<index_term_1, bar>>


.F
* <<index_term_0, Foo>>


.S
* stool
** bar
*** <<index_term_2, bar stools>>

--
EOF
      expect(output).to eq(expected_output)
    end


  end

  context 'Arthur' do

    before :each do
      @text = <<EOF
The Lady of the Lake, her arm clad in the purest shimmering samite,
held aloft Excalibur from the bosom of the water,
signifying by divine providence that I, ((Arthur)),
was to carry (((Sword, Broadsword, Excalibur))).
That is why I am your king. Shut up! Will you shut up?!
Burn her anyway! I'm not a witch.
Look, my liege! We found them.
EOF
    end


    it 'produces a list of index terms from a piece of text' , :index_map3 do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      puts ti.index_map
      expect(ti.index_map).to be_instance_of(Hash)
      puts "INDEX MAP: #{ti.index_map.to_s.red}"
      expect(ti.index_map["Arthur"]).to eq([0])
      expect(ti.index_map["(Sword, Broadsword, Excalibur)"]).to eq([1])
    end

    it 'transforms an array of lines, writing the output to a file', :transform_lines3 do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      puts 'XXX'
      puts @index_map.to_s
      puts 'XXX'
      ti.transform_lines('out.adoc')
      output = File.read('out.adoc')
      expected_output = <<EOF
The Lady of the Lake, her arm clad in the purest shimmering samite,
held aloft Excalibur from the bosom of the water,
signifying by divine providence that I, index_term::['Arthur', 0, mark],
was to carry index_term::['Sword, Broadsword, Excalibur', 1, invisible].
That is why I am your king. Shut up! Will you shut up?!
Burn her anyway! I'm not a witch.
Look, my liege! We found them.
EOF
      expect(output).to eq(expected_output)
    end



  end

  context 'uppity', :uppity  do

    before :each do

      @text = <<EOF
This is a test of ((Foo)).
That is to say, we went to the
EZ Drinker (((bar, neighborhood))).
The EZ Drinker bar stools (((stool, bar, bar stools)))
were very high.
Sadly, ((Foo)) was nowhere to be found!
EOF

      @text2 = <<EOF
This is a test of ((Foo)).
That is to say, we went to the
EZ Drinker (((bar, neighborhood))).
The EZ Drinker bar stools (((stool, bar, bar stools)))
were very high.
Sadly, ((Foo)) was nowhere to be found!
Fred said that he had gone to
(((bar, commercial)))
Alito's Hangout.
EOF



    end

    it 'produces a list of index terms from a piece of text' , :index_map4 do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      puts ti.index_map
      expect(ti.index_map).to be_instance_of(Hash)
      puts "INDEX MAP: #{ti.index_map.to_s.red}"
      expect(ti.index_map["Foo"]).to eq([0, 3])
      expect(ti.index_map["(bar, neighborhood)"]).to eq([1])
      expect(ti.index_map["(stool, bar, bar stools)"]).to eq([2])
    end

    it 'transforms an array of lines, writing the output to a file', :transform_lines4 do
      ti = TextIndex.new(string: @text)
      ti.scan
      ti.make_index_map
      puts @index_map.to_s.red
      ti.transform_lines('out.adoc')
      output = File.read('out.adoc')
      expected_output = <<EOF
This is a test of index_term::['Foo', 0, mark].
That is to say, we went to the
EZ Drinker index_term::['bar, neighborhood', 1, invisible].
The EZ Drinker bar stools index_term::['stool, bar, bar stools', 2, invisible]
were very high.
Sadly, index_term::['Foo', 3, mark] was nowhere to be found!
EOF
      expect(output).to eq(expected_output)
    end


    it 'creates an Asciidoc version of the index', :ad_version4 do
      ti = TextIndex.new(string: @text2)
      ti.scan
      ti.make_index_map
      ti.make_index
      puts 'MAP'.red
      puts ti.index_map.to_s.red
      puts 'ARRAY'.cyan
      puts ti.index_array.to_s.cyan
      puts 'END'.yellow
      expected_index_text = "\n\n.B\n* bar\n** <<index_term_4, commercial>>\n** <<index_term_1, neighborhood>>\n\n\n.F\n* <<index_term_0, Foo>>\n\n\n.S\n* stool\n** bar\n*** <<index_term_2, bar stools>>\n"
      expect(ti.index).to eq(expected_index_text)
      ti.index
    end

  end

end

