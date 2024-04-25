extends Node

var osc:OSC

func _init():
	osc = OSC.new(9999, 8888, "127.0.0.1") # inPort, outPort, outIP
	add_child(osc)	

	# Message input Handler 
	osc.onMessage("/bonjour", func(msg:OSC_MSG):
		print(msg.address, " ", msg.getValue(0))
	)

	# Message output
	var msg:OSC_MSG = OSC_MSG.new("/address")
	msg.add(123).send(osc)

func _exit_tree():
	osc.stop()
	remove_child(osc)



