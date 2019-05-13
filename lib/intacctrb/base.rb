module IntacctRB
  class Base < Struct.new(:object, :current_user)
    include Hooks
    include Hooks::InstanceHooks

    define_hook :after_create, :after_update, :after_delete,
      :after_get, :after_send_xml, :on_error, :before_create

    after_create :set_intacct_id
    after_delete :delete_intacct_id
    after_delete :delete_intacct_key
    after_send_xml :set_date_time

    attr_accessor :response, :data, :sent_xml, :intacct_action

    def initialize *params
      if params[0].is_a? Hash
        json_data = params[0].to_json
        params[0] = JSON.parse(json_data, object_class: OpenStruct)
      end
      params[0] ||= OpenStruct.new()
      super(*params)
    end

    def intacct_id
      object.intacct_id
    end

    private

    def send_xml action
      retry_count = 0
      begin
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
              xml.includewhitespace "false"
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
        IntacctRB.logger.debug xml
        @sent_xml = xml

        url = "https://www.intacct.com/ia/xml/xmlgw.phtml"
        uri = URI(url)
        retry_count += 1
        res = Net::HTTP.post_form(uri, 'xmlrequest' => xml)
        @response = Nokogiri::XML(res.body)
        IntacctRB.logger.debug res.body
        if successful?
          if key = response.at('//result//RECORDNO') || response.at('//result//key')
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
      rescue Net::ReadTimeout => e
        if retry_count <= 3
          IntacctRB.logger.warn "Net::ReadTimeout in IntacctRB; retrying"
          retry
        else
          IntacctRB.logger.error "Net::ReadTimeout in IntacctRB; retries exhausted"
          raise e
        end
      end
    end

    def successful?
      if status = response.at('//result//status') and status.content == "success"
        true
      else
        false
      end
    end

    def return_result(response, data = nil)
      if successful?
        data = OpenStruct.new({result: true, intacct_id: object.intacct_id,
          object: response, data: data})
      else
        data = OpenStruct.new({result: false, intacct_id: object.intacct_id})
        data.errors = []
        response.xpath("//result/errormessage/error").each do |error|
          data.errors << {
            code: error.at("//errorno").content,
            title: error.at("//description").content,
            description: error.at("//description2").content
          }
        end
      end
      data
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

    def filter_xml(xml, options)
      if options[:filters]
        xml.filter {
          options[:filters].each do |filter|
            xml.expression do
              xml.field(filter[:field])
              xml.operator(filter[:operator] || '=')
              xml.value(filter[:value])
            end
          end
        }
      end
    end

    def date_xml(xml, date)
      xml.year date.to_date.strftime("%Y")
      xml.month date.to_date.strftime("%m")
      xml.day date.to_date.strftime("%d")
    end

    def custom_fields_xml(xml, object)
      xml.customfields {
        if object.empower_id
          xml.customfield {
            xml.customfieldname 'empower_id'
            xml.customfieldvalue object.empower_id
          }
        end
        if object.empower_class
          xml.customfield {
            xml.customfieldname 'empower_class'
            xml.customfieldvalue object.empower_class
          }
        end
      }
    end
  end
end
