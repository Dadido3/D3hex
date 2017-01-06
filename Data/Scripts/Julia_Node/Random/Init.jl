module Node_Test
	
	using PB, Logger, Node, Node_Julia
	
	type Object
		node_id::Int64
		
		output::Ptr{Node.Conn_Output}
		
		number::Int64
		
		function Object(node_id::Int64)
			this = new(node_id)
			node = Node.Get(this.node_id)
			
			this.output = Node_Julia.Output_Add(node, "Hello World", "Hi")
			Node_Julia.Output_Callback(this.output, "Get_Size", Output_Callback_Get_Size)
			Node_Julia.Output_Callback(this.output, "Get_Data", Output_Callback_Get_Data)
			
			finalizer(this, (t)->PB.Debug(string(t) * " finalized!"))
			
			this
		end
	end
	
	function Output_Callback_Get_Size(this::Object, output::Ptr{Void})
		
		#gc()
		
		#PB.Debug("Hi thar!")
		#PB.Debug(string(this))
		#Logger.Entry_Add_Error("Hey", "Test")
		this.number = this.number + 1
		return 1000000000#this.number
	end
	
	function fastrand(state::UInt)
		state $= state << 13
		state $= state >> 17
		state $= state << 5
		#state = (214013 * state + 2531011)
		return state, convert(UInt8, (state >> 16) & 0xFF)
	end
	
	function random_fastrand!(position::Int64, data::Array{UInt8,1})
		const chunk_size = 512
		
		chunk_number = div(position, chunk_size)
		chunk_position = chunk_number * chunk_size
		state = convert(UInt, chunk_position+1)
		# Omit first random values
		@simd for i in 1:10
			state, a = fastrand(state)
		end
		counter = chunk_size
		@simd for i in chunk_position:position-1
			state, a = fastrand(state)
			counter -= 1
		end
		
		@simd for i in 1:length(data)
			@inbounds state, data[i] = fastrand(state)
			counter -= 1
			if counter <= 0
				chunk_number += 1
				chunk_position = chunk_number * chunk_size
				state = convert(UInt, chunk_position+1)
				# Omit first random values
				@simd for i in 1:10
					state, a = fastrand(state)
				end
				counter = chunk_size
			end
		end
	end
	
	function random_mersenne!(position::Int64, data::Array{UInt8,1})
		const chunk_size = 1024
		
		chunk_number = div(position, chunk_size)
		chunk_position = chunk_number * chunk_size
		
		rng = MersenneTwister(chunk_position)
		counter = chunk_size
		@simd for i in chunk_position:position-1
			rand(rng, UInt8)
			counter -= 1
		end
		
		@simd for i in 1:length(data)
			@inbounds data[i] = rand(rng, UInt8)
			counter -= 1
			if counter <= 0
				chunk_number += 1
				chunk_position = chunk_number * chunk_size
				srand(rng, chunk_position)
				counter = chunk_size
			end
		end
	end
	
	function Output_Callback_Get_Data(this::Object, output::Ptr{Void}, position::Int64, data::Array{UInt8,1}, metadata::Array{UInt8,1})
		metadata .= 0b10000001
		
		random_fastrand!(position, data)
		
		1
	end
	
end