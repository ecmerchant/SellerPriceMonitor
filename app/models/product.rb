class Product < ApplicationRecord

  require 'peddler'
  require 'date'
  require 'csv'
  require 'kconv'

  def crawl(user)
    #MWSにアクセス
    mp = "A1VC38T7YXB528"
    temp = Account.find_by(user: user)
    sid = temp.seller_id
    skey = temp.secret_key
    awskey = temp.aws_key
    border = temp.stock_border
    apitoken = temp.cw_api_token
    roomid = temp.cw_room_id
    roomid2 = temp.cw_room_id2
    roomid3 = temp.room_id3
    roomid4 = temp.room_id4
    ucheck = temp.used_check

    ids = temp.cw_ids

    tt = Product.where(user: user)

    tt.update(jriden: false, riden: false)

    #asinlist = tt.pluck(:asin)
    asinlist = tt.pluck(:sku)
    client = MWS.products(
      primary_marketplace_id: mp,
      merchant_id: sid,
      aws_access_key_id: awskey,
      aws_secret_access_key: skey
    )

    asins = []

    j = 0

    asinlist.each do |taisn, i|
      asins.push(taisn)
      if j == 9 || i == asinlist.length - 1 then
        asins.slice!(j, 9 - asins.length)

        logger.debug('======= ASIN =========')
        logger.debug(asins)
        logger.debug('======= ASIN END =========')

        response = client.get_lowest_offer_listings_for_sku(asins,{item_condition:"New", exclude_me: "false"})
        response2 = client.get_lowest_offer_listings_for_sku(asins,{item_condition:"New", exclude_me: "true"})
        response3 = client.get_competitive_pricing_for_sku(asins)
        response4 = client.get_my_price_for_sku(asins)


        parser = response.parse
        parser2 = response2.parse
        parser3 = response3.parse
        parser4 = response4.parse

        uhash = {}
        parser.each do |product|
          asin = product.dig('Product', 'Identifiers', 'MarketplaceASIN', 'ASIN')
          sku = product.dig('Product', 'Identifiers', 'SKUIdentifier', 'SellerSKU')
          tprice = 0
          buf = product.dig('Product', 'LowestOfferListings', 'LowestOfferListing')
          buf1 = product.dig('Product', 'LowestOfferListings')
          tnum = 0
          validity = false

          logger.debug("===== LowestOfferListing =====")

          if buf1 != nil then
            #出品アリ
            validity = true
            if buf.class == Array then
              #複数出品
              ch1 = false
              ch2 = false
              buf.each do |ttt, k|
                if ttt.dig('Qualifiers', 'FulfillmentChannel') == 'Amazon' then
                  ch1 = true
                elsif ttt.dig('Qualifiers', 'FulfillmentChannel') == 'Merchant' then
                  ch2 = true
                end
                tnum = tnum + ttt.dig('NumberOfOfferListingsConsidered').to_i
              end
              tprice =  buf[0].dig('Price', 'LandedPrice', 'Amount').to_i
            else
              tprice =  buf.dig('Price', 'LandedPrice', 'Amount').to_i
            end
          end
          if buf == nil then
            temp = tt.find_by(sku: sku)
            if temp != nil then
              temp.update(validity: false)
            end
          end
          if sku != nil then
            uhash[sku] = {asin: asin, sku:sku, validity: validity}
            th = uhash[sku]
            if ch1 == false || ch2 == false then
              tnum = 0
            end
            th[:snum] = tnum
            th[:price] = tprice
            uhash[sku] = th
            temp = tt.find_by(sku: sku)
            if temp != nil then
              temp.update(validity: true)
            end
          else
            logger.debug("=== SKU ERROR ===")
            logger.debug(product)
            sku = product.dig('SellerSKU')
            temp = tt.find_by(sku: sku)
            if temp != nil then
              temp.update(validity: false)
            end
          end
        end

        parser2.each do |product|
          asin = product.dig('Product', 'Identifiers', 'MarketplaceASIN', 'ASIN')
          sku = product.dig('Product', 'Identifiers', 'SKUIdentifier', 'SellerSKU')
          buf = product.dig('Product', 'LowestOfferListings', 'LowestOfferListing')
          buf1 = product.dig('Product', 'LowestOfferListings')
          tnum = 0
          if buf1 != nil then
            #出品アリ
            if buf.class == Array then
              #複数出品
              buf.each do |ttt|
                if ttt.dig('Qualifiers', 'ItemCondition') == "New" then
                  tnum = tnum + ttt.dig('NumberOfOfferListingsConsidered').to_i
                end
              end
            else
              if buf.dig('Qualifiers', 'ItemCondition') == "New" then
                tnum = buf.dig('NumberOfOfferListingsConsidered').to_i
              end
            end
          else
            tnum = 0
          end
          if sku != nil then
            th = uhash[sku]
            th[:rnum] = tnum
            uhash[sku] = th
          end
        end


        if ucheck == true then
          logger.debug("==== Check Used Price ====")
          response5 = client.get_lowest_offer_listings_for_sku(asins,{item_condition:"Used", exclude_me: "true"})
          parser5 = response5.parse
          parser5.each do |product|
            asin = product.dig('Product', 'Identifiers', 'MarketplaceASIN', 'ASIN')
            sku = product.dig('Product', 'Identifiers', 'SKUIdentifier', 'SellerSKU')
            buf = product.dig('Product', 'LowestOfferListings', 'LowestOfferListing')
            buf1 = product.dig('Product', 'LowestOfferListings')
            tnum = 0
            logger.debug(asin)
            logger.debug(sku)
            if buf1 != nil then
              #出品アリ
              if buf.class == Array then
                #複数出品
                buf.each do |ttt|
                  if ttt.dig('Qualifiers', 'ItemCondition') == "Used" then
                    tnum = tnum + ttt.dig('NumberOfOfferListingsConsidered').to_i
                  end
                end
              else
                if buf.dig('Qualifiers', 'ItemCondition') == "Used" then
                  tnum = buf.dig('NumberOfOfferListingsConsidered').to_i
                end
              end
            else
              tnum = 0
            end
            if sku != nil then
              th = uhash[sku]
              th[:urnum] = tnum
              uhash[sku] = th
              logger.debug(tnum)
            end
          end
        end

        #カート価格の確認
        logger.debug("==== Check Cart Price ====")
        parser3.each do |product|
          ch = product.dig('Product', 'CompetitivePricing', 'CompetitivePrices', 'CompetitivePrice', 'belongsToRequester')
          cp = product.dig('Product', 'CompetitivePricing', 'CompetitivePrices', 'CompetitivePrice', 'Price', 'LandedPrice', 'Amount').to_i

          sku = product.dig('Product', 'Identifiers', 'SKUIdentifier', 'SellerSKU')
          logger.debug("====*****======")
          if ch == "true" then
            temps = tt.find_by(sku: sku)
            if temps != nil then
              temps.update(is_cart_price: true, cart_price: cp)
            end
          elsif ch == "false" then
            temps = tt.find_by(sku: sku)
            if temps != nil then
              temps.update(is_cart_price: false, cart_price: cp)
              #t_asin = temps.asin
              #======カート価格未取得=======
              #logger.debug("==== Not Cart ====")
              #msg = "注意!:カート未取得!!\n" + "ASIN: " + t_asin + "\n" + "URL: https://www.amazon.co.jp/dp/" + t_asin
              #stask(msg, apitoken,roomid3, ids)

              #通知後にチェック
              #t_asin = temps.asin
              #ttt = tt.where(asin: t_asin)
              #ttt.update(checked: true)
            end
          else
            temps = tt.find_by(sku: sku)
            if temps != nil then
              temps.update(is_cart_price: false, cart_price: cp)
            end
          end
        end

        #出品価格の確認
        logger.debug('======= My price =========')
        parser4.each do |product|
          sku = product.dig('Product', 'Identifiers', 'SKUIdentifier', 'SellerSKU')
          tp = product.dig('Product', 'Offers', 'Offer')
          if tp.class == Array then
            logger.debug('======CASE MULTI========')
            tp.each do |ttt|
              ta = ttt.dig('BuyingPrice', 'ListingPrice', 'Amount').to_i
              tr = ttt.dig('RegularPrice', 'Amount').to_i
              sku = ttt.dig('SellerSKU')
              th = uhash[sku]
              if th != nil then
                th[:price] = ta
                th[:rprice] = tr
                #th[:validity] = true
                if ta == tr then
                  th[:onsale] = false
                else
                  th[:onsale] = true
                end
              else
                th = Hash.new
                th[:price] = ta
                th[:rprice] = tr
                #th[:validity] = true
                if ta == tr then
                  th[:onsale] = false
                else
                  th[:onsale] = true
                end
              end
              uhash[sku] = th
            end
          elsif tp.class == Hash
            ta = tp.dig('BuyingPrice', 'LandedPrice', 'Amount').to_i
            tr = tp.dig('RegularPrice', 'Amount').to_i
            th = uhash[sku]
            th[:price] = ta
            #th[:validity] = true
            th[:rprice] = tr
            if ta == tr then
              th[:onsale] = false
            else
              th[:onsale] = true
            end
            uhash[sku] = th
          elsif tp == nil then
            temps = tt.find_by(sku: sku)
            if temps != nil then
              temps.update(validity: false)
            end
          end
        end

        logger.debug('======= HASH =========')
        logger.debug(uhash)
        logger.debug('======= HASH END =========')

        uhash.each do |ss|
          logger.debug('======= Info Start =========')
          t_asin = ss[1][:asin]
          t_sku = ss[1][:sku]
          t_price = ss[1][:price]
          t_snum = ss[1][:snum]
          t_rnum = ss[1][:rnum]
          t_unum = ss[1][:urnum]
          t_onsale = ss[1][:onsale]
          t_rp = ss[1][:rprice]

          logger.debug(t_asin)
          logger.debug(t_sku)
          logger.debug(t_price)
          logger.debug(t_snum)
          logger.debug(t_rnum)
          logger.debug('======= unum =========')
          logger.debug(t_unum)
          t_rnum = t_rnum.to_i + t_unum.to_i
          logger.debug(t_rnum)
          logger.debug('======= unum =========')



          temps = tt.find_by(sku: t_sku)
          if temps == nil then break end
          logger.debug(temps.validity)
          logger.debug('======= Info END =========')
          #temps = tt.where(asin: t_asin)

          if t_snum > 1 && t_rnum == 0 then
            temps.update(jriden: true)
            msg = "注意!: 自社相乗り \n" + "ASIN: " + t_asin + "\n" + "URL: https://www.amazon.co.jp/dp/" + t_asin
          else
            temps.update(jriden: false)
          end
          if t_rnum > 0 then
            temps.update(riden: true)
            if t_unum.to_i == 0 then
              msg = "【警告!!】: 他社相乗り \n" + "ASIN: " + t_asin + "\n" + "URL: https://www.amazon.co.jp/dp/" + t_asin
            else
              msg = "【警告!!】: 他社相乗り(中古あり) \n" + "ASIN: " + t_asin + "\n" + "URL: https://www.amazon.co.jp/dp/" + t_asin
            end
          else
            temps.update(riden: false)
          end
          if t_price > 0 then
            temps.update(price: t_price)
          end

          temps.update(on_sale: t_onsale, regular_price: t_rp)

          #通知の条件
          #1. 相乗りがあり
          #2. チェックがなし

          #カート監視
          if temps.is_cart_price == false && temps.validity == true then
            t_asin = temps.asin
            #======カート価格未取得=======
            logger.debug("==== Not Cart ====")
            if temps.checked2 != true then
              msg = "注意!:カート未取得!!\n" + "ASIN: " + t_asin + "\n" + "URL: https://www.amazon.co.jp/dp/" + t_asin
              stask(msg, apitoken,roomid3, ids)
              #通知後にチェック
              ttt = tt.where(asin: t_asin)
              ttt.update(checked2: true)
            end
          end

          if t_snum > 0 || t_rnum > 0 then
            if t_snum > 1 && t_rnum == 0 then
              if temps.checked2 != true then
                #   自社相乗り
                #3. FBA在庫があり(0でない)
                #4. ボーダーより多い
                if temps.fba_stock != nil then
                  if temps.fba_stock > border then
                    logger.debug("==== Alert ====")
                    stask(msg, apitoken,roomid, ids)

                    #通知後にチェック
                    t_asin = temps.asin
                    ttt = tt.where(asin: t_asin)
                    ttt.update(checked2: true)
                  end
                end
              end
            elsif t_rnum > 0 then
              if temps.checked != true then
                #   他社相乗り
                #無条件
                if t_unum.to_i == 0 then
                  stask(msg, apitoken,roomid2, ids)
                else
                  if temps.checked3 != true then
                    stask(msg, apitoken,roomid2, ids)
                    t_asin = temps.asin
                    ttt = tt.where(asin: t_asin)
                    ttt.update(checked3: true)
                  end
                end
              end
            end
          end

          logger.debug("=== FBA在庫数確認 ===")
          logger.debug(t_sku[-2,2])
          if temps.is_fba == true && temps != nil then
            if temps.fba_stock != nil then
              if temps.fba_stock.to_i < 10 && temps.fba_stock.to_i > 0 && temps.jriden != true && temps.checked2 != true  then
                t_asin = temps.asin
                msg = "注意!: 出品1 ＆ FBA在庫10個以下 !!\n" +  "SKU: " + t_sku + "\n" +  "ASIN: " + t_asin + "\n" + "FBA在庫数: " + temps.fba_stock.to_s  + "\nURL: https://www.amazon.co.jp/dp/" + t_asin
                stask(msg, apitoken, roomid4, ids)
                #通知後にチェック
                ttt = tt.where(asin: t_asin)
                ttt.update(checked2: true)
              end
            end
          end

        end

        asins = []
        j = 0
      else
        j += 1
      end
    end
    logger.debug("==== Total ====")
    logger.debug(asinlist.length)
  end

  #FBA在庫数の確認
  def fba_check(user)
    logger.debug("\n===== Start FBA check =====")
    mp = "A1VC38T7YXB528"
    temp = Account.find_by(user: user)
    sid = temp.seller_id
    skey = temp.secret_key
    awskey = temp.aws_key
    products = Product.where(user:user)

    dt = DateTime.now.gmtime
    endate = dt.yesterday.beginning_of_day.ago(9.hours).iso8601
    stdate = dt.yesterday.beginning_of_day.ago(9.hours).iso8601

    #report_type = "_GET_FBA_FULFILLMENT_CURRENT_INVENTORY_DATA_"
    report_type = "_GET_AFN_INVENTORY_DATA_"

    mws_options = {
      start_date: stdate,
      end_date: endate
    }
    logger.debug(mws_options)
    client = MWS.reports(
      primary_marketplace_id: mp,
      merchant_id: sid,
      aws_access_key_id: awskey,
      aws_secret_access_key: skey
    )

    #response = client.request_report(report_type, mws_options)
    response = client.request_report(report_type)

    parser = response.parse
    reqid = parser.dig('ReportRequestInfo', 'ReportRequestId')

    mws_options = {
      report_request_id_list: reqid,
    }
    process = ""
    logger.debug(reqid)
    while process != "_DONE_" && process != "_DONE_NO_DATA_"
      response = client.get_report_request_list(mws_options)
      parser = response.parse
      process = parser.dig('ReportRequestInfo', 'ReportProcessingStatus')
      logger.debug(process)
      if process == "_DONE_" then
        genid = parser.dig('ReportRequestInfo', 'GeneratedReportId')
        break
      elsif process == "_DONE_NO_DATA_" then
        genid = "NODATA"
        break
      end
      sleep(10)
    end


    products.update(fba_stock: 0)

    logger.debug("====== generated id =======")
    logger.debug(genid)

    if genid.to_s != "NODATA" then
      response = client.get_report(genid)
      parser = response.parse
      logger.debug("====== report data is ok =======\n")
      parser.each do |row|
        if row[4] == 'SELLABLE' then
          tsku = row[0]
          tasin = row[2]
          quantity = row[5]
          #t1 = products.find_by(sku: tsku)
          t1 = products.where(asin: tasin)
          if t1 != nil then
            t1.update(fba_stock: quantity)
          end

          t2 = products.find_by(sku: tsku)
          if t2 != nil then
            t2.update(is_fba: true)
          end

          logger.debug("SKU: " + tsku + " ,FBA stock: " + quantity.to_s)
        end
      end
    end
    logger.debug("\n===== End FBA check =====\n")
  end

  def revise (user, tag)
    fba = ""
    #fba = "AMAZON_JP"
    products = Product.where(user: user)
    mp = "A1VC38T7YXB528"
    temp = Account.find_by(user: user)
    sid = temp.seller_id
    skey = temp.secret_key
    awskey = temp.aws_key
    apitoken = temp.cw_api_token
    roomid = temp.cw_room_id
    roomid2 = temp.cw_room_id2
    ids = temp.cw_ids

    client = MWS.feeds(
      primary_marketplace_id: mp,
      merchant_id: sid,
      aws_access_key_id: awskey,
      aws_secret_access_key: skey
    )

    stream = ""
    File.open('app/others/Flat_File_Price_Inventory_Updates_JP.txt') do |file|
    #File.open('app/others/Flat.File.Listingloader.jp.txt') do |file|
      file.each_line do |row|
        stream = stream + row
      end
    end
    st = Date.today.strftime("%Y-%m-%d") + "T00:00:00+09:00"
    tag.each do |key, value|
      temp = products.find_by(sku:key)
      sjudge = temp.on_sale
      rprice = temp.regular_price
      on_fba = temp.is_fba
      price = value[:price]
      ed = value[:end_date] + "T00:00:00+09:00"

      if on_fba == true then
        fba = "AMAZON_JP"
      else
        fba = ""
      end

      if sjudge == true then
        row = [key, rprice, "","JPY","","","PartialUpdate",price,"",st,ed,"",fba]
      else
        row = [key, price, "","JPY","","","PartialUpdate","","","","","",fba]
      end
      part = row.join("\t")
      stream = stream + part + "\n"
    end

    stream = stream.tosjis
    logger.debug(stream)

    #new_body = feed_body.encode(Encoding::Windows_31J)
    feed_type = "_POST_FLAT_FILE_LISTINGS_DATA_"
    parser = client.submit_feed(stream, feed_type)
    doc = Nokogiri::XML(parser.body)
    submissionId = doc.xpath(".//mws:FeedSubmissionId", {"mws"=>"http://mws.amazonaws.com/doc/2009-01-01/"}).text
    return submissionId

  end

  def msend(message, api_token, room_id)
    base_url = "https://api.chatwork.com/v2"
    endpoint = base_url + "/rooms/" + room_id  + "/messages"
    request = Typhoeus::Request.new(
      endpoint,
      method: :post,
      params: { body: message },
      headers: {'X-ChatWorkToken'=> api_token}
    )
    request.run
    res = request.response.body
    logger.debug(res)
  end

  def stask(message, api_token, room_id, to_ids)
    base_url = "https://api.chatwork.com/v2"
    endpoint = base_url + "/rooms/" + room_id  + "/tasks"
    request = Typhoeus::Request.new(
      endpoint,
      method: :post,
      params: { body: message, to_ids: to_ids },
      headers: {'X-ChatWorkToken'=> api_token}
    )
    request.run
    res = request.response.body
    logger.debug(res)
  end

end
