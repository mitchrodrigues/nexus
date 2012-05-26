class Parser

  def self.parse_line(socket, line)
    tokens = tokenize(line)
    if tokens[0] != ""
      client = ClientManager.find_by_name(tokens[0])
    else
      client = ClientManager.find_by_socket(socket)
    end
    command = tokens[1]
    if client 
      EventEngine::Command.dispatch(client, command, tokens[2,tokens.size])
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
