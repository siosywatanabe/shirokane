#coding: utf-8
# HomeController
# Author:: Kazuko Ohmura
# Date:: 2013.07.25

class Admin::HomeController < ApplicationController
  before_filter :admin_authorize, :except => :login #ログインしていない場合はログイン画面に移動
  
  def index
  end
end