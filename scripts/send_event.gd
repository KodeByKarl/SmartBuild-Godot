extends Node

func send_event(plugin, event_name: String, data: Dictionary = {}):
	if(plugin == null):
		print("Do not leave plugin null.")
		return
	
	var mess: String
	if(!data.is_empty()):
		mess = JSON.stringify(data)
	
	if(event_name.is_empty()):
		print("Do not leave even_name blank.")
		return
	
	plugin.sendMessageToCompose(mess)
