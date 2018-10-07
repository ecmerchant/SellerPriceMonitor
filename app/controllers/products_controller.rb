class ProductsController < ApplicationController

  require 'nokogiri'
  require 'uri'
  require 'csv'
  require 'peddler'
  require 'typhoeus'
  require 'date'
  require 'kconv'
  require 'rubyXL'
  require 'tempfile'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def show
    @login_user = current_user
    #temp = Product.find_or_create_by(user:current_user.email)
    @products = Product.where(user:current_user.email, validity: true, check_riden: true)
  end

  def delete
    Product.delete_all
    redirect_to root_url
  end

  def check
    if params[:commit] == "監視開始" then
      #temp = Product.new
      #temp.crawl(current_user.email)
      RiderCheckJob.perform_later(current_user.email)
    end
    redirect_to products_show_path
  end

  def update
    label = params[:commit]

    if label == "確認状況の更新" then
      logger.debug(label)
      tag = params[:chk]
      if tag != nil then
        products = Product.where(user:current_user.email)
        logger.debug(tag)
        tag.each do |tasin|
          logger.debug(tasin)
          tm = products.where(asin: tasin)
          if tm != nil then
            tm.update(checked: true)
          end
        end
      end
      redirect_to products_show_path
    else
      logger.debug(label)
      tag = params[:chk_upd]
      pr = params[:rev]
      ed = params[:end_date]

      temp = Product.where(user:current_user.email)

      if tag != nil then
        org = Hash.new

        tag.each do |key|
          asin = key
          price = pr[key]
          edate =  ed[key]
          skus = temp.where(asin: asin)
          skus.each do |sku|
            org[sku.sku] = {price: price, end_date: edate}
          end
        end

        logger.debug(org)

        jj = Account.find_by(user:current_user.email)
        if jj != nil then
          pp = jj.test_mode
        else
          pp = false
        end
        if pp == true then
          feedid = 1000.to_s
        else
          a = Product.new
          feedid = a.revise(current_user.email, org)
        end
        logger.debug("====FEED ID=====")
        logger.debug(feedid)

        body = ""
        t = Time.new
        strtime = t.strftime("%Y年%m月%d日 %H:%M:%S")
        tstamp = t.strftime("%Y%m%d%H%M%S")

        body = "価格改定ログ\n"
        body = body + "実行日時：" + strtime   +  "\n"
        body = body + "フィードID：" + feedid.to_s + "\n"
        body = body + "\n"
        body = body + "ASIN,SKU,カート価格,改定前の価格,改定後の価格" + "\n"

        temp = Product.where(user:current_user.email)

        org.each do |key, value|
          sku = key
          aprice = value
          t1 = temp.find_by(sku: sku)
          bprice = t1.price
          cprice = t1.cart_price
          asin = t1.asin
          row = asin.to_s + "," + sku.to_s + "," + cprice.to_s + "," + bprice.to_s + "," + aprice.to_s + "\n"
          body = body + row
        end
        logger.debug(body)

        filename = '価格改定ログ_' + tstamp + '.txt'
        fpath = Rails.root.join('tmp', filename)

        logger.debug(fpath)
        body.tosjis
        #open(fpath, 'w'){|f|
        #  f.puts body
        #}

        send_data(body, filename: filename, type: 'text/plain')

        #send_file(fpath)
      else
        redirect_to products_revise_path
      end
    end

  end

  def setup
    @login_user = current_user
    @account = Account.find_or_create_by(user:current_user.email)
    if request.post? then
      @account.update(user_params)
    end
  end

  def report
    user = current_user.email
    GetReportJob.perform_later(user)
    redirect_to products_show_path
  end

  def revise
    @login_user = current_user
    @products = Product.where(user:current_user.email, priced: true, validity: true)
  end

  def upload
    if request.post? then
      data = params[:file]
      if data != nil then
        ext = File.extname(data.path)
        logger.debug(ext)
        if ext == ".xls" || ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          temp = Product.where(user:current_user.email)
          dflag = 'false'
          logger.debug(dflag)
          worksheet.each_with_index do |row, i|
            logger.debug(dflag)
            logger.debug(i)
            if i != 0 then
              if dflag != 'true' then
                sku = row[0].value.to_s
                asin = row[1].value.to_s

                sku = sku.gsub(/\t/,"")
                sku = sku.strip()

                asin = asin.gsub(/\t/,"")
                asin = asin.strip()
                logger.debug("SKU: " + sku + " , ASIN: " + asin)

                temp2 = temp.find_or_create_by(asin:asin, sku:sku)
                temp2.update(check_riden: true, validity: true)
                if row[2] != nil then
                  temp2.update(memo:row[2].value.to_s)
                end
              else
                logger.debug("SKU: " + row[0].value.to_s)
                tts = temp.find_by(sku: row[0].value.to_s)
                if tts != nil then
                  tts.delete
                end
                logger.debug("Delete SKU")
              end
            else
              if row[0].value.to_s == "Delete" then
                dflag = 'true'
                logger.debug(" == Delete SKU == ")
              end
            end
          end
        elsif ext == ".txt" then
          list = CSV.read(data.path, {headers:true, encoding:'Windows_31J:UTF-8', col_sep: "\t"})
          temp = Product.where(user:current_user.email)
          list.each do |row|
            logger.debug("SKU: " + row[0].to_s + " , ASIN: " + row[3].to_s)
            temp2 = temp.find_or_create_by(asin:row[3].to_s, sku:row[0].to_s)
          end
        end
      end
    end
    redirect_to products_show_path
  end

  def price_upload
    if request.post? then
      data = params[:file]
      if data != nil then
        ext = File.extname(data.path)
        logger.debug(ext)
        if ext == ".xls" || ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          temp = Product.where(user:current_user.email)
          dflag = 'false'
          worksheet.each_with_index do |row, i|
            if i != 0 then
              if dflag != 'true' then
                sku = row[0].value.to_s
                asin = row[1].value.to_s

                sku = sku.gsub(/\t/,"")
                sku = sku.strip()

                asin = asin.gsub(/\t/,"")
                asin = asin.strip()
                logger.debug("SKU: " + sku + " , ASIN: " + asin)

                temp2 = temp.find_or_create_by(asin:asin, sku:sku)
                if row[2] != nil then
                  temp2.update(memo:row[2].value.to_s)
                end
                temp2.update(priced: true, validity: true)
              else
                temp.find_by(sku: row[0].value.to_s).delete
                logger.debug("Delete SKU")
              end
            else
              if row[0].value.to_s == "Delete" then
                dflag = 'true'
                logger.debug(" == Delete SKU == ")
              end
            end
          end
        elsif ext == ".txt" then
          list = CSV.read(data.path, {headers:true, encoding:'Windows_31J:UTF-8', col_sep: "\t"})
          temp = Product.where(user:current_user.email)
          list.each do |row|
            logger.debug("SKU: " + row[0].to_s + " , ASIN: " + row[3].to_s)
            temp2 = temp.find_or_create_by(asin:row[3].to_s, sku:row[0].to_s)
          end
        end
      end
    end
    redirect_to products_revise_path
  end

  def reset
    temp = Product.where(user:current_user.email)
    temp.update(checked: false, checked2: false, checked3: false)
    redirect_to products_revise_path
  end

  private
  def user_params
     params.require(:account).permit(:user, :seller_id, :aws_key, :secret_key, :stock_border, :cw_api_token, :cw_room_id, :cw_room_id2, :room_id3, :room_id4, :roomid3, :cw_ids, :used_check)
  end

end
