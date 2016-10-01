require 'json'

TITLES = JSON.load(File.open('titles.id.txt'))

Pattern = Struct.new(:category, :regexp) do
  def match(string)
    string =~ regexp
  end
end

class Clasifier
  def initialize
    @patterns = File.read('reg_exp_patterns/lukas.txt') .split(/\n/).map do |pattern|
      pattern.sub!(/ #.*$/, '')
      category, regexp = pattern.reverse.split(',', 2).map(&:reverse)
      regexp = regexp[/\/(.*)\//, 1] if regexp
      category = category[/'(.*)'/, 1] if category
      regexp ?  Pattern.new(category, Regexp.new("\\b#{regexp}\\b", 'i')) : nil
    end.compact
  end

  def run(string)
    @patterns.find_all { |pattern| pattern.match(string) }
  end
end

@c = Clasifier.new

def get_categories(id, title, text)
  puts "=" * 80
  res = @c.run(text)
  puts "####{id}:#{res.map(&:category).uniq.join(',')}"
  puts
  p res
  puts
  puts text
end

Dir['backup/*/[0-9]*.txt'].sort_by { |f| f[/(\d+)\.txt/, 1] }.each do |file|
  id = file[/(\d+)\.txt/, 1]
  title = TITLES[id]
  fail "ID=#{id.inspect}: do not have title for file: #{file}" unless title
  body = File.read(file)
  categories = get_categories(id, title, [title, body].join("\n"))
end
