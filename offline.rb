# Copyright (c) 2015 by Chris Metcalf <chris.metcalf@socrata.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'tmpdir'
require 'digest'
require 'fileutils'
require 'open-uri'
require 'mime/types'

module Jekyll
  module OfflineConvertible

    # Monkey patch "write" to modify content before we write it out
    def write(dest)
      if site.config['offline']
        output.gsub!(%r{<(link .*href|script .*src)="(\w*:?//[^"]+)"}) do |match|
          tag = $1
          url = $2

          # We'll use a MD5 hash of the filename to check if we've got this asset already
          hash = Digest::MD5.hexdigest url

          # Check to see if we think we have that file
          matches = Dir.glob(File.join(dest, "offline_cache", hash + ".*"))

          if matches.size > 0
            url = matches.first.gsub(dest, "")
          else
            # Make sure we have somewhere to put it
            FileUtils.mkdir_p(File.join(dest, "offline_cache")) unless File.directory?(File.join(dest, "offline_cache"))

            # We'll need to fetch this one and save it
            puts "Fetching #{url}..."
            open(url.gsub(%r{^//}, "http://")) do |web_file|
              # Figure out the extension based on the mimetype
              ext = MIME::Types[web_file.meta["content-type"]].first.extensions.first

              url = "/offline_cache/#{hash}.#{ext}"
              open(File.join(dest, url), "wb") do |file|
                puts "Saving to #{File.join(dest, url)}..."
                file << web_file.read
              end
            end

          end

          # Finally replace that part of the tag
          "<#{tag}=\"#{url}\""
        end
      end

      super
    end
  end

  module Convertible
    prepend OfflineConvertible
  end
end
