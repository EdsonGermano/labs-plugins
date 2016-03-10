require 'httparty'
require 'ruby-progressbar'

module Jekyll
  class OpenAPISpec < Page
    def initialize(site, base, dir, domain, uid)
      @site = site
      @base = base
      @dir = dir
      @name = 'openapi.json'

      self.process(@name)
      self.read_yaml(File.join(base, '_plugins'), 'openapi.json')

      # Fetch real metadata
      meta = HTTParty.get("https://#{domain}/api/views/#{uid}.json")

      # Set up all our page params
      self.data['uid'] = uid
      self.data['domain'] = domain
      self.data['version'] = meta['newBackend'] ? '2.1' : '2.0'
      self.data['title'] = meta['name']
      self.data['description'] = meta["description"]
      # TODO: Dynamically select by endpoint version
      self.data['formats'] = ["application/json"]
      # TODO: Use our entity names where available
      self.data['entity_name'] = "row"
      self.data['entity_name_plural'] = "rows"

      # Generate our properties
      self.data['complex_types'] = {}
      self.data['properties'] = meta["columns"].collect { |col|
        property = case col['dataTypeName']
                     # Simple Datatypes
                     when "checkbox"
                       { "type" => "boolean" }
                     when "double"
                       { "type" => "number", "format" => "double" }
                     when "calendar_date"
                       { "type" => "string", "format" => "date-time" }
                     when "line"
                       { "type" => "line", "format" => "geojson" }
                     when "money"
                       { "type" => "number","format" => "double" }
                     when "number"
                       { "type" => "number", "format" => "double" }
                     when "text"
                       { "type" => "string" }

                       # Complex Datatypes
                     when "location"
                       {
                         "$ref" => "#/definitions/Location"
                       }
                     when "point"
                       self.data['complex_types']["Point"] = {
                         "type" => "object",
                         "properties" => {
                           "type" => {
                             "description" => "The GeoJSON type of this object, `Point`",
                             "type" => "string",
                             "enum" => ["Point"]
                           },
                           "coordinates" => {
                             "description" => "The longitude, latitude coordinates for this Point, in WGS84",
                             "type" => "array",
                             "items" => {
                               "type" => "number",
                               "format" => "double"
                             }
                           }
                         }
                       }

                       {
                         "$ref" => "#/definitions/Point"
                       }
                     when "line"
                       complex_types << "line"
                       {
                         "$ref" => "#/definitions/Line"
                       }
                     when "polygon"
                       {
                         "$ref" => "#/definitions/Polygon"
                       }
                     # Default
                     else
                       { "type" => col['dataTypeName'] }
                     end
        property.merge({
          'name' => col['fieldName'],
          'description' => col['description'] || "",
        })
      }
    end
  end

  class OpenAPI < Jekyll::Generator
    safe false
    priority :lowest

    def generate(site)
      if site.config['dataset_limit']
        # If we've got an apis.json file, we should generate it
        puts "Generating OpenAPI specs... "
        datasets = HTTParty.get("http://api.us.socrata.com/api/catalog/v1?only=datasets&limit=#{site.config['dataset_limit']}")

        progress = ProgressBar.create(:total => datasets["results"].count)

        datasets["results"].each { |dataset|
          uid = dataset['resource']['nbe_fxf'] || dataset['resource']['id']
          domain = dataset["permalink"].match(%r{https://([a-z0-9.-]+)/d/})[1]
          site.pages << OpenAPISpec.new(
            site,
            site.source,
            File.join('foundry', domain, uid),
            domain,
            uid
          )
          progress.increment
        }
      end
    end
  end
end
