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
      version = @api.version_obj_or_default(data[:version])
      examples = data[:object].examples
                              .reject(&:skip_test)
                              .reject { |e| !e.test_env_vars.nil? && e.test_env_vars.any? }
                              .reject { |e| version < @api.version_obj_or_default(e.min_version) }

      examples.each do |example|
        target_folder = data[:output_folder]
        target_folder = File.join(target_folder, example.name)
        FileUtils.mkpath target_folder

        generate_resource_file data.clone.merge(
          example: example,
          default_template: 'templates/terraform/examples/base_configs/example_file.tf.erb',
          out_file: File.join(target_folder, 'main.tf')
        )

        generate_resource_file data.clone.merge(
          example: example,
          default_template: 'templates/terraform/examples/base_configs/tutorial.md.erb',
          out_file: File.join(target_folder, 'tutorial.md')
        )

        generate_resource_file data.clone.merge(
          default_template: 'templates/terraform/examples/base_configs/example_backing_file.tf.erb',
          out_file: File.join(target_folder, 'backing_file.tf')
        )

        generate_resource_file data.clone.merge(
          default_template: 'templates/terraform/examples/static/motd',
          out_file: File.join(target_folder, 'motd')
        )
      end
    end

    def un_parse_code(property, nested = false)
      if nested
        path = "\#\{path\}.#{property.out_name}"
      else
        path = property.out_name
      end

      return "[\"its('#{path}.to_s') { should cmp '\#{x.inspect\}' }\"]" if time?(property)
      if array?(property)
        return "x.map { |single| \"its('#{path}') { should include \#{single.inspect\} }\" }"
      end

      if map?(property)
        return "x.map { |k, v| \"its('#{path}') { should include(\#{k.inspect} => \#{v.inspect}) }\" }"
      end

      if primitive?(property)
        return "[\"its('#{path}') { should cmp \#{x.inspect\} }\"]"
      elsif typed_array?(property)
        return "x.map { |single| \"its('#{path}') { should include '\#{single.to_json\}' }\" }"
      end
      "#{modularized_property_class(property)}.un_parse(x, \"#{path}\")"
    end

    # We don't want to generate anything but the resource.
    def generate_resource_tests(data) end
  end
end
