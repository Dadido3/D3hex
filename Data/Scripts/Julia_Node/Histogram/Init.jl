module Node_Histogram
	
	using PB, Logger, Node, Node_Julia
	
	type Object
		node_id::Int64
		
		input::Ptr{Node.Conn_Input}
		output::Ptr{Node.Conn_Output}
		
		function Object(node_id::Int64)
			this = new(node_id)
			node = Node.Get(this.node_id)
			
			this.input = Node_Julia.Input_Add(node, "", "")
			
			this.output = Node_Julia.Output_Add(node, "", "")
			Node_Julia.Output_Callback(this.output, "Get_Size", Output_Callback_Get_Size)
			Node_Julia.Output_Callback(this.output, "Get_Data", Output_Callback_Get_Data)
			
			this
		end
	end
	
	function Output_Callback_Get_Size(this::Object, output::Ptr{Void})
		return 256*256
	end
	
	function Output_Callback_Get_Data(this::Object, output::Ptr{Void}, position::Int64, data::Array{UInt8,1}, metadata::Array{UInt8,1})
		
		size = min(256 * 256 - position, length(metadata))
		
		if size > 0
			metadata[1:size] .= 0b10000001
		end
		
		1
	end
	
end