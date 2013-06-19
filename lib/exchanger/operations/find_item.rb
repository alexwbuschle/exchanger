module Exchanger
  # The FindItem operation identifies items that are located in a specified folder.
  # 
  # http://msdn.microsoft.com/en-us/library/aa566107.aspx
  class FindItem < Operation
    class Request < Operation::Request
      attr_accessor :folder_id, :traversal, :base_shape, :email_address

      # Reset request options to defaults.
      def reset
        @folder_id = :contacts
        @traversal = :shallow
        @base_shape = :all_properties
        @email_address = nil
      end

      def to_xml
        Nokogiri::XML::Builder.new do |xml|
          xml.send("soap:Envelope", "xmlns:soap" => NS["soap"]) do
            if Exchanger.config.acts_as != nil && Exchanger.config.acts_as != ''
              xml.send("soap:Header") do
                xml.send("t:ExchangeImpersonation") do
                  xml.send("t:ConnectingSID") do
                    xml.send "t:PrimarySmtpAddress", Exchanger.config.acts_as
                  end
                end
              end
            end
            xml.send("soap:Body") do
              xml.FindItem("xmlns" => NS["m"], "xmlns:t" => NS["t"], "Traversal" => traversal.to_s.camelize) do
                xml.ItemShape do
                  xml.send "t:BaseShape", base_shape.to_s.camelize
                end
                xml.ParentFolderIds do
                  if folder_id.is_a?(Symbol)
                    xml.send("t:DistinguishedFolderId", "Id" => folder_id) do
                      if email_address
                        xml.send("t:Mailbox") do
                          xml.send("t:EmailAddress", email_address)
                        end
                      end
                    end
                  else
                    xml.send("t:FolderId", "Id" => folder_id)
                  end
                end
              end
            end
          end
        end
      end
    end

    class Response < Operation::Response
      def items
        to_xml.xpath(".//t:Items", NS).children.map do |node|
          item_klass = Exchanger.const_get(node.name)
          item_klass.new_from_xml(node)
        end
      end
    end
  end
end
