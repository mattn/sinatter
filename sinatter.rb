require 'rubygems'
require 'sinatra'
require 'sequel'
require 'haml'
require 'sass'
Sequel::Model.plugin(:schema)
DB = Sequel.sqlite("db/sinatter.db")

set :sessions, true
set :environment, :no_test
set :public, File.dirname(__FILE__) + '/static'

class Status < Sequel::Model
  set_schema do
    primary_key :id
    string :user
    text :text
    timestamp :created_at
  end

  def date
    self.created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def formatted_text
    Rack::Utils.escape_html(self.text).gsub(/\n/, "<br>")
  end
end
Status.create_table unless Status.table_exists?

class User < Sequel::Model
  set_schema do
    primary_key :id
    string :user
    string :mail
    string :password
    string :image
    timestamp :created_at
  end

  def date
    self.created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def formatted_text
    Rack::Utils.escape_html(self.text).gsub(/\n/, "<br>")
  end
end
User.create_table unless User.table_exists?

helpers do
  include Rack::Utils; alias_method :h, :escape_html
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

get '/register' do
  haml :register
end

put '/register' do
  if request[:user] and request[:password]
    User.create({
      :user => request[:user].strip,
      :password => request[:password].strip,
      :image => request[:image],
      :created_at => Time.now,
    }) unless User.find(:user=>request[:user].strip)
    redirect '/'
  else
    haml :login
  end
end

get '/login' do
  haml :login
end

put '/login' do
  if User.find(:user=>request[:user].strip, :password=>request[:password].strip)
    session[:user] = request[:user].strip
    redirect '/home'
  else
    haml :login
  end
end

get '/logout' do
  session.delete(:user)
  redirect "/"
end

get '/' do
  redirect '/login' unless session[:user]
  redirect '/home'
end

get '/home' do
  redirect '/login' unless session[:user]
  @statuses = Status.order_by(:created_at.desc).limit(10)
  haml :home
end

put '/home' do
  redirect '/login' unless session[:user]
  Status.create({
    :user => session[:user],
    :text => request[:text],
    :created_at => Time.now,
  })
  redirect '/home'
end

get '/replies' do
  redirect '/login' unless session[:user]
  @statuses = Status.filter(:text.like("@#{session[:user]} %")).order_by(:created_at.desc).limit(10)
  haml :replies
end

get '/user/:user' do
  redirect '/login' unless session[:user]
  @statuses = Status.filter(:user => params["user"]).order_by(:created_at.desc).limit(10)
  haml :user
end

get '/statuses/:id' do
  @status = Status.find(:id => params["id"])
  haml :status
end

get '/setting' do
  redirect '/login' unless session[:user]
  @setting = User.find(:user=>session[:user])
  haml :setting
end

put '/setting' do
  redirect '/login' unless session[:user]
  @setting = User.find(:user=>session[:user])
  @setting.password = request[:password]
  @setting.image = request[:image]
  @setting.save(:password, :image)
  haml :setting
end


