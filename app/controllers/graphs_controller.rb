#coding: utf-8
# UsersController
# Author:: Kazuko Ohmura
# Date:: 2013.07.31

require 'csv'

#グラフ表示
class GraphsController < PublichtmlController
  before_filter :authorize, :except => :login #ログインしていない場合はログイン画面に移動
  # グラフ用画面
  def index
    # グラフIDの指定が無い場合はルートへ移動
    redirect_to root_path
  end
  
  #csv出力
  def csvexport
    # 表示可能グラフチェック
    return redirect_to :root if !check_graph_permission(params[:id]) 
          
    # 指定グラフ情報
    @graph = Graph.find(params[:id])
      
    # 表示テーブル名の設定
    Tdtable.table_name = "td_" + @graph.name
    
    # 取得期間
    @start_day = params[:start];
    @end_day = params[:end];
    
    # データ取得
    @tdtable = Tdtable.where(:td_time => @start_day .. @end_day).order(:td_time)
    data = CSV.generate do |csv|
      csv << ["time", "value"]
      @tdtable.each do |td|
        csv << [td.td_time, td.td_count]
      end
    end
    # ファイル名
    fname =  @graph.name.to_s + "_#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}.csv"
    # 出力
    send_data(data, type: 'text/csv', filename: fname)    
  end
  
  # 表示用処理
  def show
    # 表示可能グラフチェック
    return redirect_to :root if !check_graph_permission(params[:id]) 
      
    #コンボボックスの値設定
    @h_analysis_types = {0 => t('analysis_types_sum'),1 => t('analysis_types_avg')}
    @h_terms ={0=> t('terms_day'),1 => t('terms_week'),2 => t('terms_month'),3 => t('terms_year')}
    
    #グラフ選択枝
    @graph_types = ['line','bar','pie']
          
    #指定グラフ情報
    @graph = Graph.find(params[:id])
      
    #設定の取得
    ss = Setting.all
    @gconf = Hash.new()
    ss.map{|s|
      @gconf[s.name] = s.parameter
    }
    
    #表示期間指定
    if params[:term] then
      @graph_term = params[:term].to_i
    else
      @graph_term = @graph.term
    end
    
    #期間移動分
    @today = Date.today
    
    #期間の設定
    @add = 0 #追加日数初期化
    @add = params[:add] if params[:add]
    case @graph_term
    when 1  #週:７日分の日別データを表示する
      @today = @today + (@add.to_i * 7).days if params[:add] # 追加日数
      @oldday = @today - 7.days
      @term = @oldday.month.to_s + "." + @oldday.day.to_s + " - " + @today.month.to_s + "." + @today.day.to_s
      stime = "%d"
    when 2  #月:１ヶ月分のデータを表示する
      @today = @today + @add.to_i.months if params[:add] # 追加日数
      @oldday = @today - 1.month
      @term = @oldday.month.to_s + "." + @oldday.day.to_s + " - " + @today.month.to_s + "." + @today.day.to_s
      stime = "%d"
    when 3  #年:１ヶ月ごとのデータを表示する。
      @today = @today + @add.to_i.years if params[:add] # 追加日数
      @oldday = @today - 1.year
      @term = @oldday.year.to_s + "." + @oldday.month.to_s + " - " + @today.year.to_s + "." + @today.month.to_s
      stime = "%m"
    else    #0か指定なしは１日の集計
      @today = @today + @add.to_i.days if params[:add] # 追加日数
      @oldday = @today
      @term = @today.month.to_s + "." + @today.day.to_s
      stime = "%H"
    end

    # データ取得期間の設定
    @today_s = @today.to_s + " 23:59:59"
    @oldday_s = @oldday.to_s + " 00:00:00"
    # データの取得
    tdtable = td_graph_data(@graph.name,@graph_term,@graph.analysis_type,@oldday_s,@today_s)

    # グラフ表示用データ作成
    @xdata = ""
    @ydata = ""
    tdtable.each do |dd|
      @xdata = @xdata + "," + dd.td_time.strftime(stime)
      @ydata = @ydata + "," + dd.td_count.to_i.to_s
    end
  end
  
  private
  # グラフが利用可能かをチェックする
  def check_graph_permission(p_graph_id)
    return Groupgraph.exists?({:group_id=>current_user.group.id,:graph_id=>p_graph_id}) 
  end
end