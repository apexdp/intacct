module IntacctRB
  class Base < Struct.new(:object, :current_user)
    include Hooks
    include Hooks::InstanceHooks

    define_hook :after_create, :after_update, :after_delete,
      :after_get, :after_send_xml, :on_error, :before_create

    after_create :set_intacct_system_id
    after_delete :delete_intacct_system_id
    after_delete :delete_intacct_key
    after_send_xml :set_date_time

    attr_accessor :response, :data, :sent_xml, :intacct_action

    def initialize *params
      params[0] = OpenStruct.new(params[0]) if params[0].is_a? Hash
      super(*params)
    end

    private

    def send_xml action
      @intacct_action = action.to_s
      run_hook :"before_#{intacct_action}" if action=="create"

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.request {
          xml.control {
            xml.senderid IntacctRB.xml_sender_id
            xml.password IntacctRB.xml_password
            xml.controlid "INVOICE XML"
            xml.uniqueid "false"
            xml.dtdversion "3.0"
          }
          xml.operation(transaction: "false") {
            xml.authentication {
              xml.login {
                xml.userid IntacctRB.app_user_id
                xml.companyid IntacctRB.app_company_id
                xml.password IntacctRB.app_password
              }
            }
            xml.content {
              yield xml
            }
          }
        }
      end

      xml = builder.doc.root.to_xml
      puts xml
      @sent_xml = xml

      url = "https://www.intacct.com/ia/xml/xmlgw.phtml"
      uri = URI(url)

      res = Net::HTTP.post_form(uri, 'xmlrequest' => xml)
      @response = Nokogiri::XML(res.body)
      puts res.body
      if successful?
        if key = response.at('//result//recordno')
          set_intacct_id key.content if object
        end

        if intacct_action
          run_hook :after_send_xml, intacct_action
          #run_hook :"after_#{intacct_action}"
        end
      else
        run_hook :on_error
      end

      @response
    end

    def successful?
      if status = response.at('//result//status') and status.content == "success"
        true
      else
        false
      end
    end

    %w(invoice bill vendor customer journal_entry).each do |type|
      define_method "intacct_#{type}_prefix" do
        IntacctRB.send("#{type}_prefix")
      end
    end

    def set_intacct_id id
      object.intacct_id = id
    end

    def delete_intacct_id
      object.intacct_id = nil if object.respond_to? :intacct_id
    end

    def set_date_time type
      if %w(create update delete).include? type
        if object.respond_to? :"intacct_#{type}d_at"
          object.send("intacct_#{type}d_at=", DateTime.now)
        end
      end
    end
  end
end
