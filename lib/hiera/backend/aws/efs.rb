require "hiera/backend/aws/base"

class Hiera
  module Backend
    module Aws
      # Implementation of Hiera keys for aws/efs
      class EFS < Base
        def initialize(scope = {})
          super(scope)
          @client = Aws::EFS::Client.new
        end

        # Override default key lookup to implement custom format. Examples:
        #  - hiera("efs")
        #  - hiera("efs url environment=dev")
        #  - hiera("efs url role=mgmt-db")
        #  - hiera("efs url environment=production role=mgmt-db")
        def lookup(key, scope)
          r = super(key, scope)
          return r if r

          args = key.split
          return if args.shift != "efs"
          attr = args.shift
          if args.length > 0
            tags = Hash[args.map { |t| t.split("=") }]
            file_systems_with_tags(tags)
          else
            file_systems
          end.map { |i| prepare_instance_data(i,attr) }
        end

        private

        def file_systems
          @client.describe_file_systems[:file_systems]
        end

        def file_systems_with_tags(tags)
          file_systems.select do |i|
            #all_tags = describe_tags(i.fetch(:file_system_id))
            all_tags = fs_tags(i[:file_system_id])
            tags.all? { |k, _| tags[k] == all_tags[k] }
          end
        end

        def fs_tags(file_system_id)
          tags = @client.describe_tags(:file_system_id => file_system_id)
          Hash[tags[:tags].map { |t| [t[:key], t[:value]] }]
        end

        # Prepare RDS instance data for consumption by Puppet. For Puppet to
        # work, all hash keys have to be converted from symbols to strings.
        def prepare_instance_data(hash,attr)

	        case attr
  	      when 'url'
            hash['file_system_id'] + '.efs.eu-west-1.amazonaws.com:/'
          end

        end
      end
    end
  end
end
