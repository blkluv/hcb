require "google/apis/admin_directory_v1"

module Partners
  module Google
    module GSuite
      module Shared
        module DirectoryClient
          def directory_client
            @directory_client ||= begin
              ::Google::Apis::AdminDirectoryV1::DirectoryService.new.tap do |s|
                s.client_options.application_name = "Hack Club Bank"
                s.client_options.log_http_requests = false
                s.authorization = authorization
              end
            end
          end

          def authorization
            ::GsuiteService.instance.authorize
          end
        end
      end
    end
  end
end
