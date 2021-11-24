# POPSExtract

*A small tool to extract the pulse-height distribution from the single particle PEAK file of the POPS.*

## Installation

```julia
pkg> add git@github.com:mdp-aerosol-group/POPSExtract.git
```

## Dependencies

The binary extraction piece is written in Python (acknowledgement to Handix Scientific for sharing the code). I did not rewrite it in Julia. PyCall must have access to numpy and pandas.

```julia
using Conda
Conda.add(["numpy", "pandas"])
```

## Example Usage

Place the files from the POPS SD card in a directory and convert using the ```file2histogram``` function. The histogram will be computed for a specified duration, in the example below 1 min. 

```julia
using POPSExtract
using Dates
using CSV
using DataFrames

path = "F20211122/"
files = readdir(path)
peakfiles = filter(x -> split(x, "_") |> x -> x[1] == "Peak", files)
data = mapfoldl(vcat, peakfiles) do f
	println("Extract file: ", f)
	fx, tx = file2histogram(path*f, Minute(1))
	hcat(DataFrame(t = tx), DataFrame(fx',:auto))
end

data |> CSV.write("20211122_Peak.csv")
```
