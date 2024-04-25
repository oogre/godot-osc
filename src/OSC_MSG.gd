class_name OSC_MSG

var addrPatern:String
var separator = ','.to_ascii_buffer()[0]
var KOMMA = 0x2c
var ZEROBYTE = 0x00
var _myAddrInt = -1
var _myAddrPattern = ""
var _myTypetag = []
var _myData = []
var _myArguments = []
var isArray = false
var _myArrayType = 0x00
var _isValid = false

var address :  String :
	get:
		return _myAddrPattern
	set(value):
		_myAddrPattern = value
		
var isValid :  bool :
	get:
		return _isValid

var dataLength :  int :
	get:
		return _myArguments.size()

func getValue(id:int):
	return _myArguments[id]

func add(value):
	_myArguments.push_back(value)
	match typeof(value):
		TYPE_FLOAT:
			_myTypetag.push_back(0x66)
		TYPE_STRING:
			_myTypetag.push_back(0x73)
		TYPE_INT:
			_myTypetag.push_back(0x69)
		TYPE_PACKED_BYTE_ARRAY:
			_myTypetag.push_back(0x62)
#
#	if("PackedByteArray" == type_string(typeof(value))):
#		_myTypetag.push_back(0x62)
#	elif("String" == type_string(typeof(value))):
#		_myTypetag.push_back(0x73)
#	elif("int" == type_string(typeof(value))):
#		_myTypetag.push_back(0x69)
#	elif("float" == type_string(typeof(value))):
		
	return self

func padSize(bytes:int): 
	return ( 4- (bytes & 03)) & 3


func toPackedByteArray():
	var output = PackedByteArray()
	var addrPad = padSize(_myAddrPattern.length() + 1)
	output.append_array ( _myAddrPattern.to_utf8_buffer() )
	output.append(ZEROBYTE)
	while(addrPad>0):
		output.append(ZEROBYTE)
		addrPad-=1
	output.append(KOMMA)
	for i in range(0,_myTypetag.size()):
		output.append(_myTypetag[i])
	var typePad = padSize(_myTypetag.size() + 1);
	while(typePad>0):
		output.append(ZEROBYTE)
		typePad-=1
	for i in range(0,_myArguments.size()):
		match _myTypetag[i]:
			0x69:#'i'.to_ascii_buffer()[0]: # Interger
				var data = PackedByteArray()
				data.resize(4)
				data.encode_s32(0, _myArguments[i])
				data.reverse()
				output.append_array(data)
			0x66:#'f'.to_ascii_buffer()[0]: # Float
				var data = PackedByteArray()
				data.resize(4)
				data.encode_float(0, _myArguments[i])
				data.reverse()
				output.append_array(data)
			0x73:#'s'.to_ascii_buffer()[0]: # String
				output.append_array ( _myArguments[i].to_utf8_buffer() )
				output.append(ZEROBYTE)
				var dataPad = padSize(_myArguments[i].length() + 1)
				while(dataPad>0):
					output.append(ZEROBYTE)
					dataPad-=1
			0x62:#'b'.to_ascii_buffer()[0]: # Blob
				output.append_array ( _myArguments[i] )
				var dataPad = padSize(_myArguments[i].length())
				while(dataPad>0):
					output.append(ZEROBYTE)
					dataPad-=1
	return output

func send(sender:OSC):
	sender.send(toPackedByteArray())
	return self
	
func toString():
	var data = ""
	for arg in _myArguments:
		data += String(arg) + " "
		
	return self.address + " " + data

func _init(value):
	
	
	
	if(TYPE_PACKED_BYTE_ARRAY == typeof(value)):
		_parseMessage(value)
	elif(TYPE_STRING
	 == typeof(value)):
		self.address = value

func _parseMessage(theBytes):
	var myLength = theBytes.size()
	var myIndex = 0;
	myIndex = _parseAddrPattern(theBytes, myLength, myIndex);
	if (myIndex != -1):
		myIndex = _parseTypetag(theBytes, myLength, myIndex);
	if (myIndex != -1):
		_myData = theBytes.slice(myIndex)
		_myArguments = _parseArguments(_myData);
		_isValid = true;
	
func _parseAddrPattern(theBytes, theLength, theIndex):
	if (theLength > 4 && theBytes[4] == KOMMA):
		_myAddrInt = theBytes.slice(0, 4).to_int32_array()
	for i in range(theIndex,theLength):
		if (theBytes[i] == ZEROBYTE):
			_myAddrPattern = theBytes.slice(theIndex, theIndex+i).get_string_from_utf8()
			return i + _align(i)
	return -1;

func _parseTypetag(theBytes, theLength, theIndex):
	if (theBytes[theIndex] == KOMMA):
		theIndex+=1
		for i in range(theIndex,theLength):
			if (theBytes[i] == ZEROBYTE):
				_myTypetag = theBytes.slice(theIndex, i)
				return i + _align(i);
	return -1

func _parseArguments(theBytes):
	var myArguments = []
	var myTagIndex = 0
	var myIndex = 0
	myArguments.resize(_myTypetag.size())
	myArguments.fill(0) # Initialize the 10 elements to 0.
	
	isArray = _myTypetag.size() > 0
	
	while (myTagIndex < _myTypetag.size()):
		# check if we still save the arguments as an array
		if (myTagIndex == 0):
			_myArrayType = _myTypetag[myTagIndex]
		else:
			if (_myTypetag[myTagIndex] != _myArrayType):
				isArray = false
		match _myTypetag[myTagIndex]:
			0x69:#'i'.to_ascii_buffer()[0]: # Interger
				myArguments[myTagIndex] = theBytes.slice(myIndex, myIndex+4)
				myArguments[myTagIndex].reverse()
				myArguments[myTagIndex] = myArguments[myTagIndex].to_int32_array()[0]
				myIndex += 4;
			0x66:#'f'.to_ascii_buffer()[0]: # Float
				myArguments[myTagIndex] = theBytes.slice(myIndex, myIndex+4)
				myArguments[myTagIndex].reverse()
				myArguments[myTagIndex] = myArguments[myTagIndex].to_float32_array()[0]
				myIndex += 4;
			0x73:#'s'.to_ascii_buffer()[0]: # String
				myArguments[myTagIndex] = theBytes.slice(myIndex).get_string_from_utf8()
				var newIndex = myIndex + myArguments[myTagIndex].length()
				myIndex = newIndex + _align(newIndex)
			0x62:#'b'.to_ascii_buffer()[0]: # Blob
				var myLen = theBytes.slice(myIndex, myIndex+4)
				myLen.reverse()
				myLen = myLen.to_int32_array()[0]
				myIndex += 4;
				myArguments[myTagIndex] = theBytes.slice(myIndex, myIndex+myLen)
				myIndex += myLen + (_align(myLen) % 4)
		myTagIndex+=1
	_myData = _myData.slice(0, myIndex)
	return myArguments

func _align(theInt:int):
	return (4 - (theInt % 4))
