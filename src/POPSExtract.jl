module POPSExtract

using PyCall
using Dates
using StatsBase

export extract_binary, file2histogram

function __init__()
    py"""
	import numpy as np
	import pandas as pd
	import struct
	import time
	from itertools import chain

	### flatten list function
	def fast_flatten(input_list):
		return list(chain.from_iterable(input_list))

	### extract binary function
	def extract_binary(_binary_):
		with open(_binary_, mode='rb') as file: 
			fileContent = file.read()
		
		file_length = len(fileContent) 
		line_index_start = 0 
		list_peakamplitude=[] 
		list_timestamps = [] 

		while file_length>line_index_start:
			line_index_end = line_index_start+12 # do this here to not have to do it again
			num_records, timestamp_val = struct.unpack('<Id',fileContent[line_index_start:line_index_end])
			num_elements = num_records*3
			line_record_end = line_index_end+(num_elements*4)
			chunk_data = struct.unpack('I'*num_elements,fileContent[line_index_end:line_record_end])
			chunk_data = np.asarray(chunk_data).reshape(-1,3) # turn into an array and reshaped, could be done in a single step
		
			# make an empty array to do the timestamp shenanigans
			# dt = time between each record except for the first entry
			# first dt is the time since the timestamp_val, float time
			chunk_timestamp = np.empty(len(chunk_data),dtype='float64') # empty array with float precision
		
			chunk_timestamp = np.cumsum(chunk_data[:,2]/1e6) # cumulative sum of the dt values, divide by 1e6 is because dt is in microseconds
		
			chunk_timestamp += timestamp_val # adding the initial timestamp of the data record to get the true timestamp
		
			# list comprehension is faster than numpy
			chunk_timestamp = chunk_timestamp[:].tolist() # converting to list
			chunk_amplitude = chunk_data[:,0].tolist() # converting to a list
		
			# the two outputs PeakAmplitude and the Timestamp
			# these are lists of lists
			list_peakamplitude.append(chunk_amplitude)
			list_timestamps.append(chunk_timestamp)
			line_index_start = line_record_end # reset things
		
		# at the end of this the lists of lists need flattening
		t = time.time()
		PeakAmplitude = fast_flatten(list_peakamplitude)
		Timestamp = fast_flatten(list_timestamps)
		elapsed = time.time() - t
		
		return PeakAmplitude,Timestamp
	"""
end
    
extract_binary(file) = py"extract_binary"(file)


function file2histogram(file, duration)
	data = extract_binary(file)

	ph = data[1]
	t = unix2datetime.(data[2])
	s = t[1]:duration:t[end]

	function get_hist(i)
		ii = (t .> s[i]) .& (t .< s[i+1])
		return fit(Histogram, ph[ii], 1:65536,closed = :left) |> x -> x.weights
	end

	f = mapfoldl(get_hist, hcat, 1:length(s)-1)
	return f, collect(s[1:end-1])
end

end
