
module Read_config

  require 'yaml'
  targetDir = ENV["HOME"] + "/"
  $config = targetDir  +  ".opcontoken.yaml"

  def get_dbuser
    config = YAML.load_file($config)
    config['opconuser']
  end
  def get_dbpwd
    config = YAML.load_file($config)
    config['opconpassword']
  end

  def get_serverport_prodstage
    config = YAML.load_file($config)
    host = config['server_prodstage']
    return host
  end
  def get_token_prodstage
    config = YAML.load_file($config)
    token = config['external_token_prodstage']
    return token
  end

  def get_serverport_teststage
    config = YAML.load_file($config)
    host = config['server_teststage']
    return host
  end
  def get_token_teststage
    config = YAML.load_file($config)
    token = config['external_token_teststage']
    return token
  end

  def get_serverport_devstage
    config = YAML.load_file($config)
    host = config['server_devstage']
    return host
  end
  def get_token_devstage
    config = YAML.load_file($config)
    token = config['external_token_devstage']
    return token
  end

end
