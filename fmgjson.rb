require "json"
require "net/http"

##########################################################################################################
# Class FmgJson provides abstraction for Ruby programs in setting up connections and executing queries to
# the FMG JSON API, provides session and request ID management as well as error checking and debug options
##########################################################################################################

class FmgJson
  def initialize(host,login,passwd,debug=0)
    @host = host
    @login = login
    @passwd = passwd
    @session = nil
    @debug = debug
    @uri = URI("http://#{@host}/jsonrpc")
    @headers = {'Content-Type' => 'application/json', 'Accept-Encoding' => 'gzip.deflate','Accept'=>'application/json'}
    @id = 1

    ## JSON Action - Login
    data = {:params => [:url => 'sys/login/user', :data => [:passwd => @passwd, :user => @login]], :session => '', :id => @id, :method => 'exec'}

    if debug == 1
      puts '####### JSON REQUEST (Pretty-Format) #######'
      puts JSON.pretty_generate(data)
      puts '############################################'
      puts
    end

    begin
      http = Net::HTTP.new(@uri.host,@uri.port)
      http.set_debug_output($stdout) if debug == 1
      res = http.post(@uri.path,data.to_json,@headers)

      if debug == 1
        puts '######## Result (body) ########'
        puts res.body
        puts '###############################'
        puts
      end

      ## Grab the session ID that was returned and store inside an instance variable so that it can be used in all
      ## future calls within an instance of this class.
      data = JSON.parse(res.body)
      @session = data['session']

      if debug == 1
        puts '####### Session ID ########'
        puts @session
        puts '###########################'
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  def exec(jsonreq, method)
    begin
      if jsonreq.is_a?(Hash)
        @id += 1
        jsonreq[:id] = @id
        jsonreq[:session] = @session
        jsonreq[:method] = method

        if @debug == 1
          puts '#### Exec JSON (Pretty-Format)'
          puts JSON.pretty_generate(jsonreq)
        end

        http = Net::HTTP.new(@uri.host,@uri.port)
        http.set_debug_output($stdout) if @debug == 1
        res = http.post(@uri.path,jsonreq.to_json)
        return JSON.parse(res.body)
      else
        raise ArgumentError.new('JSON request data must be passed in the form of a hash')
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end


private
#################################################################################
## fmg_rescue
##
## Provides style for rescue and error messaging
#################################################################################
    def fmg_rescue(error)
      puts '### Error! ################################################################################################'
      puts error.message
      puts error.backtrace.inspect
      puts '###########################################################################################################'
      puts ''
    end

end