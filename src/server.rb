require 'webrick'
require 'json'
require 'serialport'
 
include WEBrick
 
def start_webrick(config = {})
  config.update(:Port => 9955)     
  server = HTTPServer.new(config)
  yield server if block_given?
  ['INT', 'TERM'].each {|signal| 
    trap(signal) {
      server.shutdown
      user_shutdown
    }
  }
  user_start
  server.start
end
 
class RestServlet < HTTPServlet::AbstractServlet
  def do_GET(req, resp)
      # Split the path into pieces, getting rid of the first slash
      path = req.path[1..-1].split('/')
      raise HTTPStatus::NotFound if !RestServiceModule.const_defined?(path[0])
      response_class = RestServiceModule.const_get(path[0])
       
      if response_class and response_class.is_a?(Class)
        # There was a method given
        if path[1]
          response_method = path[1].to_sym
          # Make sure the method exists in the class
          raise HTTPStatus::NotFound if !response_class.respond_to?(response_method)
          # Remaining path segments get passed in as arguments to the method
          if path.length > 2
            resp.body = response_class.send(response_method, path[2..-1])
          else
            resp.body = response_class.send(response_method)
          end
          raise HTTPStatus::OK
        # No method was given, so check for an "index" method instead
        else
          raise HTTPStatus::NotFound if !response_class.respond_to?(:index)
          resp.body = response_class.send(:index)
          raise HTTPStatus::OK
        end
      else
        raise HTTPStatus::NotFound
      end
  end

  def do_PUT(req, resp)
      # Split the path into pieces, getting rid of the first slash
      path = req.path[1..-1].split('/')
      raise HTTPStatus::NotFound if !RestServiceModule.const_defined?(path[0])
      response_class = RestServiceModule.const_get(path[0])
       
      if response_class and response_class.is_a?(Class)
        # There was a method given
        if path[1]
          response_method = path[1].to_sym
          # Make sure the method exists in the class
          raise HTTPStatus::NotFound if !response_class.respond_to?(response_method)
          resp.body = response_class.send(response_method, req.body)
          raise HTTPStatus::OK
        # No method was given, so check for an "index" method instead
        else
          raise HTTPStatus::NotFound if !response_class.respond_to?(:index)
          resp.body = response_class.send(:index)
          raise HTTPStatus::OK
        end
      else
        raise HTTPStatus::NotFound
      end
  end

end
 
module RestServiceModule
  class RunningService
    @@stat = "stop"

    def self.index(args = nil)
      return JSON.generate({:data => 'Hello World'})
    end

    def self.status(args = nil)
      if args
        dict = JSON.parse(args)
        @@stat = dict["status"]
        if (@@stat == "start")
          $sp.write "1"
        elsif (@@stat == "stop")
          $sp.write "0"
        end
        return ""
      else
        return JSON.generate({:status => @@stat})
      end
    end
  end
end

$serial_port = '/dev/tty.usbmodemfa211'
$serial_baudrate = 115200
$serial_databit = 8
$serial_stopbit = 1
$serial_paritycheck = 0
$serial_delimeter = "\n"

def user_start
  if (ARGV[0])
    $serial_port = ARGV[0]
  end
  $sp = SerialPort.new($serial_port, $serial_baudrate, $serial_databit,
                       $serial_stopbit, $serial_paritycheck)
  $sp.read_timeout = 1000
end

def user_shutdown
  $sp.close
end
 
start_webrick { |server|
  server.mount('/', RestServlet)
}

