module IntacctRB
  class Employee < IntacctRB::Base
    def create
      send_xml('create') do |xml|
        xml.function(controlid: "1") {
          xml.send("create_employee") {
            employee_xml(xml)
          }
        }
      end

      successful?
    end

    def get *fields
      #return false unless object.intacct_system_id.present?

      fields = [
        :employeeid,
        :personalinfo
      ] if fields.empty?

      send_xml('get') do |xml|
        xml.function(controlid: "f4") {
          xml.get(object: "employee", key: "intacct_system_id") {
            xml.fields {
              fields.each do |field|
                xml.field field.to_s
              end
            }
          }
        }
      end

      if successful?
        @data = OpenStruct.new({
          id: response.at("//employee//employeeid").content,
          name: response.at("//employee//personalinfo//contactname").content
        })
      end

      successful?
    end

    def get_list *fields
      #return false unless object.intacct_system_id.present?

      fields = [
        :customerid,
        :name,
        :termname
      ] if fields.empty?

      send_xml('get_list') do |xml|
        xml.function(controlid: "f4") {
          xml.get_list(object: "employee", maxitems: "10", showprivate:"false") {
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
      puts response
    end

    def update updated_employee = false
      @object = updated_employee if updated_employee
      return false unless object.intacct_system_id.present?

      send_xml('update') do |xml|
        xml.function(controlid: "1") {
          xml.update_employee(employeeid: intacct_system_id) {
            xml.name object.name
            xml.comments
            xml.status "active"
          }
        }
      end

      successful?
    end

    def delete
      return false unless object.intacct_system_id.present?

      @response = send_xml('delete') do |xml|
        xml.function(controlid: "1") {
          xml.delete_customer(employeeid: intacct_system_id)
        }
      end

      successful?
    end

    def employee_xml xml
      xml.employee {
        xml.employeeid object.intacct_id if object.intacct_id
        xml.title object.title if object.title
        xml.personalinfo {
          xml.contactname object.name
        }
        xml.locationid object.location_id if object.location_id
        xml.departmentid object.departmentid if object.department_id
        xml.classid object.classid if object.department_id
        xml.supervisorid object.supervisorid if object.department_id
        xml.birthdate date_string(object.birthdate) if object.birthdate
        xml.startdate date_string(object.startdate) if object.startdate
        xml.enddate date_string(object.enddate) if object.enddate
        xml.terminationtype object.terminationtype if object.terminationtype
        xml.employeetype object.employeetype if object.employeetype
        xml.gender object.gender if object.gender
        xml.status object.status if object.status
        xml.currency object.currency if object.currency
      }
    end
  end
end
