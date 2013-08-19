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
  
  #csv出力処理
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
    @h_graphsize_width = {0 => 600,1 => 720,2 => 300}
    @h_graphsize_height = {0 => 400,1 => 480,2 => 200}
    @h_yesno = {0=>'no' , 1 => 'yes'}
    
    #グラフ選択枝
    @graph_types = ['line','bar','pie']
          
    #指定グラフ情報
    @graph = Graph.find(params[:id])
      
    # 指定テンプレート情報
    templates = Graphtemplate.where({:name => @graph.template})
    @template = templates[0]

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
      # 月曜日から開始するように調整
      @today = @today + (7-@today.wday).days
      @oldday = @today - 6.days
      @term = @oldday.month.to_s + t("datetime.prompts.month") + @oldday.day.to_s + t("datetime.prompts.day") + " - " + @today.month.to_s + t("datetime.prompts.month") + @today.day.to_s + t("datetime.prompts.day")
      stime = "%d"
    when 2  #月:１ヶ月分のデータを表示する
      @today = @today + @add.to_i.months if params[:add] # 追加日数
      # 月初から開始するように調整
      nowmonth = Date::new(@today.year,@today.month, 1)
      @today = nowmonth >> 1
      @today = @today - 1.day
      @oldday = nowmonth
      @term = @oldday.year.to_s + t("datetime.prompts.year") + @oldday.month.to_s + t("datetime.prompts.month")
      stime = "%d"
    when 3  #年:１ヶ月ごとのデータを表示する。
      @today = @today + @add.to_i.years if params[:add] # 追加日数
      # 年初から開始するように調整
      nowyear = Date::new(@today.year,1, 1)
      @today = nowyear + 1.year - 1.day
      @oldday = nowyear
      @term = @oldday.year.to_s + t("datetime.prompts.year")
      stime = "%m"
    else    #0か指定なしは１日の集計
      @today = @today - 1.day
      @today = @today + @add.to_i.days if params[:add] # 追加日数
      @oldday = @today
      @term = @today.month.to_s + t("datetime.prompts.month") + @today.day.to_s + t("datetime.prompts.day")
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
