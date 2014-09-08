require 'json'
require 'tmpdir'

module Jekyll
  # Add accessor for directory
  # this lets us get the full path to the page
  class Page
    attr_reader :dir
  end

  class RelatedPagesGenerator < Generator
    # This does nothing for github unfortunately...
    safe true

    def generate(site)
      # We're going to gather a map of URL -> [Pages] mappings
      mappings = Hash.new { |h,k| h[k] = Array.new }

      # First we need a lookup hash of URL -> Page
      page_lookup = site.pages.inject({}) { |hsh, p| hsh[p.url.gsub(/\.html$/, "")] = p; hsh }

      # Loop through all of our pages
      site.pages.each do |page|
        # We need to add both directions into our hash
        (page.data["related"] || []).each do |rel_url|
          related_page = page_lookup[rel_url]

          if related_page
            mappings[page.url.gsub(/\.html$/, "")] << { :url => related_page.url, :title => related_page.data["title"] }
          end
          mappings[rel_url.gsub(/\.html$/, "")] << { :url => page.url, :title => page.data["title"] }
        end
      end

      # Sort the related page listings so that we don't have to do it later
      mappings.values.each { |pages| pages.sort { |a,b| a[:title] <=> b[:title] } }

      begin
        # Dump the mappings into a JSON file we can grab from JavaScript
        file = File.new(File.join(Dir.mktmpdir, "related.json"), "w")
        puts "Writing related page mappings to temporary file..."
        file.write(mappings.to_json)
        file.close

        # Finally, add the json file to the static files list
        site.static_files << Jekyll::StaticFile.new(site, File.dirname(file), "/", "related.json")
      rescue Exception => e
        puts "An error occurred when generating the related.json file.\nThis isn't the end of the world, you just won't get related pages. Please resolve the below exception before committing."
        puts e.inspect
      end
    end
  end
end
