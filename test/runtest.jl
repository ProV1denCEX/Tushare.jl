#=
Testing:
- Julia version: 
- Author: Frontal_Temp
- Date: 2019-01-30
=#
push!(LOAD_PATH, ".\\src\\")

using Tushare
using YAML
using Test

s_dir = ".\\src\\Tushare.yaml"
open(s_dir) do io
  funs = YAML.load(io)

  # construct each function
  for ifun in funs
      fname = Symbol("get_$(ifun["type"])_$(ifun["name"])")
      # function definition generation
      blk = quote
        @test $(fname)()
      end
      eval(blk)
  end
end
