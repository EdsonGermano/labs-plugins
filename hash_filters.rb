
module Jekyll
  module HashFilter 
    def merge(input, key, value)
      return input.merge(key => value)
    end

    def delete(input, key)
      return input.delete_if { |k, v| k == key }
    end
  end
end

Liquid::Template.register_filter(Jekyll::HashFilter)
