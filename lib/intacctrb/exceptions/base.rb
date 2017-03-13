module IntacctRB
  module Exceptions
    class Base < StandardError
      def initialize(message)
        error_class = self.class.to_s
        error_class = error_class.split('::').last if error_class.index('::')
        error_message = "#{error_class} error: "
        error_message += message || 'Unknown'
        super(error_message)
      end
    end
  end
end
