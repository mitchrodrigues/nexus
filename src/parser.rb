class Parser

  def self.parse_line(socket, line)
    tokens = tokenize(line)
    client = Nexus::ClientManager.find socket
    if client
      EventEngine::Command.dispatch(client, tokens[1], tokens)
    end
  end

  def self.tokenize(line)
     tokens = line[0,1]!=':' ? [""] : []
    chunk = line.split(":")

    if chunk[1]
        offset = 1
    else
        offset = 0
    end
    tokens += chunk[offset].split(" ")
    tokens << chunk[2] if chunk[2]
  end

end
