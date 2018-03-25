module IntacctRB
  class Contact < IntacctRB::Base
    def create
      response = send_xml('create') do |xml|
        xml.function(controlid: "1") {
          xml.send("create") {
            contact_xml(xml)
          }
        }
      end

      return_result(response)
    end

    def get_by_name(options = {})
      # return false unless object.intacct_id.present?

      options[:fields] = [
        :contactid,
        :contactname
      ] if options[:fields].nil?

      response = send_xml('get') do |xml|
        xml.function(controlid: "f4") {
          xml.readByName {
            xml.object 'contact'
            xml.keys object.try(:name) || options[:name]
            xml.fields '*'
          }
        }
      end

      if successful?
        data = OpenStruct.new({
          id: response.at("//contact/RECORDNO").try(:content),
          name: response.at("//contact/CONTACTNAME").try(:content)
        })
      end

      return_result(response, data)
    end

    def get(options = {})
      # return false unless object.intacct_id.present?

      options[:fields] = [
        :contactid,
        :contactname
      ] if options[:fields].nil?

      response = send_xml('get') do |xml|
        xml.function(controlid: "f4") {
          xml.read {
            xml.object 'contact'
            xml.keys object.try(:intacct_id) || options[:intacct_id]
            xml.fields '*'
          }
        }
      end

      if successful?
        data = OpenStruct.new({
          id: response.at("//contact/RECORDNO").try(:content),
          name: response.at("//contact/CONTACTNAME").try(:content)
        })
      end

      return_result(response, data)
    end

    def get_list *fields
      #return false unless object.intacct_id.present?

      fields = [
        :customerid,
        :name,
        :termname
      ] if fields.empty?

      response = send_xml('get_list') do |xml|
        xml.function(controlid: "f4") {
          xml.get_list(object: "contact", maxitems: "10", showprivate:"false") {
            # xml.fields {
            #   fields.each do |field|
            #     xml.field field.to_s
            #   end
            # }
          }
        }
      end

      # if successful?
      #   @data = OpenStruct.new({
      #     id: response.at("//customer//customerid").content,
      #     name: response.at("//customer//name").content,
      #     termname: response.at("//customer//termname").content
      #   })
      # end
      #
      # successful?
      return_result(response)
    end

    def update updated_contact = false
      @object = updated_contact if updated_contact
      return false unless object.intacct_id.present?

      response = send_xml('update') do |xml|
        xml.function(controlid: "1") {
          xml.update {
            contact_xml(xml, true)
          }
        }
      end

      return_result(response)
    end

    def delete
      return false unless object.intacct_id.present?

      response = send_xml('delete') do |xml|
        xml.function(controlid: "1") {
          xml.delete_contact(contactid: intacct_id)
        }
      end

      return_result(response)
    end

    def contact_xml(xml, is_update = false)
      xml.contact {
        xml.recordno object.intacct_id if object.intacct_id
        xml.contactname object.name if object.name
        xml.printas object.name if object.name
        # COMPANYNAME	Optional	string	Company name
        # TAXABLE	Optional	boolean	Taxable. Use false for No, true for Yes. (Default: true)
        # TAXGROUP	Optional	string	Contact tax group name
        # PREFIX	Optional	string	Prefix
        # FIRSTNAME	Optional	string	First name
        # LASTNAME	Optional	string	Last name
        # INITIAL	Optional	string	Middle name
        # PHONE1	Optional	string	Primary phone number
        # PHONE2	Optional	string	Secondary phone number
        # CELLPHONE	Optional	string	Cellular phone number
        # PAGER	Optional	string	Pager number
        # FAX	Optional	string	Fax number
        # EMAIL1	Optional	string	Primary email address
        # EMAIL2	Optional	string	Secondary email address
        # URL1	Optional	string	Primary URL
        # URL2	Optional	string	Secondary URL
        # STATUS	Optional	string	Status. Use active for Active or inactive for Inactive (Default: active)
        # MAILADDRESS	Optional	object	Mail address
      }
    end
  end
end
