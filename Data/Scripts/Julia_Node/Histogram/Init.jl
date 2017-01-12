module Node_Histogram
	
	using PB, Logger, Node, Node_Julia
	
	type Object
		node_id::Int64
		
		histogram::Array{UInt8, 1}
		
		input::Ptr{Node.Conn_Input}
		output::Ptr{Node.Conn_Output}
		
		function Object(node_id::Int64)
			this = new(node_id)
			node = Node.Get(this.node_id)
			
			this.input = Node_Julia.Input_Add(node, "", "")
			Node_Julia.Input_Callback(this.input, "Event", Input_Callback_Event)
			
			this.output = Node_Julia.Output_Add(node, "", "")
			Node_Julia.Output_Callback(this.output, "Get_Size", Output_Callback_Get_Size)
			Node_Julia.Output_Callback(this.output, "Get_Data", Output_Callback_Get_Data)
			
			this
		end
	end
	
	function Input_Callback_Event(this::Object, input::Ptr{Void}, event::Ptr{Void})
		event = convert(Ptr{Node.Event}, event) # Hackish way until i pass the right type directly
		event = unsafe_load(event)
		
		if event.event_type == Node.Link_Event_Update
			Update_Histogram(this)
		end
		
		return 1
	end
	
	function Output_Callback_Get_Size(this::Object, output::Ptr{Void})
		return 256 * 256
	end
	
	function Output_Callback_Get_Data(this::Object, output::Ptr{Void}, position::Int64, data::Array{UInt8,1}, metadata::Array{UInt8,1})
		histogram = this.histogram
		
		# Get size
		size = min(length(histogram) - position, length(data), length(metadata))
		if size <= 0
			return 0
		end
		
		# Copy data
		data[1:size] .= histogram[position+1:position+size]
		metadata[1:size] .= 0b10000001
		
		return 1
	end
	
	function Update_Histogram(this::Object)
		inputsize = Node.Input_Get_Size(this.input)
		if inputsize < 0
			return false
		end
		
		inputdata = zeros(UInt8, inputsize)
		if Node.Input_Get_Data(this.input, 0, inputdata) == 0
			return false
		end
		
		histogram = zeros(Float32, 256, 256)
		maximum = 0
		for i in 1:length(inputdata)-1
			histogram[inputdata[i]+1, inputdata[i+1]+1] += 1
			if maximum < histogram[inputdata[i]+1, inputdata[i+1]+1]
				maximum = histogram[inputdata[i]+1, inputdata[i+1]+1]
			end
		end
		
		# Nonlinear scale
		histogram = sqrt(histogram)
		maximum = sqrt(maximum)
		
		# Normalize array
		histogram = histogram .* 255 / maximum
		
		# Flatten array and change its type
		histogram = convert(Array{UInt8, 1}, floor(histogram[:]))
		
		# Write to object
		this.histogram = histogram
		
		# Send event out of the output
		event = Node.Event(Node.Link_Event_Update, 0, sizeof(histogram))
		Node.Output_Event(this.output, event)
		
		return true
	end
	
end