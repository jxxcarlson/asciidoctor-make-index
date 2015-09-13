
# Usage: ruby make_index.rb foo.adoc
# Purpose: add index to foo.adoc
# Output is in file foo-index.adoc

require 'make_index/text_index'

def message
  out = "\nUsage: 'ruby make_index.rb foo.adoc'\n"
  out << "Purpose: add index to foo.adoc\n"
  out << "Output is in file foo-index.adoc\n\n"
end

# Call on class text_index to
# construct an indexed version
# of the given Asciidoc document,
# then call ascidoctor-latex to
# convert the file to HTML.
def make_index
  if ARGV.count == 0
    puts message
    return
  end
  input_file = ARGV[0]
  ti = TextIndex.new(file: input_file)
  basename = File.basename(input_file, '.adoc')
  output_file = "#{basename}-indexed.adoc"
  ti.preprocess(output_file)
  `asciidoctor-latex -b html #{output_file}`
end

make_index
