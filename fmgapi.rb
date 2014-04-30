require 'savon'
require 'date'
require 'time'

######################################################################################################################
### Nick Petersen (2014) - All rights reserved
######################################################################################################################
### This class provides simplified interaction with the Fortinet FortiManager XML API.  Various class methods
### are implemented to abstract the complexity in executing FMG XML API queries.
### Uses Savon Gem for SOAP query/response handling.  Most Savon parameters are pre-set with values that are known
### to work with FortiManager and FortiAnalyzer.
###
### Usage example:
###                   fmginstance = FmgApi.new('wsdl_file_location', 'url', 'namespace', 'userid', 'passwd')
###                   result = fmginstance.get_adom_list
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
    # filters: [:password],  #sensitive info can be filtered from logs.  specifies which parameters to filter from logs
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
  ##  get_adom_by_name('adom_name') OR
  ##  get_adom_by_name()  ## if no parameter is passed defaults to 'root'
  ################################################################################################
  def get_adom_by_name(adom_name='root')
    querymsg = @authmsg
    querymsg[:names] = adom_name

    begin
      result = exec_soap_query(:get_adoms,querymsg,:get_adoms_response,:adom_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #############################################################################################
  ## Method: get_adom_by_oid  (Returns Hash)
  ##
  ## Retrieves VDOM info for a specified VDOM ID and returns a hash of VDOM attributes
  ##  get_adom_by_oid('oid') OR
  ##  get_adom_by_oid()  ##  if no parameter is passed defaults to OID=3
  #############################################################################################
  def get_adom_by_oid(oid='3')
    querymsg = @authmsg
    querymsg[:adomIds] = oid

    begin
      result = exec_soap_query(:get_adoms,querymsg,:get_adoms_response,:adom_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################
  ## Method: get_adom_list  (Returns Array of Hashes  (unless not in ADOM mode then potentially just Hash))
  ##
  ## Returns ADOM details as hash of hashes with top key based on OID
  ##  get_adom_list()
  #####################################################################
  def get_adom_list
    querymsg = @authmsg

    begin
      result = exec_soap_query(:get_adom_list,querymsg,:get_adom_list_response,:adom_info)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_config  (Returns Hash)
  ##
  ## Retrieves a specific configuration revision
  ## Must supply parameters in the form of ONE of the following:
  ##  get_config(rev#, :sn => 'XXX') OR
  ##  get_config(rev#, :dev_id => 'XXX')
  ## Optionally MAY also include an ADOM specification such as:
  ##  get_config(rev#, {:sn => 'XXX', :adom => 'XXX') OR
  ##  get_config(rev#, {:dev_id => 'XXX', :adom => 'XXX'})
  #####################################################################################################################
  def get_config (rev, opts={})
    querymsg = @authmsg
    querymsg[:revision_number] = rev
    begin
      if opts[:sn]
        querymsg[:serial_number] = opts[:sn]
        if opts[:adom]
          querymsg[:adom] = opts[:adom]
        end
        result = exec_soap_query(:get_config,querymsg,:get_config_response,:return)
      elsif opts[:dev_id]
        querymsg[:dev_id] = opts[:dev_id]
        if opts[:adom]
          querymsg[:adom] = opts[:adom]
        end
        result = exec_soap_query(:get_config,querymsg,:get_config_response,:return)
      else
        raise ArgumentError.new('Must provide parameters for method get_config.  :dev_name or :dev_id')
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
    return result
  end

  #####################################################################################################################
  ## Method: get_config_revision_history  (Returns Hash or Array of Hashes)
  ##
  ## Retrieves list of configurations from Revision History
  ## Must supply parameters in the form of ONE of the following:
  ##  get_config_revision_history(:sn => 'XXX')  OR
  ##  get_config_revision_history(:dev_id => 'XXX')  OR
  ##  get_config_revision_history(:adom => 'XXX')
  #####################################################################################################################
  def get_config_revision_history (opts={})
    querymsg = @authmsg

    begin
      if opts[:sn]
        querymsg[:serial_number] = opts[:sn]
        result = exec_soap_query(:get_config_revision_history,querymsg,:get_config_revision_history_response,:return)
      elsif opts[:dev_id]
        querymsg[:dev_id] = opts[:dev_id]
        result = exec_soap_query(:get_config_revision_history,querymsg,:get_config_revision_history_response,:return)
      elsif opts[:adom]
        querymsg[:adom] = opts[:adom]
        result = exec_soap_query(:get_config_revision_history,querymsg,:get_config_revision_history_response,:return)
      else
        raise ArgumentError.new('Must provide parameters for method get_config_revision_history. :dev_name or :dev_id')
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_device (Returns Hash)
  ##
  ## Retrieves a list of vdoms or with parameters a vdom for a specific device id or device name.
  ## Must supply parameters in the form of ONE of the following:
  ##  get_device(:sn => 'XXX')  OR
  ##  get_device(:dev_id => 'XXX')
  #####################################################################################################################
  def get_device (opts={})
    querymsg = @authmsg

    begin
      if opts[:sn]
        querymsg[:serial_numbers] = opts[:sn]
        result = exec_soap_query(:get_devices,querymsg,:get_devices_response,:device_detail)
      elsif opts[:dev_id]
        querymsg[:dev_ids] = opts[:dev_id]
        result = exec_soap_query(:get_devices,querymsg,:get_devices_response,:device_detail)
      else
        raise ArgumentError.new('Must provide parameters for method get_device_vdom_list.  :sn or :dev_id')
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end

  end

  #####################################################################################################################
  ## Method: get_device_license_list  (Returns Hash or Array of Hashes)
  ##
  ## Retrieves a list of vdoms or with parameters a vdom for a specific device id or device name.
  ## Usage:
  ##  get_device_license_list()
  ##
  #####################################################################################################################
  def get_device_license_list
    querymsg = @authmsg

    begin
      result = exec_soap_query(:get_device_license_list,querymsg,:get_device_license_list_response,:return)

    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_device_list (Returns Hash or Array of Hashes)
  ##
  ## Retrieves a list of managed devices from FMG, returns hash of hashes with primary key based on serial number
  ## Optionally takes parameter to specify ADOM to pull devices from, if not provided defaults to root ADOM
  ##  get_device_list() OR
  ##  get_device_list('adom')
  #####################################################################################################################
  def get_device_list (adom='root')
    querymsg = @authmsg
    querymsg[:adom] = adom   ###
    querymsg[:detail] = 0      ### detail must be either 0 or 1, defaults to 0.  1 is more verbose, this option is having problems right now so is commented out and will default to 1

    begin
      result = exec_soap_query(:get_device_list,querymsg,:get_device_list_response,:device_info)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_device_list_detail (Returns Hash or Array of Hashes)
  ##
  ## Retrieves a list of managed devices from FMG with extra detail, returns hash of hashes with primary key based
  ## on serial number
  ## Optionally takes parameter to specify ADOM to pull devices from, if not provided defaults to root ADOM
  ##  get_device_list_detail() OR
  ##  get_device_list_detail('adom_name')
  #####################################################################################################################
  def get_device_list_detail (adom_name='root')
    querymsg = @authmsg
    querymsg[:adom] = adom_name
    querymsg[:detail] = 1

    begin
      result = exec_soap_query(:get_device_list,querymsg,:get_device_list_response,:device_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_device_vdom_list (Returns Hash or Array of Hashes)
  ##
  ## Retrieves a list of vdoms or with parameters a vdom for a specific device id or device name.
  ## Must supply parameters in the form of ONE of the following:
  ##  get_device_vdom_list(:dev_name => 'XXX')  OR
  ##  get_device_vdom_list(:dev_id => 'XXX')
  #####################################################################################################################
  def get_device_vdom_list (opts={})
    querymsg = @authmsg
    begin
      if opts[:dev_name]
        querymsg[:dev_name] = opts[:dev_name]
        result = exec_soap_query(:get_device_vdom_list,querymsg,:get_device_vdom_list_response,:return)
      elsif opts[:dev_id]
        querymsg[:dev_iD] = opts[:dev_id]
        result = exec_soap_query(:get_device_vdom_list,querymsg,:get_device_vdom_list_response,:return)
      else
        raise ArgumentError.new('Must provide parameters for method get_device_vdom_list.  :dev_name or :dev_id')
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_faz_archive
  ## retrieves specified archive file.  (File name is required and can be retrieved from associated FAZ log
  ## incident serial number)
  ##
  ## Must include parameters adom, dev_id, file_name & type as in following example:
  ##  get_faz_archive({:adom => 'adom_name', :dev_id => 'serial_number', :file_name => 'filename', :type => 'type'})
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
      if opts.empty?
        raise ArgumentError.new('Must provide required parameters for method: :adom, :dev_id, :file_name, :type')
      else
          if opts.has_key?(:adom) && opts.has_key?(:dev_id) && opts.has_key?(:file_name) && opts.has_key?(:type)
            #querymsg.merge!(opts)
            querymsg[:adom] = opts[:adom]
            querymsg[:dev_id] = opts[:dev_id]
            querymsg[:file_name] = opts[:file_name]
            querymsg[:type] = opts[:type]
            result = exec_soap_query(:get_faz_archive,querymsg,:get_faz_archive_response,:file_list)
          else
            raise ArgumentError.new('Must provide required parameters for method: :adom, :dev_id, :file_name, :type')
          end
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_faz_config  (Returns Nori::StringWithAttributes)
  ##   aliased also as get_fmg_config
  ##
  ##  Retrieves configuration in Nori::StringWithAttributes format from FortiManager OR FortiAnalyzer device
  #####################################################################################################################
  def get_faz_config
    querymsg = @authmsg

    begin
      result = exec_soap_query(:get_faz_config,querymsg,:get_faz_config_response,:config)
      return result
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end
alias :get_fmg_config :get_faz_config

  #####################################################################################################################
  ## Method: get_faz_generated_report  NEEDS WORK!!!!
  ##
  ##
  ## Must include parameters adom, dev_id, file_name & type as in following example:
  ##  get_faz_generated_report({:adom => 'adom_name', :dev_id => 'device_id, :file_name => 'filename', :type => 'type'})
  ##
  #####################################################################################################################
  def get_faz_generated_report (opts={})
    querymsg = @authmsg

    querymsg[:adom] = 'root'
    querymsg[:report_date] = '2014-04-25T14:36:05+00:00'
    querymsg[:report_name] = 'S-10002_t10002-Bandwidth and Applications Report-2014-04-25-0936'
    #querymsg[:report_name] = 'Bandwidth and Applications Report'
    #querymsg[:compression] = 'tar'

    result = exec_soap_query(:get_faz_generated_report,querymsg,:get_faz_generated_report_response,:return)

    #begin
    #  if opts.empty?
    #    raise ArgumentError.new('Must provide required parameters for method: :adom, :dev_id, :file_name, :type')
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
  ##
  ## Retrieves list of groups from FMG/FAZ.  Optionally can specify an ADOM in the passed parameters.  If no ADOM
  ## is specified then it will default to root ADOM.
  ##  get_group_list() OR
  ##  get_group_list ('adom_name')
  #####################################################################################################################
  def get_group_list(adom='root')
    querymsg = @authmsg
    querymsg[:detail] = 1
    querymsg[:adom] = adom

    begin
      result = exec_soap_query(:get_group_list,querymsg,:get_group_list_response,:group_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_groups (Returns Hash or Array of Hashes)
  ##
  ##
  ## Retrieves list of groups from FMG/FAZ.  Must specify either 'name' of group or 'group_id'.  Optionally can specify
  ## an ADOM.  If no ADOM is specified then it will default to root ADOM.
  ##  get_group(:name => 'group_name')  OR
  ##  get_group(:groupid => 'group_id') OR
  ##  get_group(:name => 'group_name', 'adom_name') OR
  ##  get_group(:groupid => 'group_id', 'adom_name')
  #####################################################################################################################
  def get_group(opts={}, adom='root')
    querymsg = @authmsg
    querymsg[:adom] = adom

    begin
      if opts[:name] || opts[:groupid]
        querymsg[:names] = opts[:name] if opts[:name]
        querymsg[:grp_ids] = opts[:groupid] if opts[:groupid]
      elsif opts[:name] && opts[:groupid]
        raise ArgumentError.new('Must provide required parameters for method: :name OR :groupid not both')
      else
        raise ArgumentError.new('Must provide required parameters for method: :name OR :groupid')
      end
      result = exec_soap_query(:get_groups,querymsg,:get_groups_response,:group_detail)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_instlog (Returns Hash or Array of Hashes)
  ##
  ## Retrieves installation logs for specified device
  ##  get_instlog(:dev_id => 'device_id')  OR
  ##  get_group(:sn=> 'serial_number') OR
  ##  get_group({:dev_id => 'device_id', :task_id => 'task_id'}) OR
  ##  get_group({:sn => 'serial_number', :task_id => 'task_id'})
  #####################################################################################################################
  def get_instlog(opts={}, adom='root')
    querymsg = @authmsg

    begin
      if opts[:dev_id] || opts[:sn]
        querymsg[:dev_id] = opts[:dev_id] if opts[:dev_id]
        querymsg[:serial_number] = opts[:sn] if opts[:sn]
        querymsg[:task_id] = opts[:task_id] if opts[:task_id]
      else
        raise ArgumentError.new('Must provide required parameters for method: :name or :groupid')
      end
      result = exec_soap_query(:get_instlog,querymsg,:get_instlog_response,:inst_log)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_package_list (Returns Hash or Array of Hashes)
  ##
  ## Retrieves policy package list.  Option to specify an ADOM or it defaults to root ADOM.
  ##  get_package_list()  OR
  ##  get_package_list('adom_name')
  #####################################################################################################################
  def get_package_list(adom='root')
    querymsg = @authmsg
    querymsg[:adom] = adom

    begin
      result = exec_soap_query(:get_package_list,querymsg,:get_package_list_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_script (Returns Hash)
  ##
  ## Retrieves script details.
  ##  get_script('script_name')
  #####################################################################################################################
  def get_script(script_name)
    querymsg = @authmsg
    querymsg[:name] = script_name

    begin
      result = exec_soap_query(:get_script,querymsg,:get_script_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_script_log (Returns Hash)
  ##
  ## Retrieves script log
  ##  get_script_log({:script_name => 'script_name', :dev_id => 'device_id'}) OR
  ##  get script_log({:script_name => 'script_name, :sn => 'serial_number})
  #####################################################################################################################
  def get_script_log(opts = {})
    querymsg = @authmsg

    begin
      if opts[:script_name] && opts[:dev_id]
        querymsg[:script_name] = opts[:script_name]
        querymsg[:dev_id] = opts[:dev_id]
      elsif opts[:script_name] && opts[:sn]
        querymsg[:serial_number] = opts[:sn]
      else
        raise ArgumentError.new('Must provide required parameters for method: (:script_name & :dev_id ) or (:script_name & :sn)')
      end

      result = exec_soap_query(:get_script_log,querymsg,:get_script_log_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_script_log_summary (Returns Hash )
  ##
  ## Retrieves summary of executed scripts for a specific device
  ##  get_script_log_summary(:dev_id => 'device_id') OR
  ##  get script_log_summary(:sn => 'serial_number) OR
  ##  get_script_log_summary({:dev_id => 'device_id', max_logs => '#'}) OR
  ##  get_script_log_summary({:sn => 'serial_number', max_logs => '#'})
  #####################################################################################################################
  def get_script_log_summary(opts = {})
    querymsg = @authmsg
    querymsg[:max_logs] = 1000
    querymsg[:max_logs] = opts[:max_logs] if opts[:max_logs]

    begin
      if opts[:dev_id] && opts[:sn]
        raise ArgumentError.new('Must provide required parameters for method: :script_name OR :sn (not both)')
      elsif opts[:dev_id]
        querymsg[:dev_id] = opts[:dev_id]
      elsif opts[:sn]
        querymsg[:serial_number] = opts[:sn]
      else
        raise ArgumentError.new('Must provide required parameters for method: :script_name or :sn')
      end

      result = exec_soap_query(:get_script_log_summary,querymsg,:get_script_log_summary_response,:return)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_system_status (Returns Hash)
  ##
  ## Retrieves summary of executed scripts for a specific device.  If adom is not provided it defaults to root ADOM
  ##  get_system_status() OR
  ##  get_system_status('adom_name')
  #####################################################################################################################
  def get_system_status(adom='root')
    querymsg = @authmsg
    querymsg[:adom] = adom

    begin
      result = exec_soap_query_for_get_sys_status(:get_system_status,querymsg,:get_system_status_response)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: get_task_detail (Returns Hash)
  ##
  ## Retrieves details of a task
  ##  get_task_detail('task_id') OR
  ##  get_task_detail('task_id', 'adom_name')   #if ADOM is not provided it defaults to root ADOM
  #####################################################################################################################
  def get_task_detail(task_id, adom='root')
    querymsg = @authmsg
    querymsg[:adom] = adom
    querymsg[:task_id] = task_id

    begin
      result = exec_soap_query(:get_task_list,querymsg,:get_task_list_response,:task_list)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: import_policy (Returns Nori::StringWithAttributes) returned string contains details of import if success
  ##
  ## Must provide following parameters  (:adom_name OR :adom_id) AND (:dev_name OR :dev_id) AND (:vdom_name OR :vdom_id)
  ##  Examples:
  ##   import_policy({:adom_name => 'root', :dev_name => 'MSSP-1', :vdom_name => 'root'})
  ##   import_policy({:adom_id => '3', :dev_id => '234', :vdom_id => '3'})
  ##   import_policy({:adom_name => 'root', :dev_id => '234', :vdom_name => 'root'})
  #####################################################################################################################
  def import_policy(opts = {})
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
        raise ArgumentError.new('Must provide required parameters for method: (:adom_id OR :adom_name) AND (:dev_id OR :dev_name) AND (:vdom_id OR :dev_name)')
      end

      result = exec_soap_query(:import_policy,querymsg,:import_policy_response,:report)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end


  #####################################################################################################################
  ## Method: install_conifg  (Returns Nori::StringWithAttributes)  string contains taskID of associated task
  ##
  ## Installs a policy package to specified device.
  ##  Note that there is no parameter validation in this method as there is in most other methods of this class.
  ##
  ## Required parameters:   :adom AND :pkgoid AND (:dev_id OR :sn)
  ## Optional parameters:  :rev_name, :validate
  ##
  ## Example:
  ##  install_config({:adom => 'root', :pkgoid => '572', :dev_id => '234', :rev_name => 'API Install'}
  #####################################################################################################################
  def install_config(opts = {})
    querymsg = @authmsg
    #querymsg.merge!(opts)

    if opts[:adom] && opts[:pkgoid] && opts[:dev_id]
      querymsg[:adom] = opts[:adom]
      querymsg[:pkgoid] = opts[:oid]
      querymsg[:dev_id] = opts[:dev_id]
    elsif opts[:adom] && opts[:pkgoid] && opts[:sn]
      querymsg[:adom] = opts[:adom]
      querymsg[:pkgoid] = opts[:oid]
      querymsg[:serial_number] = opts[:sn]
    else
      raise ArgumentError.new('Must provide required parameters for method: :adom AND :pkgoid AND (:dev_id OR :sn')
    end

    querymsg[:new_rev_name] = opts[:rev_name] if opts[:rev_name]
    querymsg[:install_validate] = opts[:validate] if opts[:validate]

    begin
      result = exec_soap_query(:install_config,querymsg,:install_config_response,:task_id)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: list_faz_generated_reports  (Returns Hash or Array of Hashes)
  ##
  ## Retrieves a list of FAZ generated reports stored on FortiAnalyzer or FortiManager.   An ADOM & start/end dates
  ## can be optionally specified as a parameters.  If an ADOM is not specified as a parameter this method will default
  ## to retrieving a report list from the root ADOM. If start time is provided you must also pass end time and
  ## vice-versa.
  ##
  ##   list_faz_generated_reports() OR
  ##   list_faz_generated_reports(:adom => 'adom_name') OR
  ##   list_faz_generated_reports({:start_time => '2014-01-01T00:00:00', :end_time => '2014-04-01T00:00:00'}) OR
  ##   list_faz_generated_reports({:adom => 'adom_name', :start_time => '20140101', :end_time => '20140401'})
  ##
  ##  Various time formats are supported including with/without dashes and with/without time ##
  #####################################################################################################################
  def list_faz_generated_reports(opts={})
    querymsg = @authmsg

    if opts.is_a?(Hash)
      if opts.has_key?(:adom)
        querymsg[:adom] =  opts[:adom]
      else
        querymsg[:adom] = 'root'
      end

      if opts.has_key?(:start_date) && opts.has_key?(:end_date)
        startdate = DateTime.parse(opts[:start_date]).strftime("%Y-%m-%dT%H:%M:%S") rescue false
        enddate = DateTime.parse(opts[:end_date]).strftime("%Y-%m-%dT%H:%M:%S") rescue false
        if startdate && enddate
          if enddate > startdate
            querymsg[:start_date] = startdate
            querymsg[:end_date] = enddate
          else
            puts 'End_date provided comes before the start_date provided, executing without date filter'
          end
        else
          puts 'Invalid date formats provided, executing without date filter'
        end
      end
    else
      querymsg[:adom] = 'root'
    end

    begin
      result = exec_soap_query(:list_faz_generated_reports,querymsg,:list_faz_generated_reports_response,:report_list)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end


  #####################################################################################################################
  ## Method: list_revision_id
  ##
  ## Retrieves revision IDs associated with a particular device and optionally revisions with specific name
  ##  list_revision_id(:sn => 'serial_number') OR
  ##  list_revision_id(:dev_id => 'device_id') OR
  ##  list_revision_id({:sn => 'serial_number', rev_name => 'revision_name') OR
  ##  list_revision_id({:dev_id => 'device_id', rev_name => 'revision_name')
  #####################################################################################################################
  def list_revision_id(opts = {})
    querymsg = @authmsg
    querymsg.merge!(opts)

    begin
      if opts[:sn]
        querymsg[:serial_number] = opts[:sn]
      elsif opts[:dev_id]
        querymsg[:dev_id] = opts[:dev_id]
      else
        raise ArgumentError.new('Must provide required parameters for method: :dev_id OR :sn')
      end
      querymsg[:rev_name] = opts[:rev_name] if opts[:rev_name]
      result = exec_soap_query(:list_revision_id,querymsg,:list_revision_id_response,:rev_id)
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end

  #####################################################################################################################
  ## Method: removes_faz_archive
  ## removes specified archive file.  (Filename is required and can be retrieved from associated FAZ log
  ## incident serial number)
  ##
  ## Must include parameters adom, dev_id, file_name & type as in following example:
  ##  get_faz_archive({:adom => 'adom_name', :dev_id => 'serial_number', :file_name => 'filename', :type => 'type'})
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
  def remove_faz_archive (opts={})
    querymsg = @authmsg
    #querymsg[:compression] = 'gzip'
    #querymsg[:zip_password] = 'test'

    begin
      if opts.empty?
        raise ArgumentError.new('Must provide required parameters for method: :adom, :dev_id, :file_name, :type')
      else
        if opts.has_key?(:adom) && opts.has_key?(:dev_id) && opts.has_key?(:file_name) && opts.has_key?(:type)
          #querymsg.merge!(opts)
          querymsg[:adom] = opts[:adom]
          querymsg[:dev_id] = opts[:dev_id]
          querymsg[:file_name] = opts[:file_name]
          querymsg[:type] = opts[:type]
          result = exec_soap_query(:remove_faz_archive,querymsg,:remove_faz_archive_response,:error_msg)
          return result[error_msg][error_msg]
        else
          raise ArgumentError.new('Must provide required parameters for method: :adom, :dev_id, :file_name, :type')
        end
      end
    rescue Exception => e
      fmg_rescue(e)
      return e
    end
  end


##############################
##############################


  ###############################################################################################
  ## Method: TESTING
  ###############################################################################################
  def test
    querymsg = @authmsg
    querymsg[:adom] = 'root'    ### Defaults to
    #querymsg[:detail] = 2
    puts querymsg
    data = @client.call(:get_device_list, message: querymsg).to_hash
    puts '######## Test Method Result#####'
    puts data
    puts ''
  end

  ###############################################################################################
  ## Method: exec_soap_query
  ## executes the Savon API calls to FMG for each of the above methods (with a couple of exceptions)
  ###############################################################################################
private
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
  private
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
