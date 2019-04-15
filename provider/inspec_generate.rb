# Copyright 2017 Google Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'provider/inspec'

module Provider
  # Code generator for Inspec test generation
  class InspecGenerate < Provider::Inspec
    def generate_resource(data)
      data.do_generate = true
      super(data)
      name = data.object.name.underscore
      generate_generation_template(data, name, name.pluralize)
    end

    def generate_generation_template(data, name, plural_name)
      target_folder = File.join(data.output_folder, 'generate')
      target_path = File.join(data.output_folder, 'test/integration/verify/controls')

      data_clone = data.clone
      data_clone.name = "google_#{data.product.api_name}_#{name}"
      data_clone.plural_name = "google_#{data.product.api_name}_#{plural_name}"
      data_clone.target_name = '/Users/slevenick/workspace/iggy'
      data_clone.default_template = 'templates/inspec/generate/generate.erb'
      data_clone.out_file = File.join(target_folder, "#{data.product.api_name}_#{name}.rb")
      data_clone.generate('templates/inspec/generate/generate.erb', data_clone.out_file, self)
    end

    # Returns ruby code that can turn the specified property into an array of 
    # InSpec assertions to test the value of that property for a given object

    def un_parse_code(property, nested = false)
      # If this is a nested object we must qualify the path with the previous path
      # This #{path} will be filled in later, as we traverse the object.
      if nested
        path = "\#\{path\}.#{property.out_name}"
      else
        path = property.out_name
      end

      return "[\"its('#{path}.to_s') { should cmp '\#{x.inspect\}' }\"]" if time?(property)
      if primitive_array?(property)
        # TODO(slevenick): This does not test that the array ONLY includes these items
        return "x.map { |single| \"its('#{path}') { should include \#{single.inspect\} }\" }"
      end

      if map?(property)
        # TODO(slevenick): This does not test that the map ONLY includes these items
        return "x.map { |k, v| \"its('#{path}') { should include(\#{k.inspect} => \#{v.inspect}) }\" }"
      end

      if primitive?(property)
        return "[\"its('#{path}') { should cmp \#{x.inspect\} }\"]"
      elsif typed_array?(property)
        # TODO(slevenick): This does not test that the array ONLY includes these items
        return "x.map { |single| \"its('#{path}') { should include '\#{single.to_json\}' }\" }"
      end
      "#{modularized_property_class(property)}.un_parse(x, \"#{path}\")"
    end

    # We don't want to generate anything but the resource.
    def generate_resource_tests(data) end
  end
end
