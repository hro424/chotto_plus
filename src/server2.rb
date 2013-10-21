require 'webrick'
require 'json'
# require 'serialport'
 
include WEBrick

$serial_port = '/dev/ttyS4'
$ip_address  = 'localhost'

$client_body = File.read("client.html")

def start_webrick(config = {})
  config.update(:Port => 9955)     
  server = HTTPServer.new(config)
  yield server if block_given?
  ['INT', 'TERM'].each {|signal| 
    trap(signal) {
      server.shutdown
      # user_shutdown
    }
  }
  # user_start
  server.start
end

def set_message( body, mes )
  body.gsub("localhost", $ip_address).gsub("MESSAGE_HERE", mes )
end

class RestServlet < HTTPServlet::AbstractServlet
  def do_GET(req, resp)
    s = req.query
    status = s["status"]
    if ( status == "start")
      status
      # $sp.write "1"
      resp.body = set_message( $client_body, "ok! sp.write 1" )
    elsif ( status == "stop")
      status
      # $sp.write "0"
      resp.body = set_message( $client_body, "ok! sp.write 0" )
    else
      resp.body = set_message( $client_body, "error query( or 1st access )" )
    end
  end
end

$serial_baudrate = 115200
$serial_databit = 8
$serial_stopbit = 1
$serial_paritycheck = 0
$serial_delimeter = "\n"

def user_start
  if (ARGV[0])
    $serial_port = ARGV[0]
  end
#   $sp = SerialPort.new($serial_port, $serial_baudrate, $serial_databit,
#                        $serial_stopbit, $serial_paritycheck)
#   $sp.read_timeout = 1000
end

def user_shutdown
  $sp.close
end
 
start_webrick { |server|
  server.mount('/', RestServlet)
}
