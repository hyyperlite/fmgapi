require 'savon'
require 'date'
require 'time'

######################################################################################################################
### Nick Petersen (2014)
######################################################################################################################
### This class provides simplified interaction with the Fortinet FortiManager XML API.  Various class methods
### are implemented to abstract the complexity in executing FMG XML API queries.
###
### Uses Savon Gem for SOAP query/response handling.  Most Savon arguments are pre-set with values that are known
### to work with FortiManager and FortiAnalyzer.
###
### This has been tested against FortiManager/FortiAnalyzer 5.0.7
###
### Usage example:
###  fmg1 = FmgApi.new('wsdl_file_location', 'url', 'namespace', 'userid', 'passwd')
###  result = fmg1.get_adom_list
###
### In most cases if not all, arguments to the method are passed in as hash key => value instead of traditional
### arugments passed in order.   This is because many methods many optional arguments and even required arguments
### can be left out if other required arguments are used.
### when specifying hash valudes to a method, use the following syntax:
###
### Single argument passed:    method_name(argument_key => 'argument_value')
### Multiple arguments passed: method_name({argument1_key => 'argument1_value', argument2_key => 'agrument2_value'})
######################################################################################################################

class FmgApi
  def initialize(wsdl,endpoint,namespace,userid, passwd)
    @wsdl = wsdl
    @endpoint = endpoint
    @namespace = namespace
    @userid = userid
    @passwd = passwd

    #create a savon client for the service
    @client = Savon.client(
        wsdl: @wsdl,
        endpoint: @endpoint,   #used if you don't have wsdl  (or possibly if only have local wsdl file?)
        namespace: @namespace,   #used if you don't have wsdl
        ##
        ############ SSL Attributes ##########
        ssl_verify_mode: :none,        # verify or not SSL Certificate
        # ssl_version: :SSLv3,          # or one of [:TLSv1, :SSLv2]
        # ssl_cert_file:  "path/client_cert.pem",
        # ssl_cert_key_file: "path/client_key.pem",
        # ssl_cert_key_file:  "path/ca_cert.pem",        #CA certificate file to use
        # ssl_cert_key_password: "secret",
        ##
        ############ SOAP Protocol Attributes
        ##
        # soap_header: { "token" => "secret" }, #if you need to add customer XML to the SOAP header.  useful for auth token?
        # soap_version: 2,       #defaults to SOAP 1.1
        ##
        ############ MISC Attributes
        ##
        pretty_print_xml: true,        # print the request and response XML in logs in pretty
    # headers: {"Authentication" => "secret", "etc" => "etc"},
     #open_timeout: 5,           # in seconds
     #read_timeout: 5,           # in seconds
    ##
    ########## LOGGING Attributes ##############
    ##
    # log: false,
    # logger: rails.logger,  #by default will log to $stdout (ruby's default logger)
    # log_level: :info,  #one of [:debug, :info, :warn, :error, :fatal]
    # filters: [:password],  #sensitive info can be filtered from logs.  specifies which arguments to filter from logs
    ##
    ########### RESPONSE Attributes ##############
    ##
    # strip_namespace: false    # default is to strip namespace identifiers from the response
    # convert_response_tags_to: upcase  # value is name of a proc that takes an action you've created
    )

    @authmsg = {:servicePass => {:userID => @userid, :password => @passwd}}
  end






  ################################################################################################
  ## Method: get_adom_by_name (Returns Hash)
  ##
  ## Retreives ADOM info for a specified ADOM name and returns a hash of  attributes
  ##
  ## Usage:
  ##  get_adom_by_name() OR  # Note: If no parameter is passed defaults to 'root'
  ##  get_adom_by_name(:adom => 'adom_name')
  ################################################################################################
  def get_adom_by_name(opts = {})
    querymsg = @authmsg
    querymsg[:names] = opts[:adom] ? opts[:adom] : 'root'

    begin
      exec_soap_query(:get_adoms,querymsg,:get_adoms_response,:adom_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #############################################################################################
  ## Method: get_adom_by_oid  (Returns Hash)
  ##
  ## Retrieves VDOM info for a specified VDOM ID and returns a hash of VDOM attributes
  ## Usage:
  ##  get_adom_by_oid() OR  # If no parameter is passed, defaults to OID=3 (which should be root adom)]
  ##  get_adom_by_oid(:adom_id => 'adom_oid')
  #############################################################################################
  def get_adom_by_oid(opts = {})
    querymsg = @authmsg
    querymsg[:adom_ids] = opts[:adom_id] ? opts[:adom_id] : '3'

    begin
      exec_soap_query(:get_adoms,querymsg,:get_adoms_response,:adom_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################
  ## Method: get_adom_list  (Returns Array of Hashes  (unless not in ADOM mode then potentially just Hash))
  ##
  ## Returns ADOM details as hash of hashes with top key based on OID
  ##
  ## Usage:
  ##  get_adom_list()
  #####################################################################
  def get_adom_list
    querymsg = @authmsg

    begin
      exec_soap_query(:get_adom_list,querymsg,:get_adom_list_response,:adom_info)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_config  (Returns Hash)
  ##
  ## Retrieves a specific configuration revision
  ##
  ## Usage:
  ##  get_config({:revision_number => 'rev-number', :serial_number => 'serial-number'}) OR
  ##  get_config({:revision_number => 'rev-number', :dev_id => 'device-id'})
  ## Optional arguments:
  ##  :adom   #ADOM name.  Defaults to root if not supplied
  #####################################################################################################################
  def get_config (opts={})
    querymsg = @authmsg
    querymsg[:adom] = opts[:adom] if opts[:adom]

    begin
      if opts[:serial_number] && opts[:revision_number]
        querymsg[:serial_number] = opts[:serial_number]
        querymsg[:revision_number] = opts[:revision_number]
      elsif opts[:dev_id] && opts[:revision_number]
        querymsg[:dev_id] = opts[:dev_id]
        querymsg[:revision_number] = opts[:revision_number]
      else
        raise ArgumentError.new('Must provide arguments for method get_config-> :revision_number AND (:dev_name OR :dev_id)')
      end
      exec_soap_query(:get_config,querymsg,:get_config_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_config_revision_history  (Returns Hash or Array of Hashes)
  ##
  ## Retrieves list of configurations from Revision History
  ##
  ## Usage:
  ##  get_config_revision_history(:serial_number => 'serial-number')  OR
  ##  get_config_revision_history(:dev_id => 'device-id)
  ## Optional arguments:
  ##  :checkin_user
  ##  :min_checkin_date
  ##  :max_checkin_date,  #if min and max are both passed and max occurs before min then no date filter will be used
  ##  :min_revision_number
  ##  :max_revision_number  #if min and max are both passed and min > max then no revision number filter will be used
  #####################################################################################################################
  def get_config_revision_history (opts={})
    querymsg = @authmsg
    querymsg[:checkin_user] = opts[:checkin_user] if opts[:checkin_user]


    ### Validate Min/Max checkin dates to verify they are properly formated for use by FMG and verify that if both
    ### min and max checkin dates have been provided that the min date comes before the max.  If not, execute without
    ### using checkin date filters.
    if opts[:min_checkin_date] && opts[:max_checkin_date]
      date_min_checkin = DateTime.parse(opts[:min_checkin_date]).strftime('%Y-%m-%dT%H:%M:%S') rescue false
      date_max_checkin = DateTime.parse(opts[:max_checkin_date]).strftime('%Y-%m-%dT%H:%M:%S') rescue false
      if date_max_checkin && date_min_checkin
        if date_max_checkin >= date_min_checkin
          querymsg[:min_checkin_date] = date_min_checkin
          querymsg[:max_checkin_date] = date_max_checkin
        else
          puts __method__.to_s  + ': :max_checkin_date provided comes before the :min_checkin_date provided, executing without min/max checkin-date filter'
        end
      else
        puts __method__.to_s  + ': Invalid date formats provided in attributes :max_checkin_date or :min_checkin_date, executing without min/max checkin-date filter'
      end
    elsif opts[:min_checkin_date]
      date_min_checkin = DateTime.parse(opts[:min_checkin_date]).strftime('%Y-%m-%dT%H:%M:%S') rescue false
      querymsg[:min_checkin_date] = date_min_checkin if date_min_checkin
    elsif opts[:max_checkin_date]
      date_max_checkin = DateTime.parse(opts[:max_checkin_date]).strftime('%Y-%m-%dT%H:%M:%S') rescue false
      querymsg[:max_checkin_date] = date_max_checkin if date_max_checkin
    end

    ### Validate that if min and max revision numbers are both passed that min is less than max or don't use revision
    ### number filtering in the search.
    if opts[:min_revision_number] && opts[:max_revision_number]
      if opts[:max_revision_number] >= opts[:min_revision_number]
        querymsg[:min_revision_number] = opts[:min_revision_number]
        querymsg[:max_revision_number] = opts[:max_revision_number]
      else
        puts __method__.to_s  + ':max_revision_number provided is less than :min_revision_number provided.  Executing without min/max revision number filter'
      end
    elsif opts[:min_revision_number] then querymsg[:min_revision_number] = opts[:min_revision_number]
    elsif opts[:max_revision_number] then querymsg[:max_revision_number] = opts[:max_revision_number]
    end

    ## Apply the rest of the filters and execute API call by calling exec_soap_query
    begin
      if opts[:serial_number]
        querymsg[:serial_number] = opts[:serial_number]
      elsif opts[:dev_id]
        querymsg[:dev_id] = opts[:dev_id]
      else
        raise ArgumentError.new('Must provide arguments for method get_config_revision_history-> :serial_number OR :dev_id')
      end
      exec_soap_query(:get_config_revision_history,querymsg,:get_config_revision_history_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_device (Returns Hash)
  ##
  ## Retrieves a list of vdoms or with arguments a vdom for a specific device id or device name.
  ##
  ## Usage:
  ##  get_device(:serial_number => 'serial-number')  OR
  ##  get_device(:dev_id => 'device-id')
  #####################################################################################################################
  def get_device (opts={})
    querymsg = @authmsg

    begin
      if opts[:serial_number]
        querymsg[:serial_numbers] = opts[:serial_number]
      elsif opts[:dev_id]
        querymsg[:dev_ids] = opts[:dev_id]
      else
        raise ArgumentError.new('Must provide arguments for method get_device_vdom_list->  :serial_number or :dev_id')
      end
      exec_soap_query(:get_devices,querymsg,:get_devices_response,:device_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end

  end

  #####################################################################################################################
  ## Method: get_device_license_list  (Returns Hash or Array of Hashes)
  ##
  ## Retrieves a license info for managed devices
  ##
  ## Usage:
  ##  get_device_license_list()
  #####################################################################################################################
  def get_device_license_list
    querymsg = @authmsg

    begin
      exec_soap_query(:get_device_license_list,querymsg,:get_device_license_list_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_device_list (Returns Hash or Array of Hashes)
  ##
  ## Retrieves a list of managed devices from FMG, returns hash, or hash of hashes with primary key or
  ## on serial_number.
  ##
  ## Usage:
  ##  get_device_list() OR  #if no arguments are passed defaults to root ADOM
  ##  get_device_list(:adom => 'adom-name')
  #####################################################################################################################
  def get_device_list (opts={})
    querymsg = @authmsg
    querymsg[:adom] = opts[:adom] ? opts[:adom] : 'root'
    querymsg[:detail] = 1

    begin
      exec_soap_query(:get_device_list,querymsg,:get_device_list_response,:device_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_device_vdom_list (Returns Hash or Array of Hashes)
  ##
  ## Retrieves a list of vdoms or with arguments a vdom for a specific device id or device name.
  ##
  ## Usage:
  ##  get_device_vdom_list(:dev_name => 'device-name')  OR
  ##  get_device_vdom_list(:dev_id => 'device-id')
  #####################################################################################################################
  def get_device_vdom_list (opts={})
    querymsg = @authmsg

    begin
      if opts[:dev_name]
        querymsg[:dev_name] = opts[:dev_name]
      elsif opts[:dev_id]
        querymsg[:dev_iD] = opts[:dev_id]
      else
        raise ArgumentError.new('Must provide arguments for method get_device_vdom_list->  :dev_name or :dev_id')
      end
      exec_soap_query(:get_device_vdom_list,querymsg,:get_device_vdom_list_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_faz_archive
  ## Retrieves specified archive file.  (File name is required and can be retrieved from associated FAZ log
  ## incident serial number)
  ##
  ## Usage:
  ##  get_faz_archive({:adom => 'adom-name', :dev_id => 'serial-number', :file_name => 'filename', :type => 'type'})
  ##
  ## Please note that in most cases dev_id means dev_id but for this query you must supply the serial number as
  ## the dev_id.
  ##
  ## Types are as follows:   1-Web, 2-Email, 3-FTP, 4-IM, 5-Quarantine, 6-IPS
  ##
  ## Also note, that although the WSDL claims that this query supports tar and gzip compression options I have not
  ## been able to get either of those to work.  if you specify tar the file is sent without compression (same as if
  ## you didn't specify) if you specify gzip it also requires to specify a password but if you do the query will
  ## always hang.
  #####################################################################################################################
  def get_faz_archive (opts={})
    querymsg = @authmsg
    #querymsg[:compression] = 'gzip'
    #querymsg[:zip_password] = 'test'

    begin
      if opts[:adom] && opts[:dev_id] && opts[:file_name] && opts[:type]
        querymsg[:adom] = opts[:adom]
        querymsg[:dev_id] = opts[:dev_id]
        querymsg[:file_name] = opts[:file_name]
        querymsg[:type] = opts[:type]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :adom, :dev_id, :file_name, :type')
      end
      exec_soap_query(:get_faz_archive,querymsg,:get_faz_archive_response,:file_list)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_faz_config  (Returns Nori::StringWithAttributes)   resulting string contains config
  ## Retrieves configuration of FortiAnalyzer or FortiAnalyzer.
  ##
  ## Note:
  ##
  ## This class uses the SAVON GEM for SOAP/XML processing.  There is a bug in SAVON where it removes some of
  ## the whitespace charactiers including \n from the body elements of the request upon processing.   This causes
  ## the config file returned in this query to be mal-formatted.  I have submitted a bug report to the SAVON team
  ## via GITHUB.  They have responded that this will be fixed.  You can see the bug submission at:
  ## https://github.com/savonrb/savon/issues/574#issuecomment-42635095.   In the mean time, I have added some regex
  ## processing code to resolve the returned query so it is at least usable, however this has only been limitedly
  ## tested on a few configurations.
  ##
  ## Usage:
  ##  get_faz_config()
  #####################################################################################################################
  def get_faz_config
    querymsg = @authmsg

    begin
      result = exec_soap_query(:get_faz_config,querymsg,:get_faz_config_response,:config)
      # The following code is hopefully temporary.  Returned results from SAVON have much of whitespace especially
      # \n removed which causes the returned config to not work on FAZ/FMG if applied.  Please see notes in method
      # documentation above.
      result = result.gsub(/\s{2,}/,"\n")
      result = result.gsub(/([0-9a-zA-Z])(end)/, "\\1 \n\\2\n")
      result = result.gsub(/(end)([0-9a-zA-Z])/, "\\1 \n\\2\n")
      result = result.gsub(/([0-9])(config)/, "\\1\n\\2")
      return result
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end
  alias :get_fmg_config :get_faz_config

  #####################################################################################################################
  ## Method: get_faz_generated_report
  ##
  ##                      **************** Not Working ************************
  ##
  ## Usage:
  ##  get_faz_generated_report({:adom => 'adom_name', :dev_id => 'device_id, :file_name => 'filename', :type => 'type'})
  #####################################################################################################################
  def get_faz_generated_report (opts={})
    querymsg = @authmsg
    querymsg[:adom] = 'root'
    querymsg[:report_date] = '2014-04-25T14:36:05+00:00'
    querymsg[:report_name] = 'S-10002_t10002-Bandwidth and Applications Report-2014-04-25-0936'
    #querymsg[:report_name] = 'Bandwidth and Applications Report'
    #querymsg[:compression] = 'tar'

    exec_soap_query(:get_faz_generated_report,querymsg,:get_faz_generated_report_response,:return)

    #begin
    #  if opts.empty?
    #    raise ArgumentError.new('Must provide required arguments for method: :adom, :dev_id, :file_name, :type')
    #  else
    #    if opts.has_key?(:adom) && opts.has_key?(:report_date) && opts.has_key?(:report_name)
    #      querymsg.merge!(opts)
    #      result = exec_soap_query(:get_faz_generated_report,querymsg,:get_faz_generated_report_response,:return)
    #    end
    #  end
    #rescue Exception => e
    #  fmg_rescue(e)
    #  return e
    #end
  end

  #####################################################################################################################
  ## Method: get_group_list (Returns Hash or Array of Hashes)
  ##
  ## Retrieves list of groups from FMG/FAZ.  Optionally can specify an ADOM in the passed arguments.  If no ADOM
  ## is specified then it will default to root ADOM.
  ##
  ## Usage:
  ##  get_group_list() OR
  ##  get_group_list (:adom => 'adom_name')
  #####################################################################################################################
  def get_group_list(opts={})
    querymsg = @authmsg
    querymsg[:detail] = 1
    querymsg[:adom] = opts[:adom] ? opts[:adom] : 'root'

    begin
      exec_soap_query(:get_group_list,querymsg,:get_group_list_response,:group_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_groups (Returns Hash or Array of Hashes)
  ##
  ## Retrieves list of groups from FMG/FAZ.  Must specify either 'name' of group or 'group_id'.
  ##
  ## Usage:
  ##  get_group(:name => 'group_name')  OR
  ##  get_group(:groupid => 'group_id')
  ##
  ## Optional Arguments:
  ##  :adom => 'adom_name'
  #####################################################################################################################
  def get_group(opts={})
    querymsg = @authmsg
    querymsg[:adom] = opts[:adom] ? opts[:adom] : 'root'

    begin
      if opts[:name] || opts[:groupid]
        querymsg[:names] = opts[:name] if opts[:name]
        querymsg[:grp_ids] = opts[:grp_id] if opts[:grp_id]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :name OR :grp_id')
      end
      exec_soap_query(:get_groups,querymsg,:get_groups_response,:group_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_instlog (Returns Hash or Array of Hashes)
  ##
  ## Retrieves installation logs for specified device
  ##
  ## Usage:
  ##  get_instlog(:dev_id => 'device_id')  OR
  ##  get_group(:serial_number=> 'serial_number')
  ##
  ## Optional agruments:
  ##  :task_id
  #####################################################################################################################
  def get_instlog(opts={})
    querymsg = @authmsg
    querymsg[:task_id] = opts[:task_id] if opts[:task_id]

    begin
      if opts[:dev_id] || opts[:serial_number]
        querymsg[:dev_id] = opts[:dev_id] if opts[:dev_id]
        querymsg[:serial_number] = opts[:serial_number] if opts[:serial_number]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :dev_id or :serial_number')
      end
      exec_soap_query(:get_instlog,querymsg,:get_instlog_response,:inst_log)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_package_list (Returns Hash or Array of Hashes)
  ##
  ## Retrieves policy package list.  Option to specify an ADOM or it defaults to root ADOM.
  ##
  ## Usage:
  ##  get_package_list()
  ##
  ## Optional arguments:
  ##  :adom
  #####################################################################################################################
  def get_package_list(opts={})
    querymsg = @authmsg
    querymsg[:adom] = opts[:adom] ? opts[:adom] : 'root'

    begin
      exec_soap_query(:get_package_list,querymsg,:get_package_list_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_script (Returns Hash)
  ##
  ## Retrieves script details.
  ##
  ## Usage:
  ##  get_script(:script_name => 'script_name')
  #####################################################################################################################
  def get_script(opts={})
    querymsg = @authmsg

    if opts[:script_name]
      querymsg[:name] = opts[:script_name]
    else
      raise ArgumentError.new('Must provide required arguments for method-> :dev_id or :serial_number')
    end

    begin
      exec_soap_query(:get_script,querymsg,:get_script_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_script_log (Returns Hash)
  ##
  ## Retrieves script log
  ##
  ## Usage:
  ##  get_script_log({:script_name => 'script_name', :dev_id => 'device_id'}) OR
  ##  get script_log({:script_name => 'script_name, :serial_number => 'serial_number})
  #####################################################################################################################
  def get_script_log(opts={})
    querymsg = @authmsg

    begin
      if opts[:script_name] && opts[:dev_id]
        querymsg[:script_name] = opts[:script_name]
        querymsg[:dev_id] = opts[:dev_id]
      elsif opts[:script_name] && opts[:serial_number]
        querymsg[:serial_number] = opts[:serial_number]
      else
        raise ArgumentError.new('Must provide required arguments for method: (:script_name & :dev_id ) or (:script_name & :serial_number)')
      end
      exec_soap_query(:get_script_log,querymsg,:get_script_log_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_script_log_summary (Returns Hash)
  ##
  ## Retrieves summary of executed scripts for a specific device
  ##
  ## Usage:
  ##  get_script_log_summary(:dev_id => 'device_id') OR
  ##  get script_log_summary(:serial_number => 'serial_number)
  ##
  ## Optional arguments:
  ##  :max_logs  # defaults to 1000
  #####################################################################################################################
  def get_script_log_summary(opts={})
    querymsg = @authmsg
    querymsg[:max_logs] = opts[:max_logs] ? opts[:max_logs] : '1000'

    begin
      if opts[:dev_id] && opts[:serial_number]
        raise ArgumentError.new('Must provide required arguments for method-> :script_name OR :serial_number (not both)')
      elsif opts[:dev_id]
        querymsg[:dev_id] = opts[:dev_id]
      elsif opts[:serial_number]
        querymsg[:serial_number] = opts[:serial_number]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :script_name or :serial_number')
      end
      exec_soap_query(:get_script_log_summary,querymsg,:get_script_log_summary_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_system_status (Returns Hash)
  ##
  ## Retrieves system status as has containing system variables and values.
  ##
  ## Usage:
  ##  get_system_status()
  #####################################################################################################################
  def get_system_status
    querymsg = @authmsg

    begin
      exec_soap_query_for_get_sys_status(:get_system_status,querymsg,:get_system_status_response)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_task_detail (Returns Hash)
  ##
  ## Retrieves details of a task
  ##
  ## Usage:
  ##  get_task_detail(:task_id => 'task-id') OR
  ##  get_task_detail({:task_id => 'task-id', adom=> 'adom_name'})   #if ADOM is not provided it defaults to root ADOM
  #####################################################################################################################
  def get_task_detail(opts={})
    querymsg = @authmsg
    querymsg[:adom] = opts[:adom] ? opts[:adom] : 'root'
    
    begin
      if opts[:task_id] then
        querymsg[:task_id] = opts[:task_id]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :task_id')
      end
      exec_soap_query(:get_task_list,querymsg,:get_task_list_response,:task_list)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: import_policy (Returns Nori::StringWithAttributes) returned string contains details of import if success
  ##
  ## Imports a policy from managed device to FMG current config DB for that device.
  ##
  ##  Usage:
  ##   import_policy({:adom_name => 'root', :dev_name => 'MSSP-1', :vdom_name => 'root'}) OR
  ##   import_policy({:adom_id => '3', :dev_id => '234', :vdom_id => '3'}) OR
  ##   import_policy({:adom_name => 'root', :dev_id => '234', :vdom_name => 'root'})
  #####################################################################################################################
  def import_policy(opts={})
    querymsg = @authmsg

    begin
      if opts[:adom_name] && opts[:dev_name] && opts[:vdom_name]
        querymsg[:adom_name] = opts[:adom_name]
        querymsg[:dev_name] = opts[:dev_name]
        querymsg[:vdom_name] = opts[:vdom_name]
      elsif opts[:adom_id] && opts[:dev_id] && opts[:vdom_id]
        querymsg[:adom_oid] = opts[:adom_id]
        querymsg[:dev_id] = opts[:dev_id]
        querymsg[:vdom_id] = opts[:dev_id]
      elsif opts[:adom_name] && opts[:dev_name] && opts[:vdom_id]
        querymsg[:adom_name] = opts[:adom_name]
        querymsg[:dev_name] = opts[:dev_name]
        querymsg[:vdom_id] = opts[:vdom_id]
      elsif opts[:adom_name] && opts[:dev_id] && opts[:vdom_id]
        querymsg[:adom_name] = opts[:adom_name]
        querymsg[:dev_id] = opts[:dev_id]
        querymsg[:vdom_id] = opts[:vdom_id]
      elsif opts[:adom_id] && opts[:dev_name] && opts[:vdom_name]
        querymsg[:adom_oid] = opts[:adom_id]
        querymsg[:dev_name] = opts[:dev_name]
        querymsg[:vdom_name] = opts[:vdom_name]
      elsif opts[:adom_id] && opts[:dev_name] && opts[:vdom_id]
        querymsg[:adom_oid] = opts[:adom_id]
        querymsg[:dev_name] = opts[:dev_name]
        querymsg[:vdom_id] = opts[:vdom_id]
      elsif opts[:adom_oid] && opts[:dev_id] && opts[:vdom_name]
        querymsg[:adom_oid] = opts[:adom_id]
        querymsg[:dev_id] = opts[:dev_id]
        querymsg[:vdom_name] = opts[:vdom_name]
      else
        raise ArgumentError.new('Must provide required arguments for method-> (:adom_id OR :adom_name) AND (:dev_id OR :dev_name) AND (:vdom_id OR :vdom_name)')
      end
     
      exec_soap_query(:import_policy,querymsg,:import_policy_response,:report)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end


  #####################################################################################################################
  ## Method: install_conifg  (Returns Nori::StringWithAttributes)  string contains taskID of associated task
  ##
  ## Installs a policy package to specified device.
  ##  Note that there is no argument validation in this method as there is in most other methods of this class.
  ##
  ## Required arguments:
  ##
  ## Usage:
  ##  install_config({:adom => 'root', :pkgoid => '572', :dev_id => '234'})
  ##
  ## Optional Arguments:
  ##  :rev_name    # revision name of package revision to install.  If not specified installs most recent rev
  ##  :install_validate   # 0 or 1 for false or true.  If not specified defaults to no-validation.
  ##
  #####################################################################################################################
  def install_config(opts={})
    querymsg = @authmsg
    querymsg[:new_rev_name] = opts[:rev_name] if opts[:rev_name]
    querymsg[:install_validate] = opts[:validate] if opts[:validate]

    begin
      if opts[:adom] && opts[:pkgoid] && opts[:dev_id]
        querymsg[:adom] = opts[:adom]
        querymsg[:pkgoid] = opts[:oid]
        querymsg[:dev_id] = opts[:dev_id]
      elsif opts[:adom] && opts[:pkgoid] && opts[:serial_number]
        querymsg[:adom] = opts[:adom]
        querymsg[:pkgoid] = opts[:oid]
        querymsg[:serial_number] = opts[:serial_number]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :adom AND :pkgoid AND (:dev_id OR :serial_number')
      end
      exec_soap_query(:install_config,querymsg,:install_config_response,:task_id)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: list_faz_generated_reports  (Returns Hash or Array of Hashes)
  ##
  ## Retrieves a list of FAZ generated reports stored on FortiAnalyzer or FortiManager.   An ADOM & start/end dates
  ## can be optionally specified as a arguments.  If an ADOM is not specified as a parameter this method will default
  ## to retrieving a report list from the root ADOM. If start time is provided you must also pass end time and
  ## vice-versa.  Various time formats are supported including with/without dashes and with/without time. If
  ## date/time arguments are provided but format is not valid then will still run with out date/time filtering.
  ##
  ## Usage:
  ##   list_faz_generated_reports()
  ##
  ## Optional Arguments:
  ##  :adom        # containing adom-name
  ##  :start_time  # => '2014-01-01T00:00:00'    earliest report time
  ##  :end_time    # => '2014-04-01T00:00:00'    latest report time
  #####################################################################################################################
  def list_faz_generated_reports(opts={})
    querymsg = @authmsg
    querymsg[:adom] = opts[:adom] ? opts[:adom] : 'root'

      if opts[:start_date] && opts[:end_date]
        startdate = DateTime.parse(opts[:start_date]).strftime('%Y-%m-%dT%H:%M:%S') rescue false
        enddate = DateTime.parse(opts[:end_date]).strftime('%Y-%m-%dT%H:%M:%S') rescue false
        if startdate && enddate
          if enddate > startdate
            querymsg[:start_date] = startdate
            querymsg[:end_date] = enddate
          else
            puts __method__.to_s + ': End_date provided comes before the start_date provided, executing without date filter.'
          end
        else
          puts __method__.to_s  + ': Invalid date formats provided, executing without date filter.'
        end
      end

    begin
      exec_soap_query(:list_faz_generated_reports,querymsg,:list_faz_generated_reports_response,:report_list)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: list_revision_id   (Returns: Nori::StringWithAttributes) string contains revision ID requested
  ##
  ## Retrieves revision IDs associated with a particular device and optionally revisions with specific name
  ##
  ## Usage:
  ##  list_revision_id(:serial_number => 'serial_number') OR
  ##  list_revision_id(:dev_id => 'device_id')
  ##
  ## Optional Arguments:
  ##  rev_name   # Name of revision to get ID for, if not specified retrieves current revision
  #####################################################################################################################
  def list_revision_id(opts={})
    querymsg = @authmsg
    querymsg[:rev_name] = opts[:rev_name] if opts[:rev_name]

    begin
      if opts[:serial_number]
        querymsg[:serial_number] = opts[:serial_number]
      elsif opts[:dev_id]
        querymsg[:dev_id] = opts[:dev_id]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :dev_id OR :serial_number')
      end
      exec_soap_query(:list_revision_id,querymsg,:list_revision_id_response,:rev_id)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: remove_faz_archive  (returns Hash)   (Returns: Hash)   returned result contains error_code and
  ##  error_message hash keys.  :error_code=0 (successful), :error_code=1 (failed)
  ##
  ## Removes specified archive file.  (Filename is required and can be retrieved from associated FAZ log
  ## incident serial number)
  ##
  ## Usage:
  ##  get_faz_archive({:adom => 'adom_name', :dev_id => 'serial_number', :file_name => 'filename', :type => 'type'})
  ##
  ## Please note that in most cases dev_id means dev_id but for this query you must supply the serial number as
  ## the dev_id.
  ##
  ## Types are as follows:   1-Web, 2-Email, 3-FTP, 4-IM, 5-Quarantine, 6-IPS
  ##
  ## Filename must be known and can be found in the associated log file
  ##
  ## Also note, that although the WSDL claims that this query supports tar and gzip compression options I have not
  ## been able to get either of those to work.  if you specify tar the file is sent without compression (same as if
  ## you didn't specify) if you specify gzip it also requires to specify a password but if you do the query will
  ## always hang.
  #####################################################################################################################
  def remove_faz_archive (opts={})
    querymsg = @authmsg
    #querymsg[:compression] = 'gzip'    #parameter does not seem to work so it is not included as option right now
    #querymsg[:zip_password] = 'test'   #parameter does not seem to work so it is not included as option right now

    begin
      if opts.empty?
        raise ArgumentError.new('Must provide required arguments for method-> :adom, :dev_id, :file_name, :type')
      else
        if opts.has_key?(:adom) && opts.has_key?(:dev_id) && opts.has_key?(:file_name) && opts.has_key?(:type)
          querymsg[:adom] = opts[:adom]
          querymsg[:dev_id] = opts[:dev_id]
          querymsg[:file_name] = opts[:file_name]
          querymsg[:type] = opts[:type]
        else
          raise ArgumentError.new('Must provide required arguments for method-> :adom, :dev_id, :file_name, :type')
        end
      end
      exec_soap_query(:remove_faz_archive,querymsg,:remove_faz_archive_response,:error_msg)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: retrieve_config  (Returns: Nori::StringWithAttributes)   String returned will contain the
  ##  FortiManager task ID of the request.  Status of the request can be found by retrieving and analyzing the task
  ##  by ID.
  ##
  ## Retrieves configuration from managed device to FortiManager DB
  ##
  ## Usage:
  ##  retrieve_config(:serial_number => 'XXXXXXXXXXXXX') OR
  ##  retrieve_config(:dev_id => 'XXX')
  ##
  ## Optional Arguments:
  ##  :rev_name   # Name to give to revision when saved to DB.  If not specified will be default naming.
  #####################################################################################################################
  def retrieve_config(opts={})
    querymsg = @authmsg
    querymsg[:new_rev_name] = opts[:rev_name] if opts[:rev_name]

    begin
      if opts[:serial_number]
        querymsg[:serial_number] = opts[:serial_number]
      elsif opts[:dev_id]
        querymsg[:dev_id] = opts[:dev_id]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :dev_id OR :serial_number')
      end
      exec_soap_query(:retrieve_config,querymsg,:retrieve_config_response,:task_id)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: revert config  (Returns: Hash)   returned result contains error_code and error_message hash keys.
  ##  :error_code=0 (successful), :error_code=1 (failed)
  ##
  ## Reapplies a previous revision of configuration history to the active config set for the specified device
  ##  revert_config({rev_id => 'rev#', :serial_number => 'XXXXXXXXXXXXX'}) OR
  ##  retrieve_config({rev_id => 'rev#', :dev_id => 'XXX'})
  #####################################################################################################################
  def revert_config(opts={})
    querymsg = @authmsg

    begin
      if opts[:serial_number] && opts[:rev_id]
        querymsg[:serial_number] = opts[:serial_number]
        querymsg[:rev_id] = opts[:rev_id]
      elsif opts[:dev_id] && opts[:rev_id]
        querymsg[:dev_id] = opts[:dev_id]
        querymsg[:rev_id] = opts[:rev_id]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :dev_id OR :serial_number in AND :rev_id')
      end
      exec_soap_query(:revert_config,querymsg,:revert_config_response,:error_msg)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: run_faz_report  (Returns: Hash)   returned result contains error_code and error_message hash keys.
  ##  :error_code=0 (successful), :error_code=1 (failed)
  ##
  ##   ************** Still need to identify filter options and test those *********
  ##
  ##  Usages:
  ##   run_faz_report(:report_template => 'report_name'
  ##   run_faz_report({:report_template => 'report_name', :filter => 'filters'})
  ##   run_faz_report({:report_template => 'report_name', :filter => 'filters', :adom = 'adom_name'})
  #####################################################################################################################
  def run_faz_report(opts = {})
    querymsg = @authmsg
    querymsg[:adom] = opts[:adom] ? opts[:adom] : 'root'
    querymsg[:filter] = opts[:filter] if opts[:filter]

    begin
      if opts[:report_template]
        querymsg[:report_template] = opts[:report_template]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :adom AND :report_template')
      end
      exec_soap_query(:run_faz_report,querymsg,:run_faz_report_response,:error_msg)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: run_script  (Returns: Nori::StringWithAttributes)  returned value is task ID for script process
  ##
  ## Usages:
  ##  run_script({:name => 'name-of-script', :serial_number => 'XXXXXXXXXXXXX'})
  ## Optionally can specify the following arguments:
  ##  :is_global  (values: true or false) [default = false],
  ##  :run_on_db  (values: true or false) [default = false],
  ##  :type (values CLI or TCL) [default = CLI]
  #####################################################################################################################
  def run_script(opts={})
    querymsg = @authmsg
    querymsg[:is_global] = opts[:is_global] ? opts[:is_global] : 'false'
    querymsg[:run_on_dB] = opts[:run_on_db] ? opts[:run_on_db] : 'false'
    querymsg[:type] = opts[:type] ? opts[:type] : 'CLI'


    begin
      if opts[:name] && opts[:serial_number]
        querymsg[:name] = opts[:name]
        querymsg[:serial_number] = opts[:serial_number]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :name AND :serial_number')
      end
      exec_soap_query(:run_script,querymsg,:run_script_response,:task_id)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: search_faz_log  (Returns: Hash (for single log) or Array of Hashes (for multiple logs))
  ##
  ## Usage:
  ##  search_faz_log({:device_name => 'name-of-device', :search_criteria => 'srcp=x.x.x.x and XXXXX'})
  ##
  ## Optionally can specify the following arguments:
  ##  :adom (values 'adom-names') [default => root]
  ##  :check_archive (values: 0, 1?) [default = 0]
  ##  :compression (values: tar, gzip) [default = tar]
  ##  :content  (values:  logs, XXX, XXX) [default = logs]
  ##  :dlp_archive_type (values:  XXXX) [default: <not set>]
  ##  :format  (values: rawFormat, XXXX) [default = rawFormat]
  ##  :log_type  (values: traffic, event, antivirus, webfilter, intrusion, emailfilter, vulnerability, dlp, voip) [default = traffic],
  ##  :max_num_matches  (values: 1-n) [default = 10],
  ##  :start_index  (values: 1-n) [default = 1],
  ##
  #####################################################################################################################
  def search_faz_log(opts={})
    querymsg = @authmsg
    querymsg[:adom] = opts[:adom] ? opts[:adom] : 'root'
    querymsg[:check_archive] = opts[:check_archive] ? opts[:check_archive] : '0'
    querymsg[:compression] = opts[:compression] ? opts[:check_compression] : 'tar'
    querymsg[:content] = opts[:content] ? opts[:content] : 'logs'
    querymsg[:format] = opts[:formate] ? opts[:format] : 'rawFormat'
    querymsg[:log_type] = opts[:log_type] ? opts[:log_type] : 'traffic'
    querymsg[:max_num_matches] = opts[:max_num_matches] && opts[:max_num_matches] > 0 ? opts[:max_num_matches] : '10'
    querymsg[:search_criteria] = opts[:search_criteria] ? opts[:search_criteria] : 'srcip=10.0.2.15'
    querymsg[:start_index] = opts[:start_index] && opts[:start_index] > 1 ? opts[:start_index] : '1'
    querymsg[:DLP_archive_type] = opts[:dlp_archive_type] if opts[:dlp_archive_type]

    begin
      if opts[:device_name]
        querymsg[:device_name] = opts[:device_name]
      else
        raise ArgumentError.new('Must provide required arguments for method-> :name AND :serial_number')
      end
      result = exec_soap_query(:search_faz_log,querymsg,:search_faz_log_response,:logs)
      return result[:data]
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: set_faz_config  (Returns:
  ##
  ## Usage:
  ##  search_faz_log({:config =>  "configuration \n configuration \n ..."})
  #####################################################################################################################
  def set_faz_config(opts={})
    querymsg = @authmsg
    querymsg[:adom] = opts[:adom] ? opts[:adom] : 'root'

    begin
      if opts[:config]
        querymsg[:config] = opts[:config]
      else
        raise ArgumentError.new('Must provide required argument for method-> :config')
      end
      exec_soap_query(:set_faz_config,querymsg,:set_faz_config_response,:task_id)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end
  alias :set_fmg_config :set_faz_config


##############################
 private
##############################

  ###############################################################################################
  ## Method: exec_soap_query
  ## executes the Savon API calls to FMG for each of the above methods (with a couple of exceptions)
  ###############################################################################################
  def exec_soap_query(querytype,querymsg,responsetype,infotype)

    ### Make SOAP call to FMG and store result in 'data'
    begin
      data = @client.call(querytype, message: querymsg).to_hash

    rescue Exception => e
        fmg_rescue(e)
        return e
    end

    begin
      # Check for API error response and return error if exists
      if data[responsetype].has_key?(:error_msg)
        if data[responsetype][:error_msg][:error_code].to_i != 0
          raise data[responsetype][:error_msg][:error_msg]
        else
          return data[responsetype][infotype]
        end
      else
        return data[responsetype][infotype]
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  ##################################################################################################################
  ## Method: exec_soap_query_for_get_sys_status
  ## executes the Savon API calls to FMG for only the get_sys_status method because the FortiManager
  ## returns data without a container attribute as it does with all other queries so we must manually parse out
  ## each of the values returned specifically.
  #################################################################################################################
  def exec_soap_query_for_get_sys_status(querytype,querymsg,responsetype)

    ### Make SOAP call to FMG and store result in 'data'
    begin
      data = @client.call(querytype, message: querymsg).to_hash

    rescue Exception => e
      fmg_rescue(e)
      return e
    end

    begin
      # Check for API error response and return error if exists
      if data[responsetype].has_key?(:error_msg)
        if data[responsetype][:error_msg][:error_code].to_i != 0
          raise data[responsetype][:error_msg][:error_msg]
        else
          status_result = {
              :platform_type => data[responsetype][:platform_type],
              :version => data[responsetype][:version],
              :serial_number => data[responsetype][:serial_number],
              :bios_version =>  data[responsetype][:bios_version],
              :host_name => data[responsetype][:hostName],
              :max_num_admin_domains => data[responsetype][:max_num_admin_domains],
              :max_num_device_group => data[responsetype][:max_num_device_group],
              :admin_domain_conf => data[responsetype][:admin_domain_conf],
              :fips_mode => data[responsetype][:fips_mode]
          }
        end
      else
        status_result = {
            :platform_type => data[responsetype][:platform_type],
            :version => data[responsetype][:version],
            :serial_number => data[responsetype][:serial_number],
            :bios_version =>  data[responsetype][:bios_version],
            :host_name => data[responsetype][:hostName],
            :max_num_admin_domains => data[responsetype][:max_num_admin_domains],
            :max_num_device_group => data[responsetype][:max_num_device_group],
            :admin_domain_conf => data[responsetype][:admin_domain_conf],
            :fips_mode => data[responsetype][:fips_mode]
        }
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #################################################################################
  ## Method: fmg_rescue
  ## provides style for rescue and error messaging
  #################################################################################
  def fmg_rescue(error)
    puts '### Error! ################################################################################################'
    puts error.message
    puts error.backtrace.inspect
    puts '###########################################################################################################'
    puts ''
  end
end
