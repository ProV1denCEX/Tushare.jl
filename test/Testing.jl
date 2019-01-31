#=
Testing:
- Julia version: 
- Author: Frontal_Temp
- Date: 2019-01-30
=#
push!(LOAD_PATH, ".\\src\\")

using Tushare
d_data = Tushare.get_stock_disclosure()
@show d_data

d_data = Tushare.get_stock_disclosure(Dict("ts_code" => "000001.sz"))
@show d_data

d_data = Tushare.get_stock_disclosure(Dict("ts_code" => "000001.sz"), s_fields = "ts_code")
@show d_data

d_data = Tushare.get_stock_disclosure(s_fields = "ts_code")
@show d_data

aaa = 1