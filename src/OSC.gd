class_name OSC extends Node

var server :UDPServer
var messageHandlers = {}
var _outIP:String = "127.0.0.1"
var _inPort:int = 9999
var _outPort:int = 8888

func _init(inPort:int=_inPort, outPort:int=_outPort, outIP:String=_outIP):
	self._outPort = outPort 
	self._outIP = outIP 
	server = UDPServer.new()
	server.listen(inPort)
	print(server.is_listening())
	
func _process(delta):
	server.poll() # Important!
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet()
		var msg = OSC_MSG.new(packet)
		if(!msg.isValid):
			return
		if (messageHandlers.has("*")):
			for handler in messageHandlers.get("*"):
				handler.call(msg)
		if (messageHandlers.has(msg.address)):
			for handler in messageHandlers[msg.address]:
				handler.call(msg)

func send(buffer:PackedByteArray):
	var udp = PacketPeerUDP.new()
	udp.connect_to_host(_outIP, _outPort)
	udp.put_packet(buffer)
	print(buffer)
	pass

func stop():
	server.stop()

func onMessage(address:String, callback:Callable):
	if (!messageHandlers.has(address)) :
		messageHandlers[address] = []
	messageHandlers[address].push_back(callback)
