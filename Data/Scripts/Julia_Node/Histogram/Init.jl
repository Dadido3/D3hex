module Node_Histogram
	
	using PB, Logger, Node, Node_Julia
	
	type Object
		node_id::Int64
		
		histogram_max::Float32
		histogram_min::Float32
		histogram::Array{Float32, 2}
		
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
		# Get and flatten histogram data
		local histogram = this.histogram[:]
		local max_value = this.histogram_max
		local min_value = this.histogram_min
		
		# Get size
		size = min(length(histogram) - position, length(data), length(metadata))
		if size <= 0
			return 0
		end
		
		# Get only the slice of data, which is needed
		histogram = histogram[position+1:position+size]
		
		# Nonlinear scale
		histogram = sqrt(histogram)
		max_value = sqrt(max_value)
		min_value = sqrt(min_value)
		
		# Normalize array
		if min_value != max_value
			histogram = (histogram - min_value) / (max_value - min_value) * 255
		end
		
		# Customc scaling
		histogram *= 10
		
		# Limit range to UInt8
		@simd for i in 1:length(histogram)
			@inbounds if histogram[i] > 255
				histogram[i] = 255
			end
		end
		
		# Flatten array and change its type
		histogram = floor(UInt8, histogram[:])
		
		# Copy data
		data[1:size] .= histogram
		metadata[1:size] .= 0b10000001
		
		return 1
	end
	
	function Update_Histogram(this::Object)
		inputsize = Node.Input_Get_Size(this.input)
		
		if inputsize >= 0
			inputdata = zeros(UInt8, inputsize)
			if Node.Input_Get_Data(this.input, 0, inputdata) == 0
				this.histogram = zeros(UInt8, 0)
				return false
			end
		else
			inputdata = zeros(UInt8, 0)
		end
		
		histogram = zeros(Float32, 256, 256)
		max_value = 0
		for i in 1:length(inputdata)-1
			histogram[inputdata[i]+1, inputdata[i+1]+1] += 1
			if max_value < histogram[inputdata[i]+1, inputdata[i+1]+1]
				max_value = histogram[inputdata[i]+1, inputdata[i+1]+1]
			end
		end
		
		# Write to object
		this.histogram = histogram
		this.histogram_max = max_value
		this.histogram_min = minimum(histogram)
		
		# Send event out of the output
		event = Node.Event(Node.Link_Event_Update, 0, 256 * 256)
		Node.Output_Event(this.output, event)
		
		return true
	end
	
end