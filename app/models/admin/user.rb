#coding: utf-8
# Admin::User Model
# Author:: Kazuko Ohmura
# Date:: 2013.07.25

# 管理用ユーザモデル
# == テーブル作成
# rails generate model user name:string title:string password_digest:string mail:string group_id:integer admin:boolean
# == 初期データ作成
# 管理者
# User.create!(:name => "admin", :password => "admin", :password_confirmation => "admin",:title=>'管理者',:mail=>'admin@admin.com',:group_id=>1,admin:1)
#
class Admin::User < ActiveRecord::Base
  #テーブル名の指定
  self.table_name = 'users'
  
  #パスワード用処理
  has_secure_password
  
  #グループ一覧用
  belongs_to :group
  
  #入力チェック
  validates :name,  :presence => true,:uniqueness=>true
  validates :title,  :presence => true
  validates :mail,  :presence => true,:uniqueness=>true, :email_format => {:message => I18n.t('error_mail_message')}
end
