class Parser

  def self.parse_line(socket, line)
    tokens = tokenize(line)
    
    unless tokens[0].blank? || tokens[0] == ""
      client = ClientManager.find_by_name[tokens[0]]
    end

    unless client
      client = ClientManager.find socket
    end

    if client 
      EventEngine::Command.dispatch(client, tokens[1], tokens)
    else
      NEXUS_LOGGER.info "Command from unknown client #{socket.to_i}"
    end

  end

  def self.tokenize(line_in, string_prefix = ':', token_delim = ' ')
    tokens = line_in[0,1] != string_prefix ? [""] : []
    chunk  = line_in.split(string_prefix)
    if chunk[1]
        offset = 1
    else
        offset = 0
    end
    tokens += chunk[offset].split(token_delim)
    tokens << chunk[2] if chunk[2]
    return tokens
  end

end
