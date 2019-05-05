module Tushare
    using HTTP
    using JSON
    using DataFrames
    using Pkg
    import YAML

    # get token from Token.txt
    function get_token()
        s_dir = joinpath(pwd(), "Token.txt")
        isfile(s_dir) ? s_token = readline(s_dir) : s_token = nothing
        s_token
    end

    # Prototype of fetching data from api
    function fetch_data(s_api_name::String, d_params::Dict, s_fields::String, s_token::String)
        # Generate json
        d_json = Dict(
                  "api_name" => s_api_name,
                  "token" => s_token,
                  "params" => d_params,
                  "fields" => s_fields)
        s_json = JSON.json(d_json)
        conf = (readtimeout = 100, retry_non_idempotent = true, retries = 5)

        # Data Fetching
        c_data = nothing
        c_fields = nothing
        c_response = nothing
        c_raw = nothing
        local i = 0
        while i < 5
            try
                c_response = HTTP.post(TUSHARE_API, [], JSON.json(d_json); conf...)
                c_raw = JSON.Parser.parse(String(c_response.body))
            catch
                i += 1
            end

            # result check:
            #   nothing wrong: output
            #   response.code != 0 -> Connection is ok, Check api's inputs
            #   fetch failed -> API is Ok, Check Code! (will retry 5 times)
            if !HTTP.Messages.iserror(c_response) && c_raw[:"code"] == 0
                c_raw_data = c_raw[:"data"]
                c_data = c_raw_data[:"items"]
                c_fields = c_raw_data[:"fields"]
                break

            elseif c_raw[:"code"] != 0
                c_data = nothing
                c_fields = nothing
                i += 1
                error(String(c_raw[:"msg"]))

            else
                c_data = nothing
                c_fields = nothing
                i += 1
            end
        end
        c_data, c_fields
    end

    # ReOrgnize data to a python-like
    function reorgnize_data(c_data, c_fields)
        if Pkg.installed()["DataFrames"] >= v"0.18.0"
            df_data = DataFrame(Matrix{Any}(missing, length(c_data), length(c_fields)))
        else
            df_data = DataFrame(Any, size(c_data, 1), size(c_fields, 1))
        end
        names!(df_data, Symbol.(c_fields))

        for i in 1 : size(c_data, 1)
            for j in 1 : size(c_fields, 1)
                df_data[i, j] = c_data[i][j]
            end
        end

        df_data
    end

    function handle_get_data(d_params :: Dict, s_api :: String, s_fields :: String, s_token :: String)
        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields, s_token)

        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)
        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

      df_data
    end

    macro fun_generate()
        # start out with a blank quoted expression
        c_Exprs = quote end

        # read yaml config
        s_dir = joinpath(@__DIR__, "Tushare.yaml")
        open(s_dir) do io
            funs = YAML.load(io)

            # construct each function
            for ifun in funs
                fname = Symbol("get_$(ifun["type"])_$(ifun["name"])")

                # function definition generation
                blk = quote
                    export $(esc(fname))
                    $(esc(fname))(d_params = $(esc(ifun["default_param"])); s_api = $(esc(ifun["api"])), s_fields = $(esc(ifun["default_field"])), s_token = TOKEN) = handle_get_data(d_params, s_api, s_fields, s_token)
                end

                append!(c_Exprs.args, blk.args)
            end
        end
        c_Exprs
    end

    function __init__()
        global TUSHARE_API = "http://api.tushare.pro"
        global TOKEN = get_token()
    end

    @fun_generate

end