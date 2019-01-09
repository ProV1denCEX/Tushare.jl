module Tushare
    # usings
    using HTTP
    using JSON
    using DataFrames
    using Missings

    # exports
    export get_bond_HIBOR
    export get_bond_LIBOR
    export get_bond_LPR
    export get_bond_SHIBOR
    export get_bond_SHIBORpricing
    export get_coin_BTmarketValue
    export get_coin_BTpriceVol
    export get_coin_daily
    export get_coin_exchange
    export get_coin_exchangeAnn
    export get_coin_exchangeTwitter
    export get_coin_fee
    export get_coin_indexConst
    export get_coin_kolTwitter
    export get_coin_list
    export get_coin_newsBSJ
    export get_coin_marketValuedaily
    export get_coin_newsBTC
    export get_coin_newsJinse
    export get_coin_pair
    export get_fund_company
    export get_fund_daily
    export get_fund_dividend
    export get_fund_info
    export get_fund_netvalue
    export get_fund_portfolio
    export get_future_WSR
    export get_future_basic
    export get_future_daily
    export get_future_holding
    export get_future_calendar
    export get_future_settleInfo
    export get_option_info
    export get_option_daily
    export get_stock_new
    export get_stock_list
    export get_stock_audit
    export get_stock_daily
    export get_stock_pledge
    export get_stock_mainbz
    export get_stock_concept
    export get_stock_HSconst
    export get_stock_suspend
    export get_stock_delimit
    export get_stock_instinfo
    export get_stock_cashflow
    export get_stock_top10GGT
    export get_stock_HSGTflow
    export get_stock_dividend
    export get_stock_calendar
    export get_stock_top10HSGT
    export get_stock_adjFactor
    export get_stock_dailyBasic
    export get_stock_blockTrade
    export get_stock_repurchase
    export get_stock_Hotest
    export get_stock_companyInfo
    export get_stock_pledgeDetail
    export get_stock_marginDetail
    export get_stock_finIndicator
    export get_stock_top10Holders
    export get_stock_balanceSheet
    export get_stock_marginBalance
    export get_stock_conceptDetail
    export get_stock_revenueForcast
    export get_stock_revenueExpress
    export get_stock_oldCompanyname
    export get_stock_incomeStatement
    export get_stock_top10Floatholders
    export get_other_news
    export get_other_BOdaily
    export get_other_BOweekly
    export get_other_cctvNews
    export get_other_BOmonthly
    export get_other_filmRecord
    export get_other_cinermaDaily
    export get_index_info
    export get_index_daily
    export get_index_basicDaily
    export get_index_weightMonthly
    export get_other_twTechincome
    export get_other_twTechincomeDetail

    ###################### Prototype #########################

    # get token from Token.txt
    function get_token()
        (isfile("Token.txt") ? s_Token = readline("Token.txt")
         : nothing)
    end

    # Prototype of fetching data from api
    function fetch_data(s_api_name::String, d_params::Dict, s_fields::String)
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
                c_response = HTTP.post(s_tushare_api, [], JSON.json(d_json); conf...)
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
        df_data = DataFrame(Any, length(c_data), length(c_fields))
        names!(df_data, Symbol.(c_fields))

        for i in 1 : length(c_data)
            for j in 1 : length(c_fields)
                df_data[i, j] = c_data[i][j]
            end
        end

        df_data
    end


    ###################### Basic Data #########################

    # Get Stock List
    #params:        名称 	类型 	必选 	描述
    #     is_hs 	      str 	N 	是否沪深港通标的，N否 H沪股通 S深股通
    #     list_status 	  str 	N 	上市状态： L上市 D退市 P暂停上市
    #     exchange 	      str 	N 	交易所 SSE上交所 SZSE深交所 HKEX港交所
    # fields:    名称 	类型 	描述
    # ts_code 	        str 	TS代码
    # symbol 	        str 	股票代码
    # name 	            str 	股票名称
    # area 	            str 	所在地域
    # industry 	        str 	所属行业
    # fullname 	        str 	股票全称
    # enname 	      str 	英文全称
    # market 	      str 	市场类型 （主板/中小板/创业板）
    # exchange 	        str 	交易所代码
    # curr_type 	str 	交易货币
    # list_status 	str 	上市状态： L上市 D退市 P暂停上市
    # list_date 	str 	上市日期
    # delist_date 	str 	退市日期
    # is_hs 	str 	是否沪深港通标的，N否 H沪股通 S深股通
    function get_stock_list(;s_api::String = "stock_basic",
        d_params :: Dict = Dict(), s_fields :: String = "ts_code, symbol, name,
        area, industry, fullname, enname, market, exchange, curr_type, list_status,
        list_date, delist_date, is_hs")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Stock Trading Calendar
    #     名称 	类型 	必选 	描述
    # exchange 	str 	N 	交易所 SSE上交所 SZSE深交所
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # is_open 	int 	N 	是否交易 0休市 1交易
    # 名称 	类型 	描述
    # exchange 	str 	交易所 SSE上交所 SZSE深交所
    # cal_date 	str 	日历日期
    # is_open 	int 	是否交易 0休市 1交易
    # pretrade_date 	str 	上一个交易日
    function get_stock_calendar(;s_api::String = "trade_cal",
        d_params :: Dict = Dict("exchange" => "SSE"), s_fields :: String = "exchange, cal_date,
        is_open")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Company's Basic Info
    # 名称 	类型 	默认显示 	描述
    # exchange 	str 	N 	交易所代码 ，SSE上交所 SZSE深交所 ，默认SSE
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	股票代码
    # exchange 	str 	Y 	交易所代码 ，SSE上交所 SZSE深交所
    # chairman 	str 	Y 	法人代表
    # manager 	str 	Y 	总经理
    # secretary 	str 	Y 	董秘
    # reg_capital 	float 	Y 	注册资本
    # setup_date 	str 	Y 	注册日期
    # province 	str 	Y 	所在省份
    # city 	str 	Y 	所在城市
    # introduction 	str 	Y 	公司介绍
    # website 	str 	Y 	公司主页
    # email 	str 	Y 	电子邮件
    # office 	str 	Y 	办公室
    # employees 	int 	Y 	员工人数
    # main_business 	str 	Y 	主要业务及产品
    # business_scope 	str 	Y 	经营范围
    function get_stock_companyInfo(;s_api::String = "stock_company",
        d_params :: Dict = Dict("exchange" => "SSE"), s_fields :: String = "ts_code, exchange,
        chairman, manager, secretary, reg_capital, setup_date, province, city, introduction,
        website, email, office, employees, main_business, business_scope")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Company's Old name and changes' reason
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	TS代码
    # start_date 	str 	N 	公告开始日期
    # end_date 	str 	N 	公告结束日期
    # ts_code 	str 	Y 	TS代码
    # name 	str 	Y 	证券名称
    # start_date 	str 	Y 	开始日期
    # end_date 	str 	Y 	结束日期
    # ann_date 	str 	Y 	公告日期
    # change_reason 	str 	Y 	变更原因
    function get_stock_oldCompanyname(;s_api::String = "namechange",
        d_params :: Dict = Dict(), s_fields :: String = "ts_code, name, start_date,
        end_date, ann_date, change_reason")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get HS const stocks 获取沪股通、深股通成分数据
    # hs_type 	str 	Y 	类型SH沪股通SZ深股通
    # is_new 	str 	N 	是否最新 1 是 0 否 (默认1)
    # ts_code 	str 	Y 	TS代码
    # hs_type 	str 	Y 	沪深港通类型SH沪SZ深
    # in_date 	str 	Y 	纳入日期
    # out_date 	str 	Y 	剔除日期
    # is_new 	str 	Y 	是否最新 1是0否
    function get_stock_HSconst(d_params :: Dict = Dict("hs_type" => "SH");
        s_api::String = "hs_const",
        s_fields :: String = "ts_code,
        hs_type, in_date, out_date, is_new")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get New listed Stocks
    #     start_date 	str 	N 	上网发行开始日期
    #     end_date 	str 	N 	上网发行结束日期
    #     名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS股票代码
    # sub_code 	str 	Y 	申购代码
    # name 	str 	Y 	名称
    # ipo_date 	str 	Y 	上网发行日期
    # issue_date 	str 	Y 	上市日期
    # amount 	float 	Y 	发行总量（万股）
    # market_amount 	float 	Y 	上网发行总量（万股）
    # price 	float 	Y 	发行价格
    # pe 	float 	Y 	市盈率
    # limit_amount 	float 	Y 	个人申购上限（万股）
    # funds 	float 	Y 	募集资金（亿元）
    # ballot 	float 	Y 	中签率
    function get_stock_new(;s_api::String = "new_share",
        d_params :: Dict = Dict(), s_fields :: String = "ts_code, sub_code, name,
        ipo_date, issue_date, amount, market_amount, price, pe, limit_amount, funds, ballot")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Income Statement Data
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	股票代码
    # ann_date 	str 	N 	公告日期
    # start_date 	str 	N 	报告期开始日期
    # end_date 	str 	N 	报告期结束日期
    # period 	str 	N 	报告期(每个季度最后一天的日期，比如20171231表示年报)
    # report_type 	str 	N 	报告类型： 参考下表说明
    # comp_type 	str 	N 	公司类型：1一般工商业 2银行 3保险 4证券
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS股票代码
    # ann_date 	str 	公告日期
    # f_ann_date 	str 	实际公告日期，即发生过数据变更的最终日期
    # end_date 	str 	报告期
    # report_type 	str 	报告类型： 参考下表说明
    # comp_type 	str 	公司类型：1一般工商业 2银行 3保险 4证券
    # basic_eps 	float 	基本每股收益
    # diluted_eps 	float 	稀释每股收益
    # total_revenue 	float 	营业总收入 (元，下同)
    # revenue 	float 	营业收入
    # int_income 	float 	利息收入
    # prem_earned 	float 	已赚保费
    # comm_income 	float 	手续费及佣金收入
    # n_commis_income 	float 	手续费及佣金净收入
    # n_oth_income 	float 	其他经营净收益
    # n_oth_b_income 	float 	加:其他业务净收益
    # prem_income 	float 	保险业务收入
    # out_prem 	float 	减:分出保费
    # une_prem_reser 	float 	提取未到期责任准备金
    # reins_income 	float 	其中:分保费收入
    # n_sec_tb_income 	float 	代理买卖证券业务净收入
    # n_sec_uw_income 	float 	证券承销业务净收入
    # n_asset_mg_income 	float 	受托客户资产管理业务净收入
    # oth_b_income 	float 	其他业务收入
    # fv_value_chg_gain 	float 	加:公允价值变动净收益
    # invest_income 	float 	加:投资净收益
    # ass_invest_income 	float 	其中:对联营企业和合营企业的投资收益
    # forex_gain 	float 	加:汇兑净收益
    # total_cogs 	float 	营业总成本
    # oper_cost 	float 	减:营业成本
    # int_exp 	float 	减:利息支出
    # comm_exp 	float 	减:手续费及佣金支出
    # biz_tax_surchg 	float 	减:营业税金及附加
    # sell_exp 	float 	减:销售费用
    # admin_exp 	float 	减:管理费用
    # fin_exp 	float 	减:财务费用
    # assets_impair_loss 	float 	减:资产减值损失
    # prem_refund 	float 	退保金
    # compens_payout 	float 	赔付总支出
    # reser_insur_liab 	float 	提取保险责任准备金
    # div_payt 	float 	保户红利支出
    # reins_exp 	float 	分保费用
    # oper_exp 	float 	营业支出
    # compens_payout_refu 	float 	减:摊回赔付支出
    # insur_reser_refu 	float 	减:摊回保险责任准备金
    # reins_cost_refund 	float 	减:摊回分保费用
    # other_bus_cost 	float 	其他业务成本
    # operate_profit 	float 	营业利润
    # non_oper_income 	float 	加:营业外收入
    # non_oper_exp 	float 	减:营业外支出
    # nca_disploss 	float 	其中:减:非流动资产处置净损失
    # total_profit 	float 	利润总额
    # income_tax 	float 	所得税费用
    # n_income 	float 	净利润(含少数股东损益)
    # n_income_attr_p 	float 	净利润(不含少数股东损益)
    # minority_gain 	float 	少数股东损益
    # oth_compr_income 	float 	其他综合收益
    # t_compr_income 	float 	综合收益总额
    # compr_inc_attr_p 	float 	归属于母公司(或股东)的综合收益总额
    # compr_inc_attr_m_s 	float 	归属于少数股东的综合收益总额
    # ebit 	float 	息税前利润
    # ebitda 	float 	息税折旧摊销前利润
    # insurance_exp 	float 	保险业务支出
    # undist_profit 	float 	年初未分配利润
    # distable_profit 	float 	可分配利润
    #
    # 主要报表类型说明
    # 代码 	类型 	说明
    # 1 	合并报表 	上市公司最新报表（默认）
    # 2 	单季合并 	单一季度的合并报表
    # 3 	调整单季合并表 	调整后的单季合并报表（如果有）
    # 4 	调整合并报表 	本年度公布上年同期的财务报表数据，报告期为上年度
    # 5 	调整前合并报表 	数据发生变更，将原数据进行保留，即调整前的原数据
    # 6 	母公司报表 	该公司母公司的财务报表数据
    # 7 	母公司单季表 	母公司的单季度表
    # 8 	母公司调整单季表 	母公司调整后的单季表
    # 9 	母公司调整表 	该公司母公司的本年度公布上年同期的财务报表数据
    # 10 	母公司调整前报表 	母公司调整之前的原始财务报表数据
    # 11 	调整前合并报表 	调整之前合并报表原数据
    # 12 	母公司调整前报表 	母公司报表发生变更前保留的原数据
    function get_stock_incomeStatement(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "income", s_fields :: String = "ts_code,
        ann_date, f_ann_date, end_date, report_type, comp_type, basic_eps, diluted_eps,
        total_revenue, revenue, int_income, prem_earned, comm_income, n_commis_income,
        n_oth_income, n_oth_b_income, prem_income, out_prem, une_prem_reser, reins_income,
        n_sec_tb_income, n_sec_uw_income, n_asset_mg_income, oth_b_income, fv_value_chg_gain,
        invest_income, ass_invest_income, forex_gain, total_cogs, oper_cost, int_exp,
        comm_exp, biz_tax_surchg, sell_exp, admin_exp, fin_exp, assets_impair_loss, prem_refund,
        compens_payout, reser_insur_liab, div_payt, reins_exp, oper_exp, compens_payout_refu,
        insur_reser_refu, reins_cost_refund, other_bus_cost, operate_profit, non_oper_income,
        non_oper_exp, nca_disploss, total_profit, income_tax, n_income, n_income_attr_p,
        minority_gain, oth_compr_income, t_compr_income, compr_inc_attr_p, compr_inc_attr_m_s,
        ebit, ebitda, insurance_exp, undist_profit, distable_profit")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Balance Sheet
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	股票代码
    # ann_date 	str 	N 	公告日期
    # start_date 	str 	N 	报告期开始日期
    # end_date 	str 	N 	报告期结束日期
    # period 	str 	N 	报告期(每个季度最后一天的日期，比如20171231表示年报)
    # report_type 	str 	N 	报告类型：见下方详细说明
    # comp_type 	str 	N 	公司类型：1一般工商业 2银行 3保险 4证券
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS股票代码
    # ann_date 	str 	公告日期
    # f_ann_date 	str 	实际公告日期
    # end_date 	str 	报告期
    # report_type 	str 	报表类型：见下方详细说明
    # comp_type 	str 	公司类型：1一般工商业 2银行 3保险 4证券
    # total_share 	float 	期末总股本
    # cap_rese 	float 	资本公积金 (元，下同)
    # undistr_porfit 	float 	未分配利润
    # surplus_rese 	float 	盈余公积金
    # special_rese 	float 	专项储备
    # money_cap 	float 	货币资金
    # trad_asset 	float 	交易性金融资产
    # notes_receiv 	float 	应收票据
    # accounts_receiv 	float 	应收账款
    # oth_receiv 	float 	其他应收款
    # prepayment 	float 	预付款项
    # div_receiv 	float 	应收股利
    # int_receiv 	float 	应收利息
    # inventories 	float 	存货
    # amor_exp 	float 	长期待摊费用
    # nca_within_1y 	float 	一年内到期的非流动资产
    # sett_rsrv 	float 	结算备付金
    # loanto_oth_bank_fi 	float 	拆出资金
    # premium_receiv 	float 	应收保费
    # reinsur_receiv 	float 	应收分保账款
    # reinsur_res_receiv 	float 	应收分保合同准备金
    # pur_resale_fa 	float 	买入返售金融资产
    # oth_cur_assets 	float 	其他流动资产
    # total_cur_assets 	float 	流动资产合计
    # fa_avail_for_sale 	float 	可供出售金融资产
    # htm_invest 	float 	持有至到期投资
    # lt_eqt_invest 	float 	长期股权投资
    # invest_real_estate 	float 	投资性房地产
    # time_deposits 	float 	定期存款
    # oth_assets 	float 	其他资产
    # lt_rec 	float 	长期应收款
    # fix_assets 	float 	固定资产
    # cip 	float 	在建工程
    # const_materials 	float 	工程物资
    # fixed_assets_disp 	float 	固定资产清理
    # produc_bio_assets 	float 	生产性生物资产
    # oil_and_gas_assets 	float 	油气资产
    # intan_assets 	float 	无形资产
    # r_and_d 	float 	研发支出
    # goodwill 	float 	商誉
    # lt_amor_exp 	float 	长期待摊费用
    # defer_tax_assets 	float 	递延所得税资产
    # decr_in_disbur 	float 	发放贷款及垫款
    # oth_nca 	float 	其他非流动资产
    # total_nca 	float 	非流动资产合计
    # cash_reser_cb 	float 	现金及存放中央银行款项
    # depos_in_oth_bfi 	float 	存放同业和其它金融机构款项
    # prec_metals 	float 	贵金属
    # deriv_assets 	float 	衍生金融资产
    # rr_reins_une_prem 	float 	应收分保未到期责任准备金
    # rr_reins_outstd_cla 	float 	应收分保未决赔款准备金
    # rr_reins_lins_liab 	float 	应收分保寿险责任准备金
    # rr_reins_lthins_liab 	float 	应收分保长期健康险责任准备金
    # refund_depos 	float 	存出保证金
    # ph_pledge_loans 	float 	保户质押贷款
    # refund_cap_depos 	float 	存出资本保证金
    # indep_acct_assets 	float 	独立账户资产
    # client_depos 	float 	其中：客户资金存款
    # client_prov 	float 	其中：客户备付金
    # transac_seat_fee 	float 	其中:交易席位费
    # invest_as_receiv 	float 	应收款项类投资
    # total_assets 	float 	资产总计
    # lt_borr 	float 	长期借款
    # st_borr 	float 	短期借款
    # cb_borr 	float 	向中央银行借款
    # depos_ib_deposits 	float 	吸收存款及同业存放
    # loan_oth_bank 	float 	拆入资金
    # trading_fl 	float 	交易性金融负债
    # notes_payable 	float 	应付票据
    # acct_payable 	float 	应付账款
    # adv_receipts 	float 	预收款项
    # sold_for_repur_fa 	float 	卖出回购金融资产款
    # comm_payable 	float 	应付手续费及佣金
    # payroll_payable 	float 	应付职工薪酬
    # taxes_payable 	float 	应交税费
    # int_payable 	float 	应付利息
    # div_payable 	float 	应付股利
    # oth_payable 	float 	其他应付款
    # acc_exp 	float 	预提费用
    # deferred_inc 	float 	递延收益
    # st_bonds_payable 	float 	应付短期债券
    # payable_to_reinsurer 	float 	应付分保账款
    # rsrv_insur_cont 	float 	保险合同准备金
    # acting_trading_sec 	float 	代理买卖证券款
    # acting_uw_sec 	float 	代理承销证券款
    # non_cur_liab_due_1y 	float 	一年内到期的非流动负债
    # oth_cur_liab 	float 	其他流动负债
    # total_cur_liab 	float 	流动负债合计
    # bond_payable 	float 	应付债券
    # lt_payable 	float 	长期应付款
    # specific_payables 	float 	专项应付款
    # estimated_liab 	float 	预计负债
    # defer_tax_liab 	float 	递延所得税负债
    # defer_inc_non_cur_liab 	float 	递延收益-非流动负债
    # oth_ncl 	float 	其他非流动负债
    # total_ncl 	float 	非流动负债合计
    # depos_oth_bfi 	float 	同业和其它金融机构存放款项
    # deriv_liab 	float 	衍生金融负债
    # depos 	float 	吸收存款
    # agency_bus_liab 	float 	代理业务负债
    # oth_liab 	float 	其他负债
    # prem_receiv_adva 	float 	预收保费
    # depos_received 	float 	存入保证金
    # ph_invest 	float 	保户储金及投资款
    # reser_une_prem 	float 	未到期责任准备金
    # reser_outstd_claims 	float 	未决赔款准备金
    # reser_lins_liab 	float 	寿险责任准备金
    # reser_lthins_liab 	float 	长期健康险责任准备金
    # indept_acc_liab 	float 	独立账户负债
    # pledge_borr 	float 	其中:质押借款
    # indem_payable 	float 	应付赔付款
    # policy_div_payable 	float 	应付保单红利
    # total_liab 	float 	负债合计
    # treasury_share 	float 	减:库存股
    # ordin_risk_reser 	float 	一般风险准备
    # forex_differ 	float 	外币报表折算差额
    # invest_loss_unconf 	float 	未确认的投资损失
    # minority_int 	float 	少数股东权益
    # total_hldr_eqy_exc_min_int 	float 	股东权益合计(不含少数股东权益)
    # total_hldr_eqy_inc_min_int 	float 	股东权益合计(含少数股东权益)
    # total_liab_hldr_eqy 	float 	负债及股东权益总计
    # lt_payroll_payable 	float 	长期应付职工薪酬
    # oth_comp_income 	float 	其他综合收益
    # oth_eqt_tools 	float 	其他权益工具
    # oth_eqt_tools_p_shr 	float 	其他权益工具(优先股)
    # lending_funds 	float 	融出资金
    # acc_receivable 	float 	应收款项
    # st_fin_payable 	float 	应付短期融资款
    # payables 	float 	应付款项
    # hfs_assets 	float 	持有待售的资产
    # hfs_sales 	float 	持有待售的负债
    #
    # 主要报表类型说明
    # 代码 	类型 	说明
    # 1 	合并报表 	上市公司最新报表（默认）
    # 2 	单季合并 	单一季度的合并报表
    # 3 	调整单季合并表 	调整后的单季合并报表（如果有）
    # 4 	调整合并报表 	本年度公布上年同期的财务报表数据，报告期为上年度
    # 5 	调整前合并报表 	数据发生变更，将原数据进行保留，即调整前的原数据
    # 6 	母公司报表 	该公司母公司的财务报表数据
    # 7 	母公司单季表 	母公司的单季度表
    # 8 	母公司调整单季表 	母公司调整后的单季表
    # 9 	母公司调整表 	该公司母公司的本年度公布上年同期的财务报表数据
    # 10 	母公司调整前报表 	母公司调整之前的原始财务报表数据
    # 11 	调整前合并报表 	调整之前合并报表原数据
    # 12 	母公司调整前报表 	母公司报表发生变更前保留的原数据
    function get_stock_balanceSheet(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "balancesheet", s_fields :: String = "ts_code,
        ann_date, f_ann_date, end_date, report_type, comp_type, total_share, cap_rese,
        undistr_porfit, surplus_rese, money_cap, trad_asset, notes_receiv, accounts_receiv,
        oth_receiv, prepayment, div_receiv, int_receiv, inventories, amor_exp, nca_within_1y,
        sett_rsrv, loanto_oth_bank_fi, premium_receiv, reinsur_receiv, reinsur_res_receiv,
        pur_resale_fa, oth_cur_assets, total_cur_assets, fa_avail_for_sale, htm_invest,
        lt_eqt_invest, invest_real_estate, time_deposits, oth_assets, lt_rec, fix_assets,
        cip, const_materials, fixed_assets_disp, produc_bio_assets, oil_and_gas_assets,
        intan_assets, r_and_d, goodwill, lt_amor_exp, defer_tax_assets, decr_in_disbur,
        oth_nca, total_nca, cash_reser_cb, depos_in_oth_bfi, prec_metals, deriv_assets,
        rr_reins_une_prem, rr_reins_outstd_cla, rr_reins_lins_liab, rr_reins_lthins_liab,
        refund_depos, ph_pledge_loans, refund_cap_depos, indep_acct_assets, client_depos,
        client_prov, transac_seat_fee, invest_as_receiv, total_assets, lt_borr, st_borr,
        cb_borr, depos_ib_deposits, loan_oth_bank, trading_fl, notes_payable, acct_payable,
        adv_receipts, sold_for_repur_fa, comm_payable, payroll_payable, taxes_payable, int_payable,
        div_payable, oth_payable, acc_exp, deferred_inc, st_bonds_payable, payable_to_reinsurer,
        rsrv_insur_cont, acting_trading_sec, acting_uw_sec, non_cur_liab_due_1y, oth_cur_liab,
        total_cur_liab, bond_payable, lt_payable, specific_payables, estimated_liab,
        defer_tax_liab, defer_inc_non_cur_liab, oth_ncl, total_ncl, depos_oth_bfi,
        deriv_liab, depos, agency_bus_liab, oth_liab, prem_receiv_adva, depos_received,
        ph_invest, reser_une_prem, reser_outstd_claims, reser_lins_liab, reser_lthins_liab,
        indept_acc_liab, pledge_borr, indem_payable, policy_div_payable, total_liab,
        treasury_share, ordin_risk_reser, forex_differ, invest_loss_unconf, minority_int,
        total_hldr_eqy_exc_min_int, total_hldr_eqy_inc_min_int, total_liab_hldr_eqy,
        lt_payroll_payable, oth_comp_income, oth_eqt_tools, oth_eqt_tools_p_shr,
        lending_funds, acc_receivable, st_fin_payable, payables, hfs_assets, hfs_sales")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get cashflow sheet
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	股票代码
    # ann_date 	str 	N 	公告日期
    # start_date 	str 	N 	报告期开始日期
    # end_date 	str 	N 	报告期结束日期
    # period 	str 	N 	报告期(每个季度最后一天的日期，比如20171231表示年报)
    # report_type 	str 	N 	报告类型：见下方详细说明
    # comp_type 	str 	N 	公司类型：1一般工商业 2银行 3保险 4证券
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS股票代码
    # ann_date 	str 	公告日期
    # f_ann_date 	str 	实际公告日期
    # end_date 	str 	报告期
    # comp_type 	str 	公司类型：1一般工商业 2银行 3保险 4证券
    # report_type 	str 	报表类型：见下方详细说明
    # net_profit 	float 	净利润 (元，下同)
    # finan_exp 	float 	财务费用
    # c_fr_sale_sg 	float 	销售商品、提供劳务收到的现金
    # recp_tax_rends 	float 	收到的税费返还
    # n_depos_incr_fi 	float 	客户存款和同业存放款项净增加额
    # n_incr_loans_cb 	float 	向中央银行借款净增加额
    # n_inc_borr_oth_fi 	float 	向其他金融机构拆入资金净增加额
    # prem_fr_orig_contr 	float 	收到原保险合同保费取得的现金
    # n_incr_insured_dep 	float 	保户储金净增加额
    # n_reinsur_prem 	float 	收到再保业务现金净额
    # n_incr_disp_tfa 	float 	处置交易性金融资产净增加额
    # ifc_cash_incr 	float 	收取利息和手续费净增加额
    # n_incr_disp_faas 	float 	处置可供出售金融资产净增加额
    # n_incr_loans_oth_bank 	float 	拆入资金净增加额
    # n_cap_incr_repur 	float 	回购业务资金净增加额
    # c_fr_oth_operate_a 	float 	收到其他与经营活动有关的现金
    # c_inf_fr_operate_a 	float 	经营活动现金流入小计
    # c_paid_goods_s 	float 	购买商品、接受劳务支付的现金
    # c_paid_to_for_empl 	float 	支付给职工以及为职工支付的现金
    # c_paid_for_taxes 	float 	支付的各项税费
    # n_incr_clt_loan_adv 	float 	客户贷款及垫款净增加额
    # n_incr_dep_cbob 	float 	存放央行和同业款项净增加额
    # c_pay_claims_orig_inco 	float 	支付原保险合同赔付款项的现金
    # pay_handling_chrg 	float 	支付手续费的现金
    # pay_comm_insur_plcy 	float 	支付保单红利的现金
    # oth_cash_pay_oper_act 	float 	支付其他与经营活动有关的现金
    # st_cash_out_act 	float 	经营活动现金流出小计
    # n_cashflow_act 	float 	经营活动产生的现金流量净额
    # oth_recp_ral_inv_act 	float 	收到其他与投资活动有关的现金
    # c_disp_withdrwl_invest 	float 	收回投资收到的现金
    # c_recp_return_invest 	float 	取得投资收益收到的现金
    # n_recp_disp_fiolta 	float 	处置固定资产、无形资产和其他长期资产收回的现金净额
    # n_recp_disp_sobu 	float 	处置子公司及其他营业单位收到的现金净额
    # stot_inflows_inv_act 	float 	投资活动现金流入小计
    # c_pay_acq_const_fiolta 	float 	购建固定资产、无形资产和其他长期资产支付的现金
    # c_paid_invest 	float 	投资支付的现金
    # n_disp_subs_oth_biz 	float 	取得子公司及其他营业单位支付的现金净额
    # oth_pay_ral_inv_act 	float 	支付其他与投资活动有关的现金
    # n_incr_pledge_loan 	float 	质押贷款净增加额
    # stot_out_inv_act 	float 	投资活动现金流出小计
    # n_cashflow_inv_act 	float 	投资活动产生的现金流量净额
    # c_recp_borrow 	float 	取得借款收到的现金
    # proc_issue_bonds 	float 	发行债券收到的现金
    # oth_cash_recp_ral_fnc_act 	float 	收到其他与筹资活动有关的现金
    # stot_cash_in_fnc_act 	float 	筹资活动现金流入小计
    # free_cashflow 	float 	企业自由现金流量
    # c_prepay_amt_borr 	float 	偿还债务支付的现金
    # c_pay_dist_dpcp_int_exp 	float 	分配股利、利润或偿付利息支付的现金
    # incl_dvd_profit_paid_sc_ms 	float 	其中:子公司支付给少数股东的股利、利润
    # oth_cashpay_ral_fnc_act 	float 	支付其他与筹资活动有关的现金
    # stot_cashout_fnc_act 	float 	筹资活动现金流出小计
    # n_cash_flows_fnc_act 	float 	筹资活动产生的现金流量净额
    # eff_fx_flu_cash 	float 	汇率变动对现金的影响
    # n_incr_cash_cash_equ 	float 	现金及现金等价物净增加额
    # c_cash_equ_beg_period 	float 	期初现金及现金等价物余额
    # c_cash_equ_end_period 	float 	期末现金及现金等价物余额
    # c_recp_cap_contrib 	float 	吸收投资收到的现金
    # incl_cash_rec_saims 	float 	其中:子公司吸收少数股东投资收到的现金
    # uncon_invest_loss 	float 	未确认投资损失
    # prov_depr_assets 	float 	加:资产减值准备
    # depr_fa_coga_dpba 	float 	固定资产折旧、油气资产折耗、生产性生物资产折旧
    # amort_intang_assets 	float 	无形资产摊销
    # lt_amort_deferred_exp 	float 	长期待摊费用摊销
    # decr_deferred_exp 	float 	待摊费用减少
    # incr_acc_exp 	float 	预提费用增加
    # loss_disp_fiolta 	float 	处置固定、无形资产和其他长期资产的损失
    # loss_scr_fa 	float 	固定资产报废损失
    # loss_fv_chg 	float 	公允价值变动损失
    # invest_loss 	float 	投资损失
    # decr_def_inc_tax_assets 	float 	递延所得税资产减少
    # incr_def_inc_tax_liab 	float 	递延所得税负债增加
    # decr_inventories 	float 	存货的减少
    # decr_oper_payable 	float 	经营性应收项目的减少
    # incr_oper_payable 	float 	经营性应付项目的增加
    # others 	float 	其他
    # im_net_cashflow_oper_act 	float 	经营活动产生的现金流量净额(间接法)
    # conv_debt_into_cap 	float 	债务转为资本
    # conv_copbonds_due_within_1y 	float 	一年内到期的可转换公司债券
    # fa_fnc_leases 	float 	融资租入固定资产
    # end_bal_cash 	float 	现金的期末余额
    # beg_bal_cash 	float 	减:现金的期初余额
    # end_bal_cash_equ 	float 	加:现金等价物的期末余额
    # beg_bal_cash_equ 	float 	减:现金等价物的期初余额
    # im_n_incr_cash_equ 	float 	现金及现金等价物净增加额(间接法)
    #
    # 主要报表类型说明
    # 代码 	类型 	说明
    # 1 	合并报表 	上市公司最新报表（默认）
    # 2 	单季合并 	单一季度的合并报表
    # 3 	调整单季合并表 	调整后的单季合并报表（如果有）
    # 4 	调整合并报表 	本年度公布上年同期的财务报表数据，报告期为上年度
    # 5 	调整前合并报表 	数据发生变更，将原数据进行保留，即调整前的原数据
    # 6 	母公司报表 	该公司母公司的财务报表数据
    # 7 	母公司单季表 	母公司的单季度表
    # 8 	母公司调整单季表 	母公司调整后的单季表
    # 9 	母公司调整表 	该公司母公司的本年度公布上年同期的财务报表数据
    # 10 	母公司调整前报表 	母公司调整之前的原始财务报表数据
    # 11 	调整前合并报表 	调整之前合并报表原数据
    # 12 	母公司调整前报表 	母公司报表发生变更前保留的原数据
    function get_stock_cashflow(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "cashflow",
        s_fields :: String = "
        ts_code,
        ann_date,
        f_ann_date,
        end_date,
        comp_type,
        report_type,
        net_profit,
        finan_exp,
        c_fr_sale_sg,
        recp_tax_rends,
        n_depos_incr_fi,
        n_incr_loans_cb,
        n_inc_borr_oth_fi,
        prem_fr_orig_contr,
        n_incr_insured_dep,
        n_reinsur_prem,
        n_incr_disp_tfa,
        ifc_cash_incr,
        n_incr_disp_faas,
        n_incr_loans_oth_bank,
        n_cap_incr_repur,
        c_fr_oth_operate_a,
        c_inf_fr_operate_a,
        c_paid_goods_s,
        c_paid_to_for_empl,
        c_paid_for_taxes,
        n_incr_clt_loan_adv,
        n_incr_dep_cbob,
        c_pay_claims_orig_inco,
        pay_handling_chrg,
        pay_comm_insur_plcy,
        oth_cash_pay_oper_act,
        st_cash_out_act,
        n_cashflow_act,
        oth_recp_ral_inv_act,
        c_disp_withdrwl_invest,
        c_recp_return_invest,
        n_recp_disp_fiolta,
        n_recp_disp_sobu,
        stot_inflows_inv_act,
        c_pay_acq_const_fiolta,
        c_paid_invest,
        n_disp_subs_oth_biz,
        oth_pay_ral_inv_act,
        n_incr_pledge_loan,
        stot_out_inv_act,
        n_cashflow_inv_act,
        c_recp_borrow,
        proc_issue_bonds,
        oth_cash_recp_ral_fnc_act,
        stot_cash_in_fnc_act,
        free_cashflow,
        c_prepay_amt_borr,
        c_pay_dist_dpcp_int_exp,
        incl_dvd_profit_paid_sc_ms,
        oth_cashpay_ral_fnc_act,
        stot_cashout_fnc_act,
        n_cash_flows_fnc_act ,
        eff_fx_flu_cash ,
        n_incr_cash_cash_equ ,
        c_cash_equ_beg_period,
        c_cash_equ_end_period ,
        c_recp_cap_contrib,
        incl_cash_rec_saims,
        uncon_invest_loss,
        prov_depr_assets,
        depr_fa_coga_dpba,
        amort_intang_assets ,
        lt_amort_deferred_exp ,
        decr_deferred_exp,
        incr_acc_exp,
        loss_disp_fiolta,
        loss_scr_fa,
        loss_fv_chg,
        invest_loss ,
        decr_def_inc_tax_assets,
        incr_def_inc_tax_liab ,
        decr_inventories ,
        decr_oper_payable,
        incr_oper_payable ,
        others,
        im_net_cashflow_oper_act,
        conv_debt_into_cap ,
        conv_copbonds_due_within_1y ,
        fa_fnc_leases,
        end_bal_cash ,
        beg_bal_cash ,
        end_bal_cash_equ,
        beg_bal_cash_equ ,
        im_n_incr_cash_equ")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Revenue Forecast
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	股票代码(二选一)
    # ann_date 	str 	N 	公告日期
    # start_date 	str 	N 	公告开始日期
    # end_date 	str 	N 	公告结束日期
    # period 	str 	N 	报告期 (二选一) (每个季度最后一天的日期，比如20171231表示年报)
    # type 	str 	N 	预告类型(预增/预减/扭亏/首亏/续亏/续盈/略增/略减)
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS股票代码
    # ann_date 	str 	公告日期
    # end_date 	str 	报告期
    # type 	str 	业绩预告类型(预增/预减/扭亏/首亏/续亏/续盈/略增/略减)
    # p_change_min 	float 	预告净利润变动幅度下限（%）
    # p_change_max 	float 	预告净利润变动幅度上限（%）
    # net_profit_min 	float 	预告净利润下限（万元）
    # net_profit_max 	float 	预告净利润上限（万元）
    # last_parent_net 	float 	上年同期归属母公司净利润
    # first_ann_date 	str 	首次公告日
    # summary 	str 	业绩预告摘要
    # change_reason 	str 	业绩变动原因
    function get_stock_revenueForcast(d_params :: Dict = Dict("ts_code" => "000001.SZ"),
        s_api::String = "forecast",
        s_fields :: String = "
        ts_code,
        ann_date,
        end_date,
        type,
        p_change_min,
        p_change_max,
        net_profit_min,
        net_profit_max,
        last_parent_net,
        first_ann_date,
        summary,
        change_reason")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Revenue Express
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	股票代码
    # ann_date 	str 	N 	公告日期
    # start_date 	str 	N 	公告开始日期
    # end_date 	str 	N 	公告结束日期
    # period 	str 	N 	报告期(每个季度最后一天的日期,比如20171231表示年报)
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS股票代码
    # ann_date 	str 	公告日期
    # end_date 	str 	报告期
    # revenue 	float 	营业收入(元)
    # operate_profit 	float 	营业利润(元)
    # total_profit 	float 	利润总额(元)
    # n_income 	float 	净利润(元)
    # total_assets 	float 	总资产(元)
    # total_hldr_eqy_exc_min_int 	float 	股东权益合计(不含少数股东权益)(元)
    # diluted_eps 	float 	每股收益(摊薄)(元)
    # diluted_roe 	float 	净资产收益率(摊薄)(%)
    # yoy_net_profit 	float 	去年同期修正后净利润
    # bps 	float 	每股净资产
    # yoy_sales 	float 	同比增长率:营业收入
    # yoy_op 	float 	同比增长率:营业利润
    # yoy_tp 	float 	同比增长率:利润总额
    # yoy_dedu_np 	float 	同比增长率:归属母公司股东的净利润
    # yoy_eps 	float 	同比增长率:基本每股收益
    # yoy_roe 	float 	同比增减:加权平均净资产收益率
    # growth_assets 	float 	比年初增长率:总资产
    # yoy_equity 	float 	比年初增长率:归属母公司的股东权益
    # growth_bps 	float 	比年初增长率:归属于母公司股东的每股净资产
    # or_last_year 	float 	去年同期营业收入
    # op_last_year 	float 	去年同期营业利润
    # tp_last_year 	float 	去年同期利润总额
    # np_last_year 	float 	去年同期净利润
    # eps_last_year 	float 	去年同期每股收益
    # open_net_assets 	float 	期初净资产
    # open_bps 	float 	期初每股净资产
    # perf_summary 	str 	业绩简要说明
    # is_audit 	int 	是否审计： 1是 0否
    # remark 	str 	备注
    function get_stock_revenueExpress(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "express",
        s_fields :: String = "
        ts_code,
        ann_date,
        end_date ,
        revenue,
        operate_profit,
        total_profit ,
        n_income,
        total_assets ,
        total_hldr_eqy_exc_min_int ,
        diluted_eps,
        diluted_roe ,
        yoy_net_profit,
        bps,
        yoy_sales,
        yoy_op,
        yoy_tp,
        yoy_dedu_np,
        yoy_eps,
        yoy_roe ,
        growth_assets,
        yoy_equity ,
        growth_bps ,
        or_last_year ,
        op_last_year,
        tp_last_year ,
        np_last_year ,
        eps_last_year ,
        open_net_assets ,
        open_bps ,
        perf_summary ,
        is_audit ,
        remark")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Dividend info
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	TS代码
    # ann_date 	str 	N 	公告日
    # record_date 	str 	N 	股权登记日期
    # ex_date 	str 	N 	除权除息日
    #
    # 以上参数至少有一个不能为空
    #
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # end_date 	str 	Y 	分红年度
    # ann_date 	str 	Y 	预案公告日
    # div_proc 	str 	Y 	实施进度
    # stk_div 	float 	Y 	每股送转
    # stk_bo_rate 	float 	Y 	每股送股比例
    # stk_co_rate 	float 	Y 	每股转增比例
    # cash_div 	float 	Y 	每股分红（税后）
    # cash_div_tax 	float 	Y 	每股分红（税前）
    # record_date 	str 	Y 	股权登记日
    # ex_date 	str 	Y 	除权除息日
    # pay_date 	str 	Y 	派息日
    # div_listdate 	str 	Y 	红股上市日
    # imp_ann_date 	str 	Y 	实施公告日
    # base_date 	str 	Y 	基准日
    # base_share 	float 	Y 	基准股本（万）
    function get_stock_dividend(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "dividend",
        s_fields :: String = "
        ts_code,
        end_date,
        ann_date,
        div_proc,
        stk_div,
        stk_bo_rate,
        stk_co_rate ,
        cash_div,
        cash_div_tax ,
        record_date,
        ex_date,
        pay_date,
        div_listdate ,
        imp_ann_date,
        base_date,
        base_share")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Financial indicators
    #     最多60条每次
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	TS股票代码,e.g. 600001.SH/000001.SZ
    # ann_date 	str 	N 	公告日期
    # start_date 	str 	N 	报告期开始日期
    # end_date 	str 	N 	报告期结束日期
    # period 	str 	N 	报告期(每个季度最后一天的日期,比如20171231表示年报)
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS代码
    # ann_date 	str 	公告日期
    # end_date 	str 	报告期
    # eps 	float 	基本每股收益
    # dt_eps 	float 	稀释每股收益
    # total_revenue_ps 	float 	每股营业总收入
    # revenue_ps 	float 	每股营业收入
    # capital_rese_ps 	float 	每股资本公积
    # surplus_rese_ps 	float 	每股盈余公积
    # undist_profit_ps 	float 	每股未分配利润
    # extra_item 	float 	非经常性损益
    # profit_dedt 	float 	扣除非经常性损益后的净利润
    # gross_margin 	float 	毛利
    # current_ratio 	float 	流动比率
    # quick_ratio 	float 	速动比率
    # cash_ratio 	float 	保守速动比率
    # invturn_days 	float 	存货周转天数
    # arturn_days 	float 	应收账款周转天数
    # inv_turn 	float 	存货周转率
    # ar_turn 	float 	应收账款周转率
    # ca_turn 	float 	流动资产周转率
    # fa_turn 	float 	固定资产周转率
    # assets_turn 	float 	总资产周转率
    # op_income 	float 	经营活动净收益
    # valuechange_income 	float 	价值变动净收益
    # interst_income 	float 	利息费用
    # daa 	float 	折旧与摊销
    # ebit 	float 	息税前利润
    # ebitda 	float 	息税折旧摊销前利润
    # fcff 	float 	企业自由现金流量
    # fcfe 	float 	股权自由现金流量
    # current_exint 	float 	无息流动负债
    # noncurrent_exint 	float 	无息非流动负债
    # interestdebt 	float 	带息债务
    # netdebt 	float 	净债务
    # tangible_asset 	float 	有形资产
    # working_capital 	float 	营运资金
    # networking_capital 	float 	营运流动资本
    # invest_capital 	float 	全部投入资本
    # retained_earnings 	float 	留存收益
    # diluted2_eps 	float 	期末摊薄每股收益
    # bps 	float 	每股净资产
    # ocfps 	float 	每股经营活动产生的现金流量净额
    # retainedps 	float 	每股留存收益
    # cfps 	float 	每股现金流量净额
    # ebit_ps 	float 	每股息税前利润
    # fcff_ps 	float 	每股企业自由现金流量
    # fcfe_ps 	float 	每股股东自由现金流量
    # netprofit_margin 	float 	销售净利率
    # grossprofit_margin 	float 	销售毛利率
    # cogs_of_sales 	float 	销售成本率
    # expense_of_sales 	float 	销售期间费用率
    # profit_to_gr 	float 	净利润/营业总收入
    # saleexp_to_gr 	float 	销售费用/营业总收入
    # adminexp_of_gr 	float 	管理费用/营业总收入
    # finaexp_of_gr 	float 	财务费用/营业总收入
    # impai_ttm 	float 	资产减值损失/营业总收入
    # gc_of_gr 	float 	营业总成本/营业总收入
    # op_of_gr 	float 	营业利润/营业总收入
    # ebit_of_gr 	float 	息税前利润/营业总收入
    # roe 	float 	净资产收益率
    # roe_waa 	float 	加权平均净资产收益率
    # roe_dt 	float 	净资产收益率(扣除非经常损益)
    # roa 	float 	总资产报酬率
    # npta 	float 	总资产净利润
    # roic 	float 	投入资本回报率
    # roe_yearly 	float 	年化净资产收益率
    # roa2_yearly 	float 	年化总资产报酬率
    # roe_avg 	float 	平均净资产收益率(增发条件)
    # opincome_of_ebt 	float 	经营活动净收益/利润总额
    # investincome_of_ebt 	float 	价值变动净收益/利润总额
    # n_op_profit_of_ebt 	float 	营业外收支净额/利润总额
    # tax_to_ebt 	float 	所得税/利润总额
    # dtprofit_to_profit 	float 	扣除非经常损益后的净利润/净利润
    # salescash_to_or 	float 	销售商品提供劳务收到的现金/营业收入
    # ocf_to_or 	float 	经营活动产生的现金流量净额/营业收入
    # ocf_to_opincome 	float 	经营活动产生的现金流量净额/经营活动净收益
    # capitalized_to_da 	float 	资本支出/折旧和摊销
    # debt_to_assets 	float 	资产负债率
    # assets_to_eqt 	float 	权益乘数
    # dp_assets_to_eqt 	float 	权益乘数(杜邦分析)
    # ca_to_assets 	float 	流动资产/总资产
    # nca_to_assets 	float 	非流动资产/总资产
    # tbassets_to_totalassets 	float 	有形资产/总资产
    # int_to_talcap 	float 	带息债务/全部投入资本
    # eqt_to_talcapital 	float 	归属于母公司的股东权益/全部投入资本
    # currentdebt_to_debt 	float 	流动负债/负债合计
    # longdeb_to_debt 	float 	非流动负债/负债合计
    # ocf_to_shortdebt 	float 	经营活动产生的现金流量净额/流动负债
    # debt_to_eqt 	float 	产权比率
    # eqt_to_debt 	float 	归属于母公司的股东权益/负债合计
    # eqt_to_interestdebt 	float 	归属于母公司的股东权益/带息债务
    # tangibleasset_to_debt 	float 	有形资产/负债合计
    # tangasset_to_intdebt 	float 	有形资产/带息债务
    # tangibleasset_to_netdebt 	float 	有形资产/净债务
    # ocf_to_debt 	float 	经营活动产生的现金流量净额/负债合计
    # ocf_to_interestdebt 	float 	经营活动产生的现金流量净额/带息债务
    # ocf_to_netdebt 	float 	经营活动产生的现金流量净额/净债务
    # ebit_to_interest 	float 	已获利息倍数(EBIT/利息费用)
    # longdebt_to_workingcapital 	float 	长期债务与营运资金比率
    # ebitda_to_debt 	float 	息税折旧摊销前利润/负债合计
    # turn_days 	float 	营业周期
    # roa_yearly 	float 	年化总资产净利率
    # roa_dp 	float 	总资产净利率(杜邦分析)
    # fixed_assets 	float 	固定资产合计
    # profit_prefin_exp 	float 	扣除财务费用前营业利润
    # non_op_profit 	float 	非营业利润
    # op_to_ebt 	float 	营业利润／利润总额
    # nop_to_ebt 	float 	非营业利润／利润总额
    # ocf_to_profit 	float 	经营活动产生的现金流量净额／营业利润
    # cash_to_liqdebt 	float 	货币资金／流动负债
    # cash_to_liqdebt_withinterest 	float 	货币资金／带息流动负债
    # op_to_liqdebt 	float 	营业利润／流动负债
    # op_to_debt 	float 	营业利润／负债合计
    # roic_yearly 	float 	年化投入资本回报率
    # profit_to_op 	float 	利润总额／营业收入
    # q_opincome 	float 	经营活动单季度净收益
    # q_investincome 	float 	价值变动单季度净收益
    # q_dtprofit 	float 	扣除非经常损益后的单季度净利润
    # q_eps 	float 	每股收益(单季度)
    # q_netprofit_margin 	float 	销售净利率(单季度)
    # q_gsprofit_margin 	float 	销售毛利率(单季度)
    # q_exp_to_sales 	float 	销售期间费用率(单季度)
    # q_profit_to_gr 	float 	净利润／营业总收入(单季度)
    # q_saleexp_to_gr 	float 	销售费用／营业总收入 (单季度)
    # q_adminexp_to_gr 	float 	管理费用／营业总收入 (单季度)
    # q_finaexp_to_gr 	float 	财务费用／营业总收入 (单季度)
    # q_impair_to_gr_ttm 	float 	资产减值损失／营业总收入(单季度)
    # q_gc_to_gr 	float 	营业总成本／营业总收入 (单季度)
    # q_op_to_gr 	float 	营业利润／营业总收入(单季度)
    # q_roe 	float 	净资产收益率(单季度)
    # q_dt_roe 	float 	净资产单季度收益率(扣除非经常损益)
    # q_npta 	float 	总资产净利润(单季度)
    # q_opincome_to_ebt 	float 	经营活动净收益／利润总额(单季度)
    # q_investincome_to_ebt 	float 	价值变动净收益／利润总额(单季度)
    # q_dtprofit_to_profit 	float 	扣除非经常损益后的净利润／净利润(单季度)
    # q_salescash_to_or 	float 	销售商品提供劳务收到的现金／营业收入(单季度)
    # q_ocf_to_sales 	float 	经营活动产生的现金流量净额／营业收入(单季度)
    # q_ocf_to_or 	float 	经营活动产生的现金流量净额／经营活动净收益(单季度)
    # basic_eps_yoy 	float 	基本每股收益同比增长率(%)
    # dt_eps_yoy 	float 	稀释每股收益同比增长率(%)
    # cfps_yoy 	float 	每股经营活动产生的现金流量净额同比增长率(%)
    # op_yoy 	float 	营业利润同比增长率(%)
    # ebt_yoy 	float 	利润总额同比增长率(%)
    # netprofit_yoy 	float 	归属母公司股东的净利润同比增长率(%)
    # dt_netprofit_yoy 	float 	归属母公司股东的净利润-扣除非经常损益同比增长率(%)
    # ocf_yoy 	float 	经营活动产生的现金流量净额同比增长率(%)
    # roe_yoy 	float 	净资产收益率(摊薄)同比增长率(%)
    # bps_yoy 	float 	每股净资产相对年初增长率(%)
    # assets_yoy 	float 	资产总计相对年初增长率(%)
    # eqt_yoy 	float 	归属母公司的股东权益相对年初增长率(%)
    # tr_yoy 	float 	营业总收入同比增长率(%)
    # or_yoy 	float 	营业收入同比增长率(%)
    # q_gr_yoy 	float 	营业总收入同比增长率(%)(单季度)
    # q_gr_qoq 	float 	营业总收入环比增长率(%)(单季度)
    # q_sales_yoy 	float 	营业收入同比增长率(%)(单季度)
    # q_sales_qoq 	float 	营业收入环比增长率(%)(单季度)
    # q_op_yoy 	float 	营业利润同比增长率(%)(单季度)
    # q_op_qoq 	float 	营业利润环比增长率(%)(单季度)
    # q_profit_yoy 	float 	净利润同比增长率(%)(单季度)
    # q_profit_qoq 	float 	净利润环比增长率(%)(单季度)
    # q_netprofit_yoy 	float 	归属母公司股东的净利润同比增长率(%)(单季度)
    # q_netprofit_qoq 	float 	归属母公司股东的净利润环比增长率(%)(单季度)
    # equity_yoy 	float 	净资产同比增长率
    # rd_exp 	float 	研发费用
    function get_stock_finIndicator(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "fina_indicator",
        s_fields :: String = "
        ts_code ,
        ann_date,
        end_date ,
        eps ,
        dt_eps ,
        total_revenue_ps ,
        revenue_ps,
        capital_rese_ps ,
        surplus_rese_ps ,
        undist_profit_ps ,
        extra_item ,
        profit_dedt ,
        gross_margin,
        current_ratio,
        quick_ratio,
        cash_ratio,
        invturn_days,
        arturn_days,
        inv_turn ,
        ar_turn,
        ca_turn ,
        fa_turn ,
        assets_turn ,
        op_income,
        valuechange_income,
        interst_income,
        daa,
        ebit,
        ebitda,
        fcff,
        fcfe,
        current_exint ,
        noncurrent_exint,
        interestdebt ,
        netdebt ,
        tangible_asset,
        working_capital ,
        networking_capital,
        invest_capital,
        retained_earnings ,
        diluted2_eps,
        bps ,
        ocfps ,
        retainedps,
        cfps ,
        ebit_ps ,
        fcff_ps ,
        fcfe_ps ,
        netprofit_margin,
        grossprofit_margin,
        cogs_of_sales,
        expense_of_sales,
        profit_to_gr ,
        saleexp_to_gr,
        adminexp_of_gr,
        finaexp_of_gr,
        impai_ttm,
        gc_of_gr,
        op_of_gr ,
        ebit_of_gr,
        roe ,
        roe_waa,
        roe_dt,
        roa ,
        npta,
        roic ,
        roe_yearly ,
        roa2_yearly ,
        roe_avg,
        opincome_of_ebt,
        investincome_of_ebt ,
        n_op_profit_of_ebt,
        tax_to_ebt ,
        dtprofit_to_profit,
        salescash_to_or ,
        ocf_to_or,
        ocf_to_opincome ,
        capitalized_to_da,
        debt_to_assets ,
        assets_to_eqt,
        dp_assets_to_eqt,
        ca_to_assets,
        nca_to_assets ,
        tbassets_to_totalassets,
        int_to_talcap,
        eqt_to_talcapital ,
        currentdebt_to_debt,
        longdeb_to_debt ,
        ocf_to_shortdebt ,
        debt_to_eqt,
        eqt_to_debt,
        eqt_to_interestdebt ,
        tangibleasset_to_debt ,
        tangasset_to_intdebt,
        tangibleasset_to_netdebt ,
        ocf_to_debt,
        ocf_to_interestdebt,
        ocf_to_netdebt,
        ebit_to_interest,
        longdebt_to_workingcapital,
        ebitda_to_debt,
        turn_days ,
        roa_yearly ,
        roa_dp,
        fixed_assets ,
        profit_prefin_exp,
        non_op_profit ,
        op_to_ebt,
        nop_to_ebt,
        ocf_to_profit ,
        cash_to_liqdebt ,
        cash_to_liqdebt_withinterest,
        op_to_liqdebt,
        op_to_debt,
        roic_yearly ,
        profit_to_op ,
        q_opincome ,
        q_investincome ,
        q_dtprofit,
        q_eps,
        q_netprofit_margin,
        q_gsprofit_margin,
        q_exp_to_sales,
        q_profit_to_gr,
        q_saleexp_to_gr,
        q_adminexp_to_gr,
        q_finaexp_to_gr,
        q_impair_to_gr_ttm,
        q_gc_to_gr ,
        q_op_to_gr,
        q_roe,
        q_dt_roe ,
        q_npta ,
        q_opincome_to_ebt ,
        q_investincome_to_ebt,
        q_dtprofit_to_profit ,
        q_salescash_to_or ,
        q_ocf_to_sales,
        q_ocf_to_or ,
        basic_eps_yoy ,
        dt_eps_yoy,
        cfps_yoy ,
        op_yoy ,
        ebt_yoy ,
        netprofit_yoy ,
        dt_netprofit_yoy,
        ocf_yoy ,
        roe_yoy,
        bps_yoy ,
        assets_yoy,
        eqt_yoy ,
        tr_yoy ,
        or_yoy,
        q_gr_yoy ,
        q_gr_qoq ,
        q_sales_yoy ,
        q_sales_qoq ,
        q_op_yoy ,
        q_op_qoq ,
        q_profit_yoy,
        q_profit_qoq ,
        q_netprofit_yoy ,
        q_netprofit_qoq ,
        equity_yoy,
        rd_exp")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get audit info
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	股票代码
    # ann_date 	str 	N 	公告日期
    # start_date 	str 	N 	公告开始日期
    # end_date 	str 	N 	公告结束日期
    # period 	str 	N 	报告期(每个季度最后一天的日期,比如20171231表示年报)
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS股票代码
    # ann_date 	str 	公告日期
    # end_date 	str 	报告期
    # audit_result 	str 	审计结果
    # audit_fees 	float 	审计总费用（元）
    # audit_agency 	str 	会计事务所
    # audit_sign 	str 	签字会计师
    function get_stock_audit(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "fina_audit",
        s_fields :: String = "
        ts_code ,
        ann_date ,
        end_date ,
        audit_result ,
        audit_fees,
        audit_agency ,
        audit_sign")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Main bz of stock
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	股票代码
    # period 	str 	N 	报告期(每个季度最后一天的日期,比如20171231表示年报)
    # type 	str 	N 	类型：P按产品 D按地区（请输入大写字母P或者D）
    # start_date 	str 	N 	报告期开始日期
    # end_date 	str 	N 	报告期结束日期
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS代码
    # end_date 	str 	报告期
    # bz_item 	str 	主营业务来源
    # bz_sales 	float 	主营业务收入(元)
    # bz_profit 	float 	主营业务利润(元)
    # bz_cost 	float 	主营业务成本(元)
    # curr_type 	str 	货币代码
    # update_flag 	str 	是否更新
    function get_stock_mainbz(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "fina_mainbz",
        s_fields :: String = "
        ts_code,
        end_date ,
        bz_item ,
        bz_sales ,
        bz_profit,
        bz_cost ,
        curr_type ,
        update_flag")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get moneyflow of hsgt 获取沪股通、深股通、港股通每日资金流向数据
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	N 	交易日期 (二选一)
    # start_date 	str 	N 	开始日期 (二选一)
    # end_date 	str 	N 	结束日期
    #
    # 输出参数
    # 名称 	类型 	描述
    # trade_date 	str 	交易日期
    # ggt_ss 	str 	港股通（上海）
    # ggt_sz 	str 	港股通（深圳）
    # hgt 	str 	沪股通（百万元）
    # sgt 	str 	深股通（百万元）
    # north_money 	str 	北向资金（百万元）
    # south_money 	str 	南向资金（百万元）
    function get_stock_HSGTflow(d_params :: Dict = Dict("trade_date" => "20180101");
        s_api::String = "moneyflow_hsgt",
        s_fields :: String = "
        trade_date,
        ggt_ss ,
        ggt_sz ,
        hgt ,
        sgt ,
        north_money,
        south_money")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get HDGT Top 10 stocks
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	股票代码（二选一）
    # trade_date 	str 	N 	交易日期（二选一）
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # market_type 	str 	N 	市场类型（1：沪市 3：深市）
    #
    # 输出参数
    # 名称 	类型 	描述
    # trade_date 	str 	交易日期
    # ts_code 	str 	股票代码
    # name 	str 	股票名称
    # close 	float 	收盘价
    # change 	float 	涨跌额
    # rank 	int 	资金排名
    # market_type 	str 	市场类型（1：沪市 3：深市）
    # amount 	float 	成交金额（元）
    # net_amount 	float 	净成交金额（元）
    # buy 	float 	买入金额（元）
    # sell 	float 	卖出金额（元）
    function get_stock_top10HSGT(d_params :: Dict = Dict("trade_date" => "20180101");
        s_api::String = "hsgt_top10",
        s_fields :: String = "
        trade_date,
        ts_code,
        name,
        close,
        change,
        rank ,
        market_type,
        amount,
        net_amount,
        buy,
        sell")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get GGT Top 10 获取港股通每日成交数据，其中包括沪市、深市详细数据
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	股票代码（二选一）
    # trade_date 	str 	N 	交易日期（二选一）
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # market_type 	str 	N 	市场类型 2：港股通（沪） 4：港股通（深）
    #
    # 输出参数
    # 名称 	类型 	描述
    # trade_date 	str 	交易日期
    # ts_code 	str 	股票代码
    # name 	str 	股票名称
    # close 	float 	收盘价
    # p_change 	float 	涨跌幅
    # rank 	str 	资金排名
    # market_type 	str 	市场类型 2：港股通（沪） 4：港股通（深）
    # amount 	float 	累计成交金额（元）
    # net_amount 	float 	净买入金额（元）
    # sh_amount 	float 	沪市成交金额（元）
    # sh_net_amount 	float 	沪市净买入金额（元）
    # sh_buy 	float 	沪市买入金额（元）
    # sh_sell 	float 	沪市卖出金额
    # sz_amount 	float 	深市成交金额（元）
    # sz_net_amount 	float 	深市净买入金额（元）
    # sz_buy 	float 	深市买入金额（元）
    # sz_sell 	float 	深市卖出金额（元）
    function get_stock_top10GGT(d_params :: Dict = Dict("trade_date" => "20180101");
        s_api::String = "ggt_top10",
        s_fields :: String = "
        trade_date,
        ts_code ,
        name ,
        close,
        p_change,
        rank,
        market_type,
        amount,
        net_amount,
        sh_amount ,
        sh_net_amount,
        sh_buy,
        sh_sell,
        sz_amount,
        sz_net_amount,
        sz_buy,
        sz_sell")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Margin balance
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	Y 	交易日期
    # exchange_id 	str 	N 	交易所代码
    #
    # 输出参数
    # 名称 	类型 	描述
    # trade_date 	str 	交易日期
    # exchange_id 	str 	交易所代码（SSE上交所SZSE深交所）
    # rzye 	float 	融资余额(元)
    # rzmre 	float 	融资买入额(元)
    # rzche 	float 	融资偿还额(元)
    # rqye 	float 	融券余额(元)
    # rqmcl 	float 	融券卖出量(股,份,手)
    # rzrqye 	float 	融资融券余额(元)
    function get_stock_marginBalance(d_params :: Dict = Dict("trade_date" => "20180101");
        s_api::String = "margin",
        s_fields :: String = "
        trade_date,
        exchange_id ,
        rzye ,
        rzmre ,
        rzche ,
        rqye ,
        rqmcl ,
        rzrqye")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Margin Detail for stocks
    #     输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	Y 	交易日期
    # ts_code 	str 	N 	TS代码
    #
    # 输出参数
    # 名称 	类型 	描述
    # trade_date 	str 	交易日期
    # ts_code 	str 	TS股票代码
    # rzye 	float 	融资余额(元)
    # rqye 	float 	融券余额(元)
    # rzmre 	float 	融资买入额(元)
    # rqyl 	float 	融券余量（手）
    # rzche 	float 	融资偿还额(元)
    # rqchl 	float 	融券偿还量(手)
    # rqmcl 	float 	融券卖出量(股,份,手)
    # rzrqye 	float 	融资融券余额(元)
    function get_stock_marginDetail(d_params :: Dict = Dict("trade_date" => "20180101");
        s_api::String = "margin_detail",
        s_fields :: String = "
        trade_date,
        ts_code ,
        rzye,
        rqye ,
        rzmre ,
        rqyl ,
        rzche ,
        rqchl ,
        rqmcl ,
        rzrqye")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get top 10 shareholders for stock
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	TS代码
    # period 	str 	N 	报告期
    # ann_date 	str 	N 	公告日期
    # start_date 	str 	N 	报告期开始日期
    # end_date 	str 	N 	报告期结束日期
    #
    # 注：一次取100行记录
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS股票代码
    # ann_date 	str 	公告日期
    # end_date 	str 	报告期
    # holder_name 	str 	股东名称
    # hold_amount 	float 	持有数量（股）
    # hold_ratio 	float 	持有比例
    function get_stock_top10Holders(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "top10_holders",
        s_fields :: String = "
        ts_code ,
        ann_date ,
        end_date,
        holder_name,
        hold_amount,
        hold_ratio")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get top 10 float holders of stocks
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	TS代码
    # period 	str 	N 	报告期
    # ann_date 	str 	N 	公告日期
    # start_date 	str 	N 	报告期开始日期
    # end_date 	str 	N 	报告期结束日期
    #
    # 注：一次取100行记录
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS股票代码
    # ann_date 	str 	公告日期
    # end_date 	str 	报告期
    # holder_name 	str 	股东名称
    # hold_amount 	float 	持有数量（股）
    function get_stock_top10Floatholders(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "top10_floatholders",
        s_fields :: String = "
        ts_code ,
        ann_date ,
        end_date,
        holder_name,
        hold_amount")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Hotest top
    #     接口：top_list
    # 描述：龙虎榜每日交易明细
    # 数据历史： 2005年至今
    # 限量：单次最大10000
    # 积分：用户需要至少300积分才可以调取，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	Y 	交易日期
    # ts_code 	str 	N 	股票代码
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # trade_date 	str 	Y 	交易日期
    # ts_code 	str 	Y 	TS代码
    # name 	str 	Y 	名称
    # close 	float 	Y 	收盘价
    # pct_change 	float 	Y 	涨跌幅
    # turnover_rate 	float 	Y 	换手率
    # amount 	float 	Y 	总成交额
    # l_sell 	float 	Y 	龙虎榜卖出额
    # l_buy 	float 	Y 	龙虎榜买入额
    # l_amount 	float 	Y 	龙虎榜成交额
    # net_amount 	float 	Y 	龙虎榜净买入额
    # net_rate 	float 	Y 	龙虎榜净买额占比
    # amount_rate 	float 	Y 	龙虎榜成交额占比
    # float_values 	float 	Y 	当日流通市值
    # reason 	str 	Y 	上榜理由
    function get_stock_Hotest(d_params :: Dict = Dict("trade_date" => "20180101");
        s_api::String = "top_list",
        s_fields :: String = "
        trade_date,
        ts_code,
        name ,
        close ,
        pct_change,
        turnover_rate ,
        amount,
        l_sell,
        l_buy ,
        l_amount,
        net_amount,
        net_rate ,
        amount_rate ,
        float_values,
        reason")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Institution info in Hotest Top
    # 接口：top_inst
    # 描述：龙虎榜机构成交明细
    # 限量：单次最大10000
    # 积分：用户需要至少300积分才可以调取，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	Y 	交易日期
    # ts_code 	str 	N 	TS代码
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # trade_date 	str 	Y 	交易日期
    # ts_code 	str 	Y 	TS代码
    # exalter 	str 	Y 	营业部名称
    # buy 	float 	Y 	买入额（万）
    # buy_rate 	float 	Y 	买入占总成交比例
    # sell 	float 	Y 	卖出额（万）
    # sell_rate 	float 	Y 	卖出占总成交比例
    # net_buy 	float 	Y 	净成交额（万）
    function get_stock_instinfo(d_params :: Dict = Dict("trade_date" => "20180101");
        s_api::String = "top_inst",
        s_fields :: String = "
        trade_date,
        ts_code ,
        exalter,
        buy,
        buy_rate ,
        sell ,
        sell_rate ,
        net_buy")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Stock Pledge statistics
    #     接口：pledge_stat
    # 描述：获取股权质押统计数据
    # 限量：单次最大1000
    # 积分：用户需要至少300积分才可以调取，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	股票代码
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # end_date 	str 	Y 	截至日期
    # pledge_count 	int 	Y 	质押次数
    # unrest_pledge 	float 	Y 	无限售股质押数量（万）
    # rest_pledge 	float 	Y 	限售股份质押数量（万）
    # total_share 	float 	Y 	总股本
    # pledge_ratio 	float 	Y 	质押比例
    function get_stock_pledge(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "pledge_stat",
        s_fields :: String = "
        ts_code,
        end_date ,
        pledge_count ,
        unrest_pledge ,
        rest_pledge,
        total_share ,
        pledge_ratio")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Stock Pledge Detail
    function get_stock_pledgeDetail(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "pledge_detail",
        s_fields :: String = "
        ts_code ,
        ann_date ,
        holder_name ,
        pledge_amount,
        start_date,
        end_date ,
        is_release,
        release_date ,
        pledgor ,
        holding_amount ,
        pledged_amount,
        p_total_ratio,
        h_total_ratio,
        is_buyback")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get repurchase data
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ann_date 	str 	N 	公告日期（任意填参数，如果都不填，单次默认返回2000条）
    # start_date 	str 	N 	公告开始日期
    # end_date 	str 	N 	公告结束日期
    #
    # 以上日期格式为：YYYYMMDD，比如20181010
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # ann_date 	str 	Y 	公告日期
    # end_date 	str 	Y 	截止日期
    # proc 	str 	Y 	进度
    # exp_date 	str 	Y 	过期日期
    # vol 	float 	Y 	回购数量
    # amount 	float 	Y 	回购金额
    # high_limit 	float 	Y 	回购最高价
    # low_limit 	float 	Y 	回购最低价
    function get_stock_repurchase(;s_api::String = "repurchase",
        d_params :: Dict = Dict(), s_fields :: String = "
        ts_code,
        ann_date,
        end_date ,
        proc,
        exp_date ,
        vol,
        amount ,
        high_limit,
        low_limit")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Stock Concept
    #     输入参数
    # 名称 	类型 	必选 	描述
    # src 	str 	N 	来源，默认为ts
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # code 	str 	Y 	概念分类ID
    # name 	str 	Y 	概念分类名称
    # src 	str 	Y 	来源
    function get_stock_concept(;s_api::String = "concept",
        d_params :: Dict = Dict(), s_fields :: String = "
        code,
        name ,
        src")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Stock Concept Detail
    # 输入参数
    # 名称 	类型 	必选 	描述
    # id 	str 	Y 	概念分类ID （id来自概念股分类接口）
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # id 	str 	Y 	概念代码
    # ts_code 	str 	Y 	股票代码
    # name 	str 	Y 	股票名称
    # in_date 	str 	N 	纳入日期
    # out_date 	str 	N 	剔除日期
    function get_stock_conceptDetail(d_params :: Dict = Dict("id" => "TS2");
        s_api::String = "concept_detail",
        s_fields :: String = "
        id,
        ts_code,
        name ,
        in_date ,
        out_date")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get delimit share info
    #     接口：share_float
    # 描述：获取限售股解禁
    # 限量：单次最大5000条，总量不限制
    # 积分：120分可调取，每分钟内限制次数，超过5000积分无限制，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	TS股票代码（至少输入一个参数）
    # ann_date 	str 	N 	公告日期（日期格式：YYYYMMDD，下同）
    # float_date 	str 	N 	解禁日期
    # start_date 	str 	N 	解禁开始日期
    # end_date 	str 	N 	解禁结束日期
    #
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # ann_date 	str 	Y 	公告日期
    # float_date 	str 	Y 	解禁日期
    # float_share 	float 	Y 	流通股份
    # float_ratio 	float 	Y 	流通股份占总股本比率
    # holder_name 	str 	Y 	股东名称
    # share_type 	str 	Y 	股份类型
    function get_stock_delimit(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "share_float",
        s_fields :: String = "
        ts_code,
        ann_date ,
        float_date ,
        float_share,
        float_ratio,
        holder_name ,
        share_type")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get block Trade
    #     接口：block_trade
    # 描述：大宗交易
    # 限量：单次最大1000条，总量不限制
    # 积分：300积分可调取，每分钟内限制次数，超过5000积分无限制，具体请参阅积分获取办法
    #
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	TS代码（股票代码和日期至少输入一个参数）
    # trade_date 	str 	N 	交易日期（格式：YYYYMMDD，下同）
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # trade_date 	str 	Y 	交易日历
    # price 	float 	Y 	成交价
    # vol 	float 	Y 	成交量（万股）
    # amount 	float 	Y 	成交金额
    # buyer 	str 	Y 	买方营业部
    # seller 	str 	Y 	卖房营业部
    function get_stock_blockTrade(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "block_trade",
        s_fields :: String = "
        ts_code ,
        trade_date ,
        price ,
        vol,
        amount ,
        buyer ,
        seller")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Index Basic Info
    #     输入参数
    # 名称 	类型 	必选 	描述
    # market 	str 	Y 	交易所或服务商
    # publisher 	str 	N 	发布商
    # category 	str 	N 	指数类别
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS代码
    # name 	str 	简称
    # fullname 	str 	指数全称
    # market 	str 	市场
    # publisher 	str 	发布方
    # index_type 	str 	指数风格
    # category 	str 	指数类别
    # base_date 	str 	基期
    # base_point 	float 	基点
    # list_date 	str 	发布日期
    # weight_rule 	str 	加权方式
    # desc 	str 	描述
    # exp_date 	str 	终止日期
    #
    # 市场说明(market)
    # 市场代码 	说明
    # MSCI 	MSCI指数
    # CSI 	中证指数
    # SSE 	上交所指数
    # SZSE 	深交所指数
    # CICC 	中金所指数
    # SW 	申万指数
    # CNI 	国证指数
    # OTH 	其他指数
    # 指数列表
    #
    #     主题指数
    #     规模指数
    #     策略指数
    #     风格指数
    #     综合指数
    #     成长指数
    #     价值指数
    #     有色指数
    #     化工指数
    #     能源指数
    #     其他指数
    #     外汇指数
    #     基金指数
    #     商品指数
    #     债券指数
    #     行业指数
    #     贵金属指数
    #     农副产品指数
    #     软商品指数
    #     油脂油料指数
    #     非金属建材指数
    #     煤焦钢矿指数
    #     谷物指数
    #     一级行业指数
    #     二级行业指数
    #     三级行业指数
    function get_index_info(d_params :: Dict = Dict("market" => "SSE");
        s_api::String = "index_basic",
        s_fields :: String = "
        ts_code ,
        name ,
        fullname ,
        market,
        publisher,
        index_type ,
        category ,
        base_date,
        base_point,
        list_date ,
        weight_rule ,
        desc ,
        exp_date")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Public Fund Basic info
    #     输入参数
    # 名称 	类型 	必选 	描述
    # market 	str 	N 	交易市场: E场内 O场外（默认E）
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	基金代码
    # name 	str 	Y 	简称
    # management 	str 	Y 	管理人
    # custodian 	str 	Y 	托管人
    # fund_type 	str 	Y 	投资类型
    # found_date 	str 	Y 	成立日期
    # due_date 	str 	Y 	到期日期
    # list_date 	str 	Y 	上市时间
    # issue_date 	str 	Y 	发行日期
    # delist_date 	str 	Y 	退市日期
    # issue_amount 	float 	Y 	发行份额(亿)
    # m_fee 	float 	Y 	管理费
    # c_fee 	float 	Y 	托管费
    # duration_year 	float 	Y 	存续期
    # p_value 	float 	Y 	面值
    # min_amount 	float 	Y 	起点金额(万元)
    # exp_return 	float 	Y 	预期收益率
    # benchmark 	str 	Y 	业绩比较基准
    # status 	str 	Y 	存续状态D摘牌 I发行 L已上市
    # invest_type 	str 	Y 	投资风格
    # type 	str 	Y 	基金类型
    # trustee 	str 	Y 	受托人
    # purc_startdate 	str 	Y 	日常申购起始日
    # redm_startdate 	str 	Y 	日常赎回起始日
    # market 	str 	Y 	E场内O场外
    function get_fund_info(;s_api::String = "fund_basic",
        d_params :: Dict = Dict(), s_fields :: String = "
        ts_code,
        name ,
        management ,
        custodian,
        fund_type ,
        found_date ,
        due_date ,
        list_date,
        issue_date,
        delist_date ,
        issue_amount,
        m_fee ,
        c_fee,
        duration_year ,
        p_value ,
        min_amount ,
        exp_return,
        benchmark,
        status,
        invest_type,
        type,
        trustee,
        purc_startdate,
        redm_startdate,
        market")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Public Fund Company
    #     输入参数
    # 无
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # name 	str 	Y 	基金公司名称
    # shortname 	str 	Y 	简称
    # short_enname 	str 	N 	英文缩写
    # province 	str 	Y 	省份
    # city 	str 	Y 	城市
    # address 	str 	Y 	注册地址
    # phone 	str 	Y 	电话
    # office 	str 	Y 	办公地址
    # website 	str 	Y 	公司网址
    # chairman 	str 	Y 	法人代表
    # manager 	str 	Y 	总经理
    # reg_capital 	float 	Y 	注册资本
    # setup_date 	str 	Y 	成立日期
    # end_date 	str 	Y 	公司终止日期
    # employees 	float 	Y 	员工总数
    # main_business 	str 	Y 	主要产品及业务
    # org_code 	str 	Y 	组织机构代码
    # credit_code 	str 	Y 	统一社会信用代码
    function get_fund_company(;s_api::String = "fund_company",
        d_params :: Dict = Dict(), s_fields :: String = "
        name ,
        shortname,
        short_enname,
        province,
        city ,
        address ,
        phone,
        office ,
        website,
        chairman,
        manager,
        reg_capital ,
        setup_date,
        end_date,
        employees ,
        main_business ,
        org_code ,
        credit_code")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Fund Dividend Data
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ann_date 	str 	N 	公告日（以下参数四选一）
    # ex_date 	str 	N 	除息日
    # pay_date 	str 	N 	派息日
    # ts_code 	str 	N 	基金代码
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # ann_date 	str 	Y 	公告日期
    # imp_anndate 	str 	Y 	分红实施公告日
    # base_date 	str 	Y 	分配收益基准日
    # div_proc 	str 	Y 	方案进度
    # record_date 	str 	Y 	权益登记日
    # ex_date 	str 	Y 	除息日
    # pay_date 	str 	Y 	派息日
    # earpay_date 	str 	Y 	收益支付日
    # net_ex_date 	str 	Y 	净值除权日
    # div_cash 	float 	Y 	每股派息(元)
    # base_unit 	float 	Y 	基准基金份额(万份)
    # ear_distr 	float 	Y 	可分配收益(元)
    # ear_amount 	float 	Y 	收益分配金额(元)
    # account_date 	str 	Y 	红利再投资到账日
    # base_year 	str 	Y 	份额基准年度
    function get_fund_dividend(d_params :: Dict = Dict("ts_code" => "161618.OF");
        s_api::String = "fund_div",
        s_fields :: String = "
        ts_code,
        ann_date ,
        imp_anndate ,
        base_date,
        div_proc ,
        record_date ,
        ex_date ,
        pay_date,
        earpay_date ,
        net_ex_date,
        div_cash ,
        base_unit,
        ear_distr,
        ear_amount ,
        account_date ,
        base_year")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Future Basic Data
    #     接口：fut_basic
    # 描述：获取期货合约列表数据
    # 限量：单次最大10000
    # 积分：用户需要至少200积分才可以调取，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # exchange 	str 	Y 	交易所代码
    # fut_type 	str 	N 	合约类型 (1 普通合约 2主力与连续合约 默认取全部)
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	合约代码
    # symbol 	str 	Y 	交易标识
    # exchange 	str 	Y 	交易市场
    # name 	str 	Y 	中文简称
    # fut_code 	str 	Y 	合约产品代码
    # multiplier 	float 	Y 	合约乘数
    # trade_unit 	str 	Y 	交易计量单位
    # per_unit 	float 	Y 	交易单位(每手)
    # quote_unit 	str 	Y 	报价单位
    # quote_unit_desc 	str 	Y 	最小报价单位说明
    # d_mode_desc 	str 	Y 	交割方式说明
    # list_date 	str 	Y 	上市日期
    # delist_date 	str 	Y 	最后交易日期
    # d_month 	str 	Y 	交割月份
    # last_ddate 	str 	Y 	最后交割日
    # trade_time_desc 	str 	N 	交易时间说明
    function get_future_basic(d_params :: Dict = Dict("exchange" => "DCE");
        s_api::String = "fut_basic",
        s_fields :: String = "
        ts_code ,
        symbol,
        exchange ,
        name,
        fut_code,
        multiplier ,
        trade_unit,
        per_unit,
        quote_unit,
        quote_unit_desc ,
        d_mode_desc ,
        list_date,
        delist_date ,
        d_month ,
        last_ddate ,
        trade_time_desc")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Future Trading Calendar
    #     接口：trade_cal
    # 描述：获取各大期货交易所交易日历数据
    # 积分：注册用户即可获取，无积分要求
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # exchange 	str 	N 	交易所 SHFE 上期所 DCE 大商所 CFFEX中金所 CZCE郑商所 INE上海国际能源交易所
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # is_open 	int 	N 	是否交易 0休市 1交易
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # exchange 	str 	Y 	交易所 同参数部分描述
    # cal_date 	str 	Y 	日历日期
    # is_open 	int 	Y 	是否交易 0休市 1交易
    # pretrade_date 	str 	N 	上一个交易日
    function get_future_calendar(;s_api::String = "trade_cal",
        d_params :: Dict = Dict(), s_fields :: String = "
        exchange,
        cal_date ,
        is_open ,
        pretrade_date")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Option Basic Info
    #     输入参数
    # 名称 	类型 	必选 	描述
    # exchange 	str 	Y 	交易所代码 （包括上交所SSE等交易所）
    # call_put 	str 	N 	期权类型
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # exchange 	str 	Y 	交易市场
    # name 	str 	Y 	合约名称
    # per_unit 	str 	Y 	合约单位
    # opt_code 	str 	Y 	标准合约代码
    # opt_type 	str 	Y 	合约类型
    # call_put 	str 	Y 	期权类型
    # exercise_type 	str 	Y 	行权方式
    # exercise_price 	float 	Y 	行权价格
    # s_month 	str 	Y 	结算月
    # maturity_date 	str 	Y 	到期日
    # list_price 	float 	Y 	挂牌基准价
    # list_date 	str 	Y 	开始交易日期
    # delist_date 	str 	Y 	最后交易日期
    # last_edate 	str 	Y 	最后行权日期
    # last_ddate 	str 	Y 	最后交割日期
    # quote_unit 	str 	Y 	报价单位
    # min_price_chg 	str 	Y 	最小价格波幅
    function get_option_info(d_params :: Dict = Dict("exchange" => "SSE");
        s_api::String = "opt_basic",
        s_fields :: String = "
        ts_code,
        exchange ,
        name ,
        per_unit,
        opt_code ,
        opt_type ,
        call_put ,
        exercise_type ,
        exercise_price ,
        s_month ,
        maturity_date ,
        list_price,
        list_date,
        delist_date ,
        last_edate ,
        last_ddate,
        quote_unit ,
        min_price_chg")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get TW Tech industry monthly rev
    #     接口：tmt_twincome
    # 描述：获取台湾TMT电子产业领域各类产品月度营收数据。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	N 	报告期
    # item 	str 	Y 	产品代码
    # start_date 	str 	N 	报告期开始日期
    # end_date 	str 	N 	报告期结束日期
    #
    # 输出参数
    # 名称 	类型 	描述
    # date 	str 	报告期
    # item 	str 	产品代码
    # op_income 	str 	月度收入
    #
    # 由于服务器压力，单次最多获取30个月数据，后续再逐步全部开放，目前可根据日期范围多次获取数据。
    #     产品代码列表
    # TS代码 	类别名称
    # 1 	PC
    # 2 	NB
    # 3 	主机板
    # 4 	印刷电路板
    # 5 	IC载板
    # 6 	PCB组装
    # 7 	软板
    # 8 	PCB
    # 9 	PCB原料
    # 10 	铜箔基板
    # 11 	玻纤纱布
    # 12 	FCCL
    # 13 	显示卡
    # 14 	绘图卡
    # 15 	电视卡
    # 16 	泛工业电脑
    # 17 	POS
    # 18 	工业电脑
    # 19 	光电IO
    # 20 	监视器
    # 21 	扫描器
    # 22 	PC周边
    # 23 	储存媒体
    # 24 	光碟
    # 25 	硬盘磁盘
    # 26 	发光二极体
    # 27 	太阳能
    # 28 	LCD面板
    # 29 	背光模组
    # 30 	LCD原料
    # 31 	LCD其它
    # 32 	触控面板
    # 33 	监控系统
    # 34 	其它光电
    # 35 	电子零组件
    # 36 	二极体整流
    # 37 	连接器
    # 38 	电源供应器
    # 39 	机壳
    # 40 	被动元件
    # 41 	石英元件
    # 42 	3C二次电源
    # 43 	网路设备
    # 44 	数据机
    # 45 	网路卡
    # 46 	半导体
    # 47 	晶圆制造
    # 48 	IC封测
    # 49 	特用IC
    # 50 	记忆体模组
    # 51 	晶圆材料
    # 52 	IC设计
    # 53 	IC光罩
    # 54 	电子设备
    # 55 	手机
    # 56 	通讯设备
    # 57 	电信业
    # 58 	网路服务
    # 59 	卫星通讯
    # 60 	光纤通讯
    # 61 	3C通路
    # 62 	消费性电子
    # 63 	照相机
    # 64 	软件服务
    # 65 	系统整合
    function get_other_twTechincome(d_params :: Dict = Dict("item" => "8");
        s_api::String = "tmt_twincome",
        s_fields :: String = "
        date,
        item ,
        op_income")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get TW Tech industry monthly rev detail -> to company
    #     接口：tmt_twincomedetail
    # 描述：获取台湾TMT行业上市公司各类产品月度营收情况。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	N 	报告期
    # item 	str 	N 	产品代码
    # symbol 	str 	N 	公司代码
    # start_date 	str 	N 	报告期开始日期
    # end_date 	str 	N 	报告期结束日期
    # source 	str 	N 	None
    #
    # 输出参数
    # 名称 	类型 	描述
    # date 	str 	报告期
    # item 	str 	产品代码
    # symbol 	str 	公司代码
    # op_income 	str 	月度营收
    # consop_income 	str 	合并月度营收
    function get_other_twTechincomeDetail(d_params :: Dict = Dict("item" => "8");
        s_api::String = "tmt_twincomedetail",
        s_fields :: String = "
        date ,
        item,
        symbol,
        op_income,
        consop_income")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Movie tickets data monthly
    #     接口：bo_monthly
    # 描述：获取电影月度票房数据
    # 数据更新：本月更新上一月数据
    # 数据历史： 数据从2008年1月1日开始，超过10年历史数据。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	Y 	日期（每月1号，格式YYYYMMDD）
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # name 	str 	Y 	影片名称
    # list_date 	str 	Y 	上映日期
    # avg_price 	float 	Y 	平均票价
    # month_amount 	float 	Y 	当月票房（万）
    # list_day 	int 	Y 	月内天数
    # p_pc 	int 	Y 	场均人次
    # wom_index 	float 	Y 	口碑指数
    # m_ratio 	float 	Y 	月度占比（%）
    # rank 	int 	Y 	排名
    function get_other_BOmonthly(d_params :: Dict = Dict("date" => "20180101");
        s_api::String = "bo_monthly",
        s_fields :: String = "
        date,
        name,
        list_date ,
        avg_price,
        month_amount,
        list_day ,
        p_pc,
        wom_index ,
        m_ratio ,
        rank")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Movie tickets data Weekly
    #     接口：bo_weekly
    # 描述：获取周度票房数据
    # 数据更新：本周更新上一周数据
    # 数据历史： 数据从2008年第一周开始，超过10年历史数据。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	Y 	日期（每周一日期，格式YYYYMMDD）
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # name 	str 	Y 	影片名称
    # avg_price 	float 	Y 	平均票价
    # week_amount 	float 	Y 	当周票房（万）
    # total 	float 	Y 	累计票房（万）
    # list_day 	int 	Y 	上映天数
    # p_pc 	int 	Y 	场均人次
    # wom_index 	float 	Y 	口碑指数
    # up_ratio 	float 	Y 	环比变化 （%）
    # rank 	int 	Y 	排名
    function get_other_BOweekly(d_params :: Dict = Dict("date" => "20181224");
        s_api::String = "bo_weekly",
        s_fields :: String = "
        date,
        name ,
        avg_price,
        week_amount,
        total,
        list_day,
        p_pc,
        wom_index,
        up_ratio,
        rank")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Movie tickets data Daily
    #     接口：bo_daily
    # 描述：获取电影日度票房
    # 数据更新：当日更新上一日数据
    # 数据历史： 数据从2018年9月开始，更多历史数据正在补充
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	Y 	日期 （格式YYYYMMDD）
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # name 	str 	Y 	影片名称
    # avg_price 	float 	Y 	平均票价
    # day_amount 	float 	Y 	当日票房（万）
    # total 	float 	Y 	累计票房（万）
    # list_day 	int 	Y 	上映天数
    # p_pc 	int 	Y 	场均人次
    # wom_index 	float 	Y 	口碑指数
    # up_ratio 	float 	Y 	环比变化 （%）
    # rank 	int 	Y 	排名
    function get_other_BOdaily(d_params :: Dict = Dict("date" => "20181224");
        s_api::String = "bo_daily",
        s_fields :: String = "
        date,
        name ,
        avg_price,
        day_amount,
        total,
        list_day,
        p_pc,
        wom_index,
        up_ratio,
        rank")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Cinerma tickets data daily
    #     接口：bo_cinema
    # 描述：获取每日各影院的票房数据
    # 数据历史： 数据从2018年9月开始，更多历史数据正在补充
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	Y 	日期(格式:YYYYMMDD)
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # c_name 	str 	Y 	影院名称
    # aud_count 	int 	Y 	观众人数
    # att_ratio 	float 	Y 	上座率
    # day_amount 	float 	Y 	当日票房
    # day_showcount 	float 	Y 	当日场次
    # avg_price 	float 	Y 	场均票价（元）
    # p_pc 	float 	Y 	场均人次
    # rank 	int 	Y 	排名
    function get_other_cinermaDaily(d_params :: Dict = Dict("date" => "20181224");
        s_api::String = "bo_cinema",
        s_fields :: String = "
        date,
        c_name ,
        aud_count ,
        att_ratio ,
        day_amount,
        day_showcount,
        avg_price,
        p_pc ,
        rank")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Film record data
    #     接口：film_record
    # 描述：获取全国电影剧本备案的公示数据
    # 限量：单次最大500，总量不限制
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ann_date 	str 	N 	公布日期 （至少输入一个参数，格式：YYYYMMDD，日期不连续，定期公布）
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # rec_no 	str 	Y 	备案号
    # film_name 	str 	Y 	影片名称
    # rec_org 	str 	Y 	备案单位
    # script_writer 	str 	Y 	编剧
    # rec_result 	str 	Y 	备案结果
    # rec_area 	str 	Y 	备案地（备案时间）
    # classified 	str 	Y 	影片分类
    # date_range 	str 	Y 	备案日期区间
    # ann_date 	str 	Y 	备案结果发布时间
    function get_other_filmRecord(d_params :: Dict = Dict("ann_date" => "20181224");
        s_api::String = "film_record",
        s_fields :: String = "
        rec_no,
        film_name ,
        rec_org ,
        script_writer,
        rec_result ,
        rec_area ,
        classified,
        date_range,
        ann_date")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get News Data
    #     接口：news
    # 描述：获取主流新闻网站的快讯新闻数据
    # 限量：单次最大1000条新闻
    # 积分：用户积累1500积分可以调取，超过5000无限制，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # start_date 	datetime 	Y 	开始日期
    # end_date 	datetime 	Y 	结束日期
    # src 	str 	Y 	新闻来源 见下表
    #
    # 数据源
    # 来源名称 	src标识 	描述
    # 新浪财经 	sina 	获取新浪财经实时资讯
    # 华尔街见闻 	wallstreetcn 	华尔街见闻快讯
    # 同花顺 	10jqka 	同花顺财经新闻
    # 东方财富 	eastmoney 	东方财富财经新闻
    # 云财经 	yuncaijing 	云财经新闻
    #
    # 日期输入说明：
    #
    #     如果是某一天的数据，可以输入日期 20181120 或者 2018-11-20，比如要想取2018年11月20日的新闻，可以设置start_date='20181120', end_date='20181121' （大于数据一天）
    #     如果是加时间参数，可以设置：start_date='2018-11-20 09:00:00', end_date='2018-11-20 22:05:03'
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # datetime 	str 	Y 	新闻时间
    # content 	str 	Y 	内容
    # title 	str 	Y 	标题
    # channels 	str 	Y 	分类
    function get_other_news(d_params :: Dict = Dict("start_date" => "20181224",
        "end_date" => "20181225", "src" => "sina");
        s_api::String = "news",
        s_fields :: String = "
            datetime ,
            content,
            title,
            channels")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get cctv news
    #     接口：cctv_news
    # 描述：获取新闻联播文字稿数据，数据开始于2009年6月
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	Y 	日期（输入格式：YYYYMMDD 比如：20181211）
    #
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # title 	str 	Y 	标题
    # content 	str 	Y 	内容
    function get_other_cctvNews(d_params :: Dict = Dict("date" => "20181224");
        s_api::String = "cctv_news",
        s_fields :: String = "
        date,
        title,
        content")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Coin list
    #     接口：coinlist
    # 描述：获取全球数字货币基本信息，包括发行日期、规模、所基于的公链和算法等。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # issue_date 	str 	Y 	发行日期
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    # 输出参数
    # 名称 	类型 	描述
    # coin 	str 	货币代码
    # en_name 	str 	英文名称
    # cn_name 	str 	中文名称
    # issue_date 	str 	发行日期
    # issue_price 	float 	发行价格（美元）
    # amount 	float 	发行总量
    # supply 	float 	流通总量
    # algo 	str 	算法原理
    # area 	str 	发行地区
    # desc 	str 	描述
    # labels 	str 	标签分类
    function get_coin_list(d_params :: Dict = Dict("start_date" => "20181224", "end_date" => "20181225");
        s_api::String = "coinlist",
        s_fields :: String = "
        coin,
        en_name,
        cn_name,
        issue_date,
        issue_price ,
        amount,
        supply,
        algo,
        area,
        desc ,
        labels")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get coin pair
    #     接口：coinpair
    # 描述：获取Tushare所能提供的所有交易和交易对名称，用于获得行情等数据。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	N 	日期
    # exchange 	str 	Y 	交易所
    #
    # 输出参数
    # 名称 	类型 	描述
    # trade_date 	str 	日期
    # exchange 	str 	交易所
    # exchange_pair 	str 	交易所原始交易对名称
    # ts_pair 	str 	Tushare标准名称
    #
    # 交易所列表
    # 序号 	交易所名称
    # 1 	allcoin
    # 2 	bcex
    # 3 	bibox
    # 4 	bigone
    # 5 	binance
    # 6 	bitbank
    # 7 	bitfinex
    # 8 	bitflyer
    # 9 	bitflyex
    # 10 	bithumb
    # 11 	bitmex
    # 12 	bitstamp
    # 13 	bitstar
    # 14 	bittrex
    # 15 	bitvc
    # 16 	bitz
    # 17 	bleutrade
    # 18 	btcbox
    # 19 	btcc
    # 20 	btccp
    # 21 	btcturk
    # 22 	btc_usd_index
    # 23 	bter
    # 24 	chbtc
    # 25 	cobinhood
    # 26 	coinbase
    # 27 	coinbene
    # 28 	coincheck
    # 29 	coinegg
    # 30 	coinex
    # 31 	coinone
    # 32 	coinsuper
    # 33 	combine
    # 34 	currency
    # 35 	dextop
    # 36 	digifinex
    # 37 	exmo
    # 38 	exx
    # 39 	fcoin
    # 40 	fisco
    # 41 	future_bitmex
    # 42 	gate
    # 43 	gateio
    # 44 	gdax
    # 45 	gemini
    # 46 	hadax
    # 47 	hbus
    # 48 	hft
    # 49 	hitbtc
    # 50 	huobi
    # 51 	huobiotc
    # 52 	huobip
    # 53 	huobix
    # 54 	idax
    # 55 	idex
    # 56 	index
    # 57 	itbit
    # 58 	jubi
    # 59 	korbit
    # 60 	kraken
    # 61 	kucoin
    # 62 	lbank
    # 63 	lbc
    # 64 	liqui
    # 65 	okcn
    # 66 	okcom
    # 67 	okef
    # 68 	okex
    # 69 	okotc
    # 70 	okusd
    # 71 	poloniex
    # 72 	quoine
    # 73 	quoinex
    # 74 	rightbtc
    # 75 	shuzibi
    # 76 	simex
    # 77 	topbtc
    # 78 	upbit
    # 79 	viabtc
    # 80 	yobit
    # 81 	yuanbao
    # 82 	yunbi
    # 83 	zaif
    # 84 	zb
    function get_coin_pair(d_params :: Dict = Dict("exchange" => "huobi");
        s_api::String = "coinpair",
        s_fields :: String = "
        trade_date,
        exchange,
        exchange_pair,
        ts_pair")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Coin exchenge info
    #     接口：coinexchanges
    # 描述：获取全球数字货币交易所基本信息。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # exchange 	str 	N 	交易所
    # area_code 	str 	N 	地区 （见下面列表）
    #
    # 输出参数
    # 名称 	类型 	描述
    # exchange 	str 	交易所代码
    # name 	str 	交易所名称
    # pairs 	int 	交易对数量
    # area_code 	str 	所在地区代码
    # area 	str 	所在地区
    # coin_trade 	str 	支持现货交易
    # fut_trade 	str 	支持期货交易
    # oct_trade 	str 	支持场外交易
    # deep_share 	str 	支持共享交易深度
    # mineable 	str 	支持挖矿交易
    # desc 	str 	交易所简介
    # website 	str 	交易所官网
    # twitter 	str 	交易所twitter
    # facebook 	str 	交易所facebook
    # weibo 	str 	交易所weibo
    #
    # 交易所地区说明
    # 地区代码 	地区名称
    # ae 	阿联酋
    # au 	澳大利亚
    # br 	巴西
    # by 	白俄罗斯
    # bz 	伯利兹
    # ca 	加拿大
    # cbb 	加勒比
    # ch 	瑞士
    # cl 	智利
    # cn 	中国
    # cy 	塞浦路斯
    # dk 	丹麦
    # ee 	爱沙尼亚
    # es 	西班牙
    # hk 	中国香港
    # id 	印度尼西亚
    # il 	以色列
    # in 	印度
    # jp 	日本
    # kh 	柬埔寨
    # kr 	韩国
    # ky 	开曼群岛
    # la 	老挝
    # mn 	蒙古国
    # mt 	马耳他
    # mx 	墨西哥
    # my 	马来西亚
    # nl 	荷兰
    # nz 	新西兰
    # ph 	菲律宾
    # pl 	波兰
    # ru 	俄罗斯
    # sc 	塞舌尔
    # sg 	新加坡
    # th 	泰国
    # tr 	土耳其
    # tz 	坦桑尼亚
    # ua 	乌克兰
    # uk 	英国
    # us 	美国
    # vn 	越南
    # ws 	萨摩亚
    # za 	南非
    function get_coin_exchange(;s_api::String = "coinexchanges",
        d_params :: Dict = Dict(), s_fields :: String = "
        exchange,
        name ,
        pairs,
        area_code,
        area,
        coin_trade,
        fut_trade,
        oct_trade ,
        deep_share ,
        mineable,
        desc ,
        website,
        twitter ,
        facebook,
        weibo")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Coin exchange fees
    #     接口：coinfees
    # 描述：获取交易所当前和历史交易费率，目前支持的有huobi、okex、binance和bitfinex。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # exchange 	str 	Y 	交易所
    # asset_type 	str 	N 	交易类别 coin币交易（默认） future期货交易
    #
    # 输出参数
    # 名称 	类型 	描述
    # exchange 	str 	交易所
    # level 	str 	交易级别和类型
    # maker_fee 	float 	挂单费率
    # taker_fee 	float 	吃单费率
    # asset_type 	str 	资产类别 coin币交易 future期货交易
    # start_date 	str 	费率开始执行日期
    # end_date 	str 	本次费率失效日期
    #
    # exchange说明
    # exchange 	名称 	优惠情况
    # huobi 	火币 	按VIP级别不同有优惠，VIP需购买
    # okex 	okex 	按成交额度有优惠
    # binance 	币安 	按年优惠
    # bitfinex 	bitfinex 	按成交额度大小优惠
    # fcoin 	fcoin 	交易即挖矿，先收后返
    # coinex 	coin 	交易即挖矿，先收后返
    function get_coin_fee(d_params :: Dict = Dict("exchange" => "huobi");
        s_api::String = "coinfees",
        s_fields :: String = "
        exchange ,
        level,
        maker_fee,
        taker_fee ,
        asset_type ,
        start_date ,
        end_date")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get ubindex constituents
    # 接口：ubindex_constituents
    #
    # 描述：获取优币指数成分所对应的流通市值、权重以及指数调仓日价格等数据。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # index_name 	str 	Y 	指数名称（支持的指数请见下表）
    # start_date 	str 	Y 	开始日期（包含），格式：yyyymmdd
    # end_date 	str 	Y 	结束日期（包含），格式：yyyymmdd
    #
    # 输出参数
    # 名称 	类型 	描述
    # trade_date 	str 	指数日期
    # index_name 	str 	指数名称
    # symbol 	str 	成分货币简称
    # circulated_cap 	float 	计算周期内日流动市值均值
    # weight 	float 	计算周期内权重
    # price 	float 	指数日价格
    # create_time 	datetime 	入库时间
    #
    # 支持的指数
    # 指数名称 	说明
    # UBI7 	平台类TOP7项目指数
    # UBI0 	平台类TOP10项目指数
    # UBI20 	平台类TOP20项目指数
    # UBC7 	币类TOP7项目指数
    # UB7 	市场整体类TOP7项目指数
    # UB20 	市场整体类TOP20项目指数
    function get_coin_indexConst(d_params :: Dict = Dict("index_name" => "UBI7", "start_date" => "20180801",
    "end_date" => "20180901");
        s_api::String = "ubindex_constituents",
        s_fields :: String = "
        trade_date,
        index_name,
        symbol,
        circulated_cap,
        weight ,
        price ,
        create_time")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get coin news from jinse
    #     接口：jinse
    # 描述：获取金色采集即时和历史资讯数据（5分钟更新一次）
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # start_date 	datetime 	Y 	开始时间 格式：YYYY-MM-DD HH:MM:SS
    # end_date 	datetime 	Y 	结束时间 格式：YYYY-MM-DD HH:MM:SS
    #
    # 输出参数
    # 名称 	类型 	描述
    # title 	str 	标题
    # content 	str 	内容
    # type 	str 	类型
    # url 	str 	URL
    # datetime 	str 	时间
    function get_coin_newsJinse(d_params :: Dict = Dict("start_date" => "2018-08-01 14:15:41", "end_date" => "2018-09-01 16:20:11");
        s_api::String = "jinse",
        s_fields :: String = "
        title,
        content,
        type,
        url,
        datetime")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get coin news from btc
    #     接口：btc8
    # 描述：获取巴比特即时和历史资讯数据（5分钟更新一次）
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # start_date 	datetime 	Y 	开始时间 格式：YYYY-MM-DD HH:MM:SS
    # end_date 	datetime 	Y 	结束时间 格式：YYYY-MM-DD HH:MM:SS
    #
    # 输出参数
    # 名称 	类型 	描述
    # title,
    # content,
    # type,
    # url,
    # datetime
    function get_coin_newsBTC(d_params :: Dict = Dict("start_date" => "2018-08-01 14:15:41", "end_date" => "2018-09-01 16:20:11");
        s_api::String = "btc8",
        s_fields :: String = "
        title,
        content,
        type,
        url,
        datetime")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get coin news from bishijie
    #     接口：bishijie
    # 描述：获取币世界即时和历史资讯数据（5分钟更新一次）
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # start_date 	datetime 	Y 	开始时间 格式：YYYY-MM-DD HH:MM:SS
    # end_date 	datetime 	Y 	结束时间 格式：YYYY-MM-DD HH:MM:SS
    #
    # 输出参数
    # 名称 	类型 	描述
    # title,
    # content,
    # type,
    # url,
    # datetime
    function get_coin_newsBSJ(d_params :: Dict = Dict("start_date" => "2018-08-01 14:15:41", "end_date" => "2018-09-01 16:20:11");
        s_api::String = "bishijie",
        s_fields :: String = "
        title,
        content,
        type,
        url,
        datetime")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get coin exchange announcement
    #     接口：exchange_ann
    # 描述：获取交易所即时和历史资讯数据（5分钟更新一次）
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # start_date 	datetime 	Y 	开始时间 格式：YYYY-MM-DD HH:MM:SS
    # end_date 	datetime 	Y 	结束时间 格式：YYYY-MM-DD HH:MM:SS
    #
    # 输出参数
    # 名称 	类型 	描述
    # title,
    # content,
    # type,
    # url,
    # datetime
    function get_coin_exchangeAnn(d_params :: Dict = Dict("start_date" => "2018-08-01 14:15:41", "end_date" => "2018-09-01 16:20:11");
        s_api::String = "exchange_ann",
        s_fields :: String = "
        title,
        content,
        type,
        url,
        datetime")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get coin exchange twitter
    #     接口：exchange_twitter
    #
    # 描述：获取Twitter上数字货币交易所发布的消息（5分钟更新一次，未来根据服务器压力再做调整）
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # start_date 	datetime 	Y 	开始时间 格式：YYYY-MM-DD HH:MM:SS
    # end_date 	datetime 	Y 	结束时间 格式：YYYY-MM-DD HH:MM:SS
    #
    # 输出参数
    # 名称 	类型 	描述
    # id 	int 	记录ID（采集站点中的）
    # account_id 	int 	交易所账号ID（采集站点中的）
    # account 	str 	交易所账号
    # nickname 	str 	交易所昵称
    # avatar 	str 	头像
    # content_id 	int 	类容ID（采集站点中的）
    # content 	str 	原始内容
    # is_retweet 	int 	是否转发：0-否；1-是
    # retweet_content 	json 	转发内容，json格式，包含了另一个Twitter结构
    # media 	json 	附件，json格式，包含了资源类型、资源链接等
    # posted_at 	int 	发布时间戳
    # content_translation 	str 	内容翻译
    # str_posted_at 	str 	发布时间，根据posted_at转换而来
    # create_at 	str 	采集时间
    function get_coin_exchangeTwitter(d_params :: Dict = Dict("start_date" => "2018-08-01 14:15:41", "end_date" => "2018-09-01 16:20:11");
        s_api::String = "exchange_twitter",
        s_fields :: String = "
        id,
        account_id ,
        account,
        nickname ,
        avatar ,
        content_id ,
        content ,
        is_retweet ,
        retweet_content,
        media,
        posted_at,
        content_translation ,
        str_posted_at ,
        create_at")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get coin kol twitter
    #     接口：twitter_kol
    #
    # 描述：获取Twitter上数字货币交易所发布的消息（5分钟更新一次，未来根据服务器压力再做调整）
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # start_date 	datetime 	Y 	开始时间 格式：YYYY-MM-DD HH:MM:SS
    # end_date 	datetime 	Y 	结束时间 格式：YYYY-MM-DD HH:MM:SS
    #
    # 输出参数
    # 名称 	类型 	描述
    # id 	int 	记录ID（采集站点中的）
    # account_id 	int 	交易所账号ID（采集站点中的）
    # account 	str 	交易所账号
    # nickname 	str 	交易所昵称
    # avatar 	str 	头像
    # content_id 	int 	类容ID（采集站点中的）
    # content 	str 	原始内容
    # is_retweet 	int 	是否转发：0-否；1-是
    # retweet_content 	json 	转发内容，json格式，包含了另一个Twitter结构
    # media 	json 	附件，json格式，包含了资源类型、资源链接等
    # posted_at 	int 	发布时间戳
    # content_translation 	str 	内容翻译
    # str_posted_at 	str 	发布时间，根据posted_at转换而来
    # create_at 	str 	采集时间
    function get_coin_kolTwitter(d_params :: Dict = Dict("start_date" => "2018-08-01 14:15:41", "end_date" => "2018-09-01 16:20:11");
        s_api::String = "twitter_kol",
        s_fields :: String = "
        id,
        account_id ,
        account,
        nickname ,
        avatar ,
        content_id ,
        content ,
        is_retweet ,
        retweet_content,
        media,
        posted_at,
        content_translation ,
        str_posted_at ,
        create_at")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    ###################### Trading Data #########################
    # Get Stock Daily Data
    # 输入参数
    #     名称 	类型 	必选 	描述
    # ts_code 	str 	N 	股票代码（二选一）
    # trade_date 	str 	N 	交易日期（二选一）
    # start_date 	str 	N 	开始日期(YYYYMMDD)
    # end_date 	str 	N 	结束日期(YYYYMMDD)

    # Get Stock Daily Trade Data
    # 注：日期都填YYYYMMDD格式，比如20181010
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	股票代码
    # trade_date 	str 	交易日期
    # open 	float 	开盘价
    # high 	float 	最高价
    # low 	float 	最低价
    # close 	float 	收盘价
    # pre_close 	float 	昨收价
    # change 	float 	涨跌额
    # pct_chg 	float 	涨跌幅 （未复权，如果是复权请用 通用行情接口 ）
    # vol 	float 	成交量 （手）
    # amount 	float 	成交额 （千元）
    function get_stock_daily(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "daily",
        s_fields :: String = "ts_code,
        trade_date, open, high, low, close, pre_close, change, pct_chg, vol, amount")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get adj factor adj_factor * preadj_price = adj_price
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	股票代码
    # trade_date 	str 	N 	交易日期(YYYYMMDD，下同)
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    # 注：日期都填YYYYMMDD格式，比如20181010
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	股票代码
    # trade_date 	str 	交易日期
    # adj_factor 	float 	复权因子
    function get_stock_adjFactor(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "adj_factor",
        s_fields :: String = "ts_code,
        trade_date, adj_factor")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Every day trading fundamental indices
    # 获取全部股票每日重要的基本面指标，可用于选股分析、报表展示等。
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	股票代码（二选一）
    # trade_date 	str 	N 	交易日期 （二选一）
    # start_date 	str 	N 	开始日期(YYYYMMDD)
    # end_date 	str 	N 	结束日期(YYYYMMDD)
    #
    # 注：日期都填YYYYMMDD格式，比如20181010
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS股票代码
    # trade_date 	str 	交易日期
    # close 	float 	当日收盘价
    # turnover_rate 	float 	换手率
    # turnover_rate_f 	float 	换手率（自由流通股）
    # volume_ratio 	float 	量比
    # pe 	float 	市盈率（总市值/净利润）
    # pe_ttm 	float 	市盈率（TTM）
    # pb 	float 	市净率（总市值/净资产）
    # ps 	float 	市销率
    # ps_ttm 	float 	市销率（TTM）
    # total_share 	float 	总股本 （万）
    # float_share 	float 	流通股本 （万）
    # free_share 	float 	自由流通股本 （万）
    # total_mv 	float 	总市值 （万元）
    # circ_mv 	float 	流通市值（万元）
    function get_stock_dailyBasic(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "daily_basic",
        s_fields :: String = "ts_code,
        trade_date, close, turnover_rate, turnover_rate_f, volume_ratio, pe, pe_ttm,
        pb, ps, ps_ttm, total_share, float_share, free_share, total_mv, circ_mv")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Daily Suspend Data
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	股票代码(三选一)
    # suspend_date 	str 	N 	停牌日期(三选一)
    # resume_date 	str 	N 	复牌日期(三选一)
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	股票代码
    # suspend_date 	str 	停牌日期
    # resume_date 	str 	复牌日期
    # ann_date 	str 	公告日期
    # suspend_reason 	str 	停牌原因
    # reason_type 	str 	停牌原因类别
    function get_stock_suspend(d_params :: Dict = Dict("ts_code" => "000001.SZ");
        s_api::String = "suspend",
        s_fields :: String = "ts_code,
        suspend_date, resume_date, ann_date, suspend_date, reason_type")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Index daily data
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	指数代码
    # trade_date 	str 	N 	交易日期 （日期格式：YYYYMMDD，下同）
    # start_date 	str 	N 	开始日期
    # end_date 	None 	N 	结束日期
    #
    # 输出参数
    # 名称 	类型 	描述
    # ts_code 	str 	TS指数代码
    # trade_date 	str 	交易日
    # close 	float 	收盘点位
    # open 	float 	开盘点位
    # high 	float 	最高点位
    # low 	float 	最低点位
    # pre_close 	float 	昨日收盘点
    # change 	float 	涨跌点
    # pct_chg 	float 	涨跌幅
    # vol 	float 	成交量（手）
    # amount 	float 	成交额（千元）
    function get_index_daily(d_params :: Dict = Dict("ts_code" => "399300.SZ");
        s_api::String = "index_daily",
        s_fields :: String = "
        ts_code,
        trade_date,
        close,
        open,
        high,
        low,
        pre_close,
        change,
        pct_chg,
        vol ,
        amount")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Index Weight and constitution
    #     接口：index_weight
    # 描述：获取各类指数成分和权重，月度数据 ，如需日度指数成分和权重，请联系 waditu@163.com
    # 来源：指数公司网站公开数据
    # 积分：用户需要至少400积分才可以调取，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # index_code 	str 	Y 	指数代码 (二选一)
    # trade_date 	str 	Y 	交易日期 （二选一）
    # start_date 	str 	N 	开始日期
    # end_date 	None 	N 	结束日期
    #
    # 输出参数
    # 名称 	类型 	描述
    # index_code 	str 	指数代码
    # con_code 	str 	成分代码
    # trade_date 	str 	交易日期
    # weight 	float 	权重
    function get_index_weightMonthly(d_params :: Dict = Dict("index_code" => "399300.SZ");
        s_api::String = "index_weight",
        s_fields :: String = "
        index_code,
        con_code,
        trade_date ,
        weight")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Index's daily basic info
    #     接口：index_dailybasic
    # 描述：目前只提供上证综指，深证成指，上证50，中证500，中小板指，创业板指的每日指标数据
    # 数据来源：Tushare社区统计计算
    # 数据历史：从2004年1月开始提供
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	N 	交易日期 （格式：YYYYMMDD，比如20181018，下同）
    # ts_code 	str 	N 	TS代码
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    # 注：trade_date，ts_code 至少要输入一个参数，单次限量3000条（即，单一指数单次可提取超过12年历史），总量不限制。
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # trade_date 	str 	Y 	交易日期
    # total_mv 	float 	Y 	当日总市值（元）
    # float_mv 	float 	Y 	当日流通市值（元）
    # total_share 	float 	Y 	当日总股本（股）
    # float_share 	float 	Y 	当日流通股本（股）
    # free_share 	float 	Y 	当日自由流通股本（股）
    # turnover_rate 	float 	Y 	换手率
    # turnover_rate_f 	float 	Y 	换手率(基于自由流通股本)
    # pe 	float 	Y 	市盈率
    # pe_ttm 	float 	Y 	市盈率TTM
    # pb 	float 	Y 	市净率
    function get_index_basicDaily(d_params :: Dict = Dict("ts_code" => "399300.SZ");
        s_api::String = "index_dailybasic",
        s_fields :: String = "
        ts_code,
        trade_date,
        total_mv ,
        float_mv ,
        total_share,
        float_share ,
        free_share,
        turnover_rate ,
        turnover_rate_f ,
        pe,
        pe_ttm,
        pb")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Public Fund NetValue
    #     输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	TS基金代码 （二选一）
    # end_date 	str 	N 	净值日期 （二选一）
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # ann_date 	str 	Y 	公告日期
    # end_date 	str 	Y 	截止日期
    # unit_nav 	float 	Y 	单位净值
    # accum_nav 	float 	Y 	累计净值
    # accum_div 	float 	Y 	累计分红
    # net_asset 	float 	Y 	资产净值
    # total_netasset 	float 	Y 	合计资产净值
    # adj_nav 	float 	Y 	复权单位净值
    function get_fund_netvalue(d_params :: Dict = Dict("ts_code" => "001753.OF");
        s_api::String = "fund_nav",
        s_fields :: String = "
        ts_code ,
        ann_date,
        end_date,
        unit_nav ,
        accum_nav,
        accum_div,
        net_asset,
        total_netasset,
        adj_nav")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Public Fund Portfolio
    #     接口：fund_portfolio
    # 描述：获取公募基金持仓数据，季度更新
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	Y 	基金代码
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS基金代码
    # ann_date 	str 	Y 	公告日期
    # end_date 	str 	Y 	截止日期
    # symbol 	str 	Y 	股票代码
    # mkv 	float 	Y 	持有股票市值(元)
    # amount 	float 	Y 	持有股票数量（股）
    # stk_mkv_ratio 	float 	Y 	占股票市值比
    # stk_float_ratio 	float 	Y 	占流通股本比例
    function get_fund_portfolio(d_params :: Dict = Dict("ts_code" => "001753.OF");
        s_api::String = "fund_portfolio",
        s_fields :: String = "
        ts_code,
        ann_date ,
        end_date ,
        symbol ,
        mkv ,
        amount,
        stk_mkv_ratio ,
        stk_float_ratio")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Fund price Daily
    #     接口：fund_daily
    # 描述：获取场内基金日线行情，类似股票日行情
    # 更新：每日收盘后2小时内
    # 限量：单次最大800行记录，总量不限制
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	基金代码（二选一）
    # trade_date 	str 	N 	交易日期（二选一）
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # trade_date 	str 	Y 	交易日期
    # open 	float 	Y 	开盘价(元)
    # high 	float 	Y 	最高价(元)
    # low 	float 	Y 	最低价(元)
    # close 	float 	Y 	收盘价(元)
    # pre_close 	float 	Y 	昨收盘价(元)
    # change 	float 	Y 	涨跌额(元)
    # pct_chg 	float 	Y 	涨跌幅(%)
    # vol 	float 	Y 	成交量(手)
    # amount 	float 	Y 	成交额(千元)
    function get_fund_daily(d_params :: Dict = Dict("ts_code" => "150008.SZ");
        s_api::String = "fund_daily",
        s_fields :: String = "
        ts_code ,
        trade_date ,
        open ,
        high ,
        low ,
        close ,
        pre_close ,
        change ,
        pct_chg ,
        vol ,
        amount ")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Future Price daily
    #     接口：fut_daily
    # 描述：期货日线行情数据
    # 限量：单次最大2000条，总量不限制
    # 积分：用户需要至少200积分才可以调取，未来可能调整积分，请尽量多的积累积分。具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	N 	交易日期
    # ts_code 	str 	N 	合约代码
    # exchange 	str 	N 	交易所代码
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS合约代码
    # trade_date 	str 	Y 	交易日期
    # pre_close 	float 	Y 	昨收盘价
    # pre_settle 	float 	Y 	昨结算价
    # open 	float 	Y 	开盘价
    # high 	float 	Y 	最高价
    # low 	float 	Y 	最低价
    # close 	float 	Y 	收盘价
    # settle 	float 	Y 	结算价
    # change1 	float 	Y 	涨跌1 收盘价-昨结算价
    # change2 	float 	Y 	涨跌2 结算价-昨结算价
    # vol 	float 	Y 	成交量(手)
    # amount 	float 	Y 	成交金额(万元)
    # oi 	float 	Y 	持仓量(手)
    # oi_chg 	float 	Y 	持仓量变化
    # delv_settle 	float 	N 	交割结算价
    function get_future_daily(d_params :: Dict = Dict("ts_code" => "CU1811.SHF");
        s_api::String = "fut_daily",
        s_fields :: String = "
        ts_code ,
        trade_date ,
        pre_close ,
        pre_settle ,
        open ,
        high ,
        low,
        close ,
        settle ,
        change1,
        change2 ,
        vol,
        amount ,
        oi,
        oi_chg ,
        delv_settle")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Future Daily holding rank
    # 接口：fut_holding
    # 描述：获取每日成交持仓排名数据
    # 限量：单次最大2000，总量不限制
    # 积分：用户需要至少600积分才可以调取，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	N 	交易日期 （trade_date/symbol至少输入一个参数）
    # symbol 	str 	N 	合约或产品代码
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # exchange 	str 	N 	交易所代码
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # trade_date 	str 	Y 	交易日期
    # symbol 	str 	Y 	合约代码或类型
    # broker 	str 	Y 	期货公司会员简称
    # vol 	int 	Y 	成交量
    # vol_chg 	int 	Y 	成交量变化
    # long_hld 	int 	Y 	持买仓量
    # long_chg 	int 	Y 	持买仓量变化
    # short_hld 	int 	Y 	持卖仓量
    # short_chg 	int 	Y 	持卖仓量变化
    # exchange 	str 	N 	交易所
    function get_future_holding(d_params :: Dict = Dict("symbol" => "C");
        s_api::String = "fut_holding",
        s_fields :: String = "
        trade_date ,
        symbol ,
        broker ,
        vol ,
        vol_chg ,
        long_hld ,
        long_chg ,
        short_hld ,
        short_chg ,
        exchange")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Future ware Statement report
    #     接口：fut_wsr
    # 描述：获取仓单日报数据，了解各仓库/厂库的仓单变化
    # 限量：单次最大1000，总量不限制
    # 积分：用户需要至少600积分才可以调取，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	N 	交易日期
    # symbol 	str 	N 	产品代码
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # exchange 	str 	N 	交易所代码
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # trade_date 	str 	Y 	交易日期
    # symbol 	str 	Y 	产品代码
    # fut_name 	str 	Y 	产品名称
    # warehouse 	str 	Y 	仓库名称
    # wh_id 	str 	N 	仓库编号
    # pre_vol 	int 	Y 	昨日仓单量
    # vol 	int 	Y 	今日仓单量
    # vol_chg 	int 	Y 	增减量
    # area 	str 	N 	地区
    # year 	str 	N 	年度
    # grade 	str 	N 	等级
    # brand 	str 	N 	品牌
    # place 	str 	N 	产地
    # pd 	int 	N 	升贴水
    # is_ct 	str 	N 	是否折算仓单
    # unit 	str 	Y 	单位
    # exchange 	str 	N 	交易所
    function get_future_WSR(d_params :: Dict = Dict("symbol" => "C");
        s_api::String = "fut_wsr",
        s_fields :: String = "
        trade_date,
        symbol,
        fut_name,
        warehouse,
        wh_id,
        pre_vol ,
        vol,
        vol_chg,
        area,
        year ,
        grade,
        brand ,
        place,
        pd,
        is_ct ,
        unit ,
        exchange")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Settlement info
    #     接口：fut_settle
    # 描述：获取每日结算参数数据，包括交易和交割费率等
    # 限量：单次最大1000，总量不限制
    # 积分：用户需要至少600积分才可以调取，具体请参阅积分获取办法
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	N 	交易日期 （trade_date/ts_code至少需要输入一个参数）
    # ts_code 	str 	N 	合约代码
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # exchange 	str 	N 	交易所代码
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	合约代码
    # trade_date 	str 	Y 	交易日期
    # settle 	float 	Y 	结算价
    # trading_fee_rate 	float 	Y 	交易手续费率
    # trading_fee 	float 	Y 	交易手续费
    # delivery_fee 	float 	Y 	交割手续费
    # b_hedging_margin_rate 	float 	Y 	买套保交易保证金率
    # s_hedging_margin_rate 	float 	Y 	卖套保交易保证金率
    # long_margin_rate 	float 	Y 	买投机交易保证金率
    # short_margin_rate 	float 	Y 	卖投机交易保证金率
    # offset_today_fee 	float 	N 	平今仓手续率
    # exchange 	str 	N 	交易所
    function get_future_settleInfo(d_params :: Dict = Dict("trade_date" => "20181114");
        s_api::String = "fut_settle",
        s_fields :: String = "
        ts_code ,
        trade_date ,
        settle,
        trading_fee_rate,
        trading_fee ,
        delivery_fee ,
        b_hedging_margin_rate ,
        s_hedging_margin_rate ,
        long_margin_rate ,
        short_margin_rate ,
        offset_today_fee,
        exchange")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get Option Trading Data
    #     接口：opt_daily
    # 描述：获取期权日线行情
    # 限量：单次最大1000，总量不限制
    # 积分：用户需要至少200积分才可以调取，但有流量控制，请自行提高积分，积分越多权限越大，具体请参阅积分获取办法
    #
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # ts_code 	str 	N 	TS合约代码（输入代码或时间至少任意一个参数）
    # trade_date 	str 	N 	交易日期
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # exchange 	str 	N 	交易所
    #
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # ts_code 	str 	Y 	TS代码
    # trade_date 	str 	Y 	交易日期
    # exchange 	str 	Y 	交易市场
    # pre_settle 	float 	Y 	昨结算价
    # pre_close 	float 	Y 	前收盘价
    # open 	float 	Y 	开盘价
    # high 	float 	Y 	最高价
    # low 	float 	Y 	最低价
    # close 	float 	Y 	收盘价
    # settle 	float 	Y 	结算价
    # vol 	float 	Y 	成交量(手)
    # amount 	float 	Y 	成交金额(万元)
    # oi 	float 	Y 	持仓量(手)
    function get_option_daily(d_params :: Dict = Dict("trade_date" => "20181114");
        s_api::String = "opt_daily",
        s_fields :: String = "
        ts_code ,
        trade_date ,
        exchange ,
        pre_settle ,
        pre_close,
        open ,
        high ,
        low ,
        close ,
        settle ,
        vol ,
        amount,
        oi")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # SHIBOR
    #     接口：shibor
    # 描述：shibor利率
    # 限量：单次最大2000，总量不限制，可通过设置开始和结束日期分段获取
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	N 	日期 (日期输入格式：YYYYMMDD，下同)
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # on 	float 	Y 	隔夜
    # 1w 	float 	Y 	1周
    # 2w 	float 	Y 	2周
    # 1m 	float 	Y 	1个月
    # 3m 	float 	Y 	3个月
    # 6m 	float 	Y 	6个月
    # 9m 	float 	Y 	9个月
    # 1y 	float 	Y 	1年
    function get_bond_SHIBOR(;s_api::String = "shibor",
        d_params :: Dict = Dict(), s_fields :: String = "
        date ,
        on ,
        1w,
        2w,
        1m ,
        3m,
        6m ,
        9m,
        1y")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # SHIBOR Pricing
    #     接口：shibor_quote
    # 描述：Shibor报价数据
    # 限量：单次最大4000行数据，总量不限制，可通过设置开始和结束日期分段获取
    # 积分：用户积累120积分可以调取，具体请参阅积分获取办法
    #
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	N 	日期 (日期输入格式：YYYYMMDD，下同)
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # bank 	str 	N 	银行名称 （中文名称，例如 农业银行）
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # bank 	str 	Y 	报价银行
    # on_b 	float 	Y 	隔夜_Bid
    # on_a 	float 	Y 	隔夜_Ask
    # 1w_b 	float 	Y 	1周_Bid
    # 1w_a 	float 	Y 	1周_Ask
    # 2w_b 	float 	Y 	2周_Bid
    # 2w_a 	float 	Y 	2周_Ask
    # 1m_b 	float 	Y 	1月_Bid
    # 1m_a 	float 	Y 	1月_Ask
    # 3m_b 	float 	Y 	3月_Bid
    # 3m_a 	float 	Y 	3月_Ask
    # 6m_b 	float 	Y 	6月_Bid
    # 6m_a 	float 	Y 	6月_Ask
    # 9m_b 	float 	Y 	9月_Bid
    # 9m_a 	float 	Y 	9月_Ask
    # 1y_b 	float 	Y 	1年_Bid
    # 1y_a 	float 	Y 	1年_Ask
    function get_bond_SHIBORpricing(;s_api::String = "shibor_quote",
        d_params :: Dict = Dict(), s_fields :: String = "
        date ,
        bank ,
        on_b,
        on_a ,
        1w_b ,
        1w_a ,
        2w_b,
        2w_a ,
        1m_b ,
        1m_a ,
        3m_b ,
        3m_a ,
        6m_b ,
        6m_a ,
        9m_b,
        9m_a ,
        1y_b ,
        1y_a")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # LPR Interest Rate
    #     接口：shibor_lpr
    # 描述：LPR贷款基础利率
    # 限量：单次最大4000(相当于单次可提取18年历史)，总量不限制，可通过设置开始和结束日期分段获取
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	N 	日期 (日期输入格式：YYYYMMDD，下同)
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # 1y 	float 	Y 	1年贷款利率
    function get_bond_LPR(;s_api::String = "shibor_lpr",
        d_params :: Dict = Dict(), s_fields :: String = "
        date ,
        1y")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get LIBOR
    #     接口：libor
    # 描述：Libor拆借利率
    # 限量：单次最大4000行数据，总量不限制，可通过设置开始和结束日期分段获取
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	N 	日期 (日期输入格式：YYYYMMDD，下同)
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    # curr_type 	str 	N 	货币代码 (USD美元 EUR欧元 JPY日元 GBP英镑 CHF瑞郎，默认是USD)
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # curr_type 	str 	Y 	货币
    # on 	float 	Y 	隔夜
    # 1w 	float 	Y 	1周
    # 1m 	float 	Y 	1个月
    # 2m 	float 	Y 	2个月
    # 3m 	float 	Y 	3个月
    # 6m 	float 	Y 	6个月
    # 12m 	float 	Y 	12个月
    function get_bond_LIBOR(;s_api::String = "libor",
        d_params :: Dict = Dict(), s_fields :: String = "
        date ,
        curr_type ,
        on ,
        1w ,
        1m,
        2m ,
        3m,
        6m,
        12m")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get HIBOR
    #     接口：hibor
    # 描述：Hibor利率
    # 限量：单次最大4000行数据，总量不限制，可通过设置开始和结束日期分段获取
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # date 	str 	N 	日期 (日期输入格式：YYYYMMDD，下同)
    # start_date 	str 	N 	开始日期
    # end_date 	str 	N 	结束日期
    #
    # 输出参数
    # 名称 	类型 	默认显示 	描述
    # date 	str 	Y 	日期
    # on 	float 	Y 	隔夜
    # 1w 	float 	Y 	1周
    # 2w 	float 	Y 	2周
    # 1m 	float 	Y 	1个月
    # 2m 	float 	Y 	2个月
    # 3m 	float 	Y 	3个月
    # 6m 	float 	Y 	6个月
    # 12m 	float 	Y 	12个月
    function get_bond_HIBOR(;s_api::String = "hibor",
        d_params :: Dict = Dict(), s_fields :: String = "
        date ,
        on ,
        1w ,
        2w,
        1m,
        2m ,
        3m,
        6m,
        12m")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get coin market value daily
    #     接口：coincap
    # 描述：获取数字货币每日市值数据，该接口每隔6小时采集一次数据，所以当日每个品种可能有多条数据，用户可根据实际情况过滤截取使用。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # trade_date 	str 	Y 	日期
    # coin 	str 	N 	coin代码, e.g. BTC/ETH/QTUM
    #
    # 输出参数
    # 名称 	类型 	描述
    # trade_date 	str 	交易日期
    # coin 	str 	货币代码
    # name 	str 	货币名称
    # marketcap 	str 	市值（美元）
    # price 	float 	当前时间价格（美元）
    # vol24 	float 	24小时成交额（美元）
    # supply 	float 	流通总量
    # create_time 	str 	数据采集时间
    function get_coin_marketValuedaily(d_params :: Dict = Dict("trade_date" => 20180806);
        s_api::String = "coincap",
        s_fields :: String = "
        trade_date,
        coin,
        name,
        marketcap,
        price,
        vol24,
        supply,
        create_time")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get coin bar daily
    # 接口：coinbar
    # 描述：获取数字货币行情数据，目前支持币币交易和期货合约交易。如果是币币交易，exchange参数请输入huobi,okex,binance,bitfinex等。如果是期货，exchange参数请输入future_xxx，比如future_okex，future_bitmex。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # exchange 	str 	Y 	交易所名称
    # symbol 	str 	Y 	数字货币交易对
    # start_date 	datetime 	N 	开始时间
    # end_date 	datetime 	N 	结束时间
    # freq 	str 	Y 	行情频率
    # contract_type 	str 	N 	合约类型(只在exchange='future_xxx'情况下有用)
    #
    # 输出参数
    # 名称 	类型 	描述
    # symbol 	str 	数字货币交易对
    # date 	datetime 	行情时间
    # open 	float 	开盘价
    # high 	float 	最高价
    # low 	float 	最低价
    # close 	float 	收盘价
    # count 	int 	成交笔数（默认不展示，有些交易所没有此项数据，若需要请在fields里添加）
    # contract_type 	str 	合约类型 (只在取期货数据才有数据)
    # vol 	float 	成交量
    # amount 	float 	成交额 (默认不展示,需在fields里添加上，有些交易所没有此项数据)
    #
    # freq说明
    # freq 	说明
    # 1min 	1分钟
    # 5min 	5分钟
    # 15min 	15分钟
    # 30min 	30分钟
    # 60min 	60分钟
    # daily 	日线
    # week 	周线
    function get_coin_daily(d_params :: Dict = Dict("exchange" => "huobi", "symbol" => "bchusdt",
        "freq" => "daily");
        s_api::String = "coinbar",
        s_fields :: String = "
        symbol,
        date,
        open,
        high,
        low,
        close,
        count ,
        vol,
        amount")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get btc market value
    #     接口：btc_marketcap
    # 描述：获取比特币历史以来每日市值数据
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # start_date 	str 	Y 	开始时间
    # end_date 	str 	Y 	结束时间
    #
    # 输出参数
    # 名称 	类型 	描述
    # date 	str 	日期
    # marketcap 	float 	市值
    function get_coin_BTmarketValue(d_params :: Dict = Dict("start_date" => "20181224",
        "end_date" => "20181225"); s_api::String = "btc_marketcap",
        s_fields :: String = "
        date,
        marketcap")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Get btc price vol daily
    #     接口：btc_pricevol
    # 描述：获取比特币历史每日的价格和成交量数据。
    #
    # 输入参数
    # 名称 	类型 	必选 	描述
    # start_date 	str 	Y 	开始时间
    # end_date 	str 	Y 	结束时间
    #
    # 输出参数
    # 名称 	类型 	描述
    # date 	str 	日期
    # price 	float 	价格
    # volume 	float 	交易量
    function get_coin_BTpriceVol(d_params :: Dict = Dict("start_date" => "20181224",
        "end_date" => "20181225"); s_api::String = "btc_pricevol",
        s_fields :: String = "
        date ,
        price,
        volume")

        # Fetch Data
        c_data, c_fields = fetch_data(s_api, d_params, s_fields)
        if c_data != nothing && c_fields != nothing
            # Re-Organize Data
            df_data = reorgnize_data(c_data, c_fields)

        else
            error("Stock List fetch failed, Please Check: Field names, params or API change")
        end

        df_data
    end

    # Code Testing
    global s_tushare_api = "http://api.tushare.pro"
    global s_token = get_token()

end
