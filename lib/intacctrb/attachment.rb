module IntacctRB
  class Attachment < IntacctRB::Base
    attr_accessor :customer_data
    define_hook :custom_bill_fields, :bill_item_fields

    def create
      return false if object.intacct_system_id.present?

      send_xml('create') do |xml|
        xml.function(controlid: "f1") {
          xml.create_supdoc {
            attachment_xml xml
          }
        }
      end

      if !successful?
        raise IntacctRB::Exceptions::Attachment.new(response.at('//error//description2'))
      end

      object.intacct_id
    end

    def get_date_at(xpath, object)
      year = object.at("#{xpath}/year").content
      month = object.at("#{xpath}/month").content
      day = object.at("#{xpath}/day").content
      if [year,month,day].any?(&:empty?)
        nil
      else
        Date.new(year.to_i,month.to_i,day.to_i)
      end
    end

    def attachment_xml xml
      xml.supdocid object.supdoc_id
      xml.supdocfoldername object.folder_name
      xml.attachments {
        object.attachments.each do |attachment|
          xml.attachment {
            xml.attachmentname attachment.name
            xml.attachmenttype attachment.type
            xml.attachmentdata attachment.data
          }
        end
      }
    end

    def set_intacct_system_id
      object.intacct_system_id = intacct_object_id
    end

    def delete_intacct_system_id
      object.intacct_system_id = nil
    end

    def delete_intacct_key
      object.intacct_key = nil
    end
  end
end
