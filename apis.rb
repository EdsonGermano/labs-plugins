require 'httparty'

module Jekyll
  class APIs < Jekyll::Generator
    safe false
    priority :lowest

    def generate(site)
      apis_json = site.pages.detect { |page| page.name == 'apis.json' }
      if apis_json && site.config['dataset_limit']
        # If we've got an apis.json file, we should generate it
        puts "Generating APIs.json file"
        datasets = HTTParty.get("http://api.us.socrata.com/api/catalog/v1?only=datasets&limit=#{site.config['dataset_limit']}") 
        puts "... for #{datasets["results"].count} APIs..."

        apis_json.data['apis'] = datasets["results"].collect { |dataset|
          {
            "name" => dataset["resource"]["name"],
            "description" => dataset["resource"]["description"],
            "uid" => dataset["resource"]["nbe_fxf"] || dataset["resource"]["id"],
            "domain" => dataset["permalink"].match(%r{https://([a-z0-9.-]+)/d/})[1],
            "tags" => dataset["classification"]["domain_tags"]
          }
        }
        apis_json.data['updated_date'] = Time.now.strftime("%Y-%m-%d")
      end
    end
  end
end
