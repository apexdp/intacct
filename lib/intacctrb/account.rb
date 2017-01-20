module IntacctRB
  class Account < IntacctRB::Base
    def get_list(options = {})
      send_xml('get_list') do |xml|
        xml.function(controlid: "f4") {
          xml.get_list(object: "glaccount", maxitems: (options[:max_items] || 0),
            start: (options[:start] || 0), showprivate:"true") {
            filter_xml(xml, options)
            if options[:fields]
              xml.fields {
                fields.each do |field|
                  xml.field field.to_s
                end
              }
            end
          }
        }
      end

      if successful?
        @data = []
        @response.xpath('//glaccount').each do |account|
          @data << OpenStruct.new({
            id: account.at("glaccountno").content,
            name: account.at("title").content,
            normal_balance: account.at("normalbalance").content,
            account_type: account.at("accounttype").content,
            closing_type: account.at("closingtype").content,
            updated_at: account.at("whenmodified").content,
            status: account.at("status").content
          })
        end
        @data
      else
        false
      end
    end
  end
end
