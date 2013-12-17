module Exchanger
  # The ResolveNames operation resolves ambiguous e-mail addresses and display names.
  # 
  # http://msdn.microsoft.com/en-us/library/aa563518.aspx
  class ResolveNames < Operation
    class Request < Operation::Request
      attr_accessor :name

      # Reset request options to defaults.
      def reset
        @name = nil
      end

      def to_xml
        Nokogiri::XML::Builder.new do |xml|
          xml.send("soap:Envelope", "xmlns:soap" => NS["soap"], "xmlns:t" => NS["t"]) do
            if Exchanger.config.version || Exchanger.config.acts_as
              xml["soap"].Header do
                if Exchanger.config.version
                  xml["t"].RequestServerVersion("Version" => Exchanger.config.version)
                end
                if Exchanger.config.acts_as
                  xml["t"].ExchangeImpersonation do
                    xml["t"].ConnectingSID do
                      xml["t"].PrimarySmtpAddress Exchanger.config.acts_as
                    end
                  end
                end
              end
            end

            xml.send("soap:Body") do
              xml.ResolveNames("xmlns" => NS["m"], "xmlns:t" => NS["t"], "ReturnFullContactData" => "true") do
                xml.UnresolvedEntry name
              end
            end
          end
        end
      end
    end

    class Response < Operation::Response
      def mailboxes
        to_xml.xpath(".//t:Mailbox", NS).map do |node|
          item_klass = Exchanger.const_get(node.name)
          item_klass.new_from_xml(node)
        end
      end

      def contacts
        to_xml.xpath(".//t:Contact", NS).map do |node|
          item_klass = Exchanger.const_get(node.name)
          item_klass.new_from_xml(node)
        end
      end
    end
  end
end