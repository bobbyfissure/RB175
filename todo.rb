require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"


configure do
  set :erb, :escape_html => true
end

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @lists = session[:lists] ||= []
end

get "/" do
  redirect "/lists"

  erb 
end

get "/lists" do
  @lists = session[:lists]
  @lists_clone = @lists.clone
  @sorted_list = sort_lists(@lists_clone)

  erb :lists , layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  if @list.nil?
    session[:error] = "That list does not exist."
    redirect "/lists"
  else
    erb :single_list, layout: :layout
  end
end

get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit, layout: :layout
end


def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name}
    "List name must be unique."
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo name must be between 1 and 100 characters."
  end
end

post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error_for_list_name(list_name)
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  @list = session[:lists][params[:id].to_i]
  if error
    session[:error] = error_for_list_name(list_name)
    erb :edit, layout: :layout
  else
    session[:lists][params[:id].to_i][:name] = list_name
    session[:success] = "List name has been updated."
    redirect "/lists/#{params[:id]}"
  end
end

post "/lists/:id/destroy" do
  session[:lists].delete_at(params[:id].to_i)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "This list has been deleted"
    redirect "/lists"
  end
end

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end


post "/lists/:list_id/todos" do
  @list_id = params[@list_id].to_i
  @list = session[:lists][params[@list_id].to_i]
  text = params[:todo].strip
  error = error_for_todo(text)
  if error
    session[:error] = error_for_todo(text)
    erb :single_list, layout: :layout
  else
    id = next_todo_id(@list[:todos])

    session[:lists][params[:list_id].to_i][:todos] << {id: id, name: text, completed: false}
    session[:success] = "The todo was added."
    redirect "/lists/#{params[:list_id].to_i}"
  end
end

post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[@list_id].to_i
  @list = session[:lists][params[:list_id].to_i]

  todo_id = params[:id].to_i
  @list[:todos].delete_at(todo_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "Todo deleted."
    redirect "/lists/#{params[:list_id].to_i}"
  end
end

post "/lists/:list_id/todos/:id" do
  @list = session[:lists][params[:list_id].to_i]
  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed

  session[:success] = "The todo has been updated."
  redirect "/lists/#{params[:list_id].to_i}"
end

post "/lists/:id/complete_all" do
  @list = session[:lists][params[:id].to_i]
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todos have been marked complete."
  redirect "/lists/#{params[:id].to_i}"
end

helpers do
  def list_complete?(list)
    list[:todos].size > 0 && list[:todos].all? {|todo| todo[:completed] }
  end

  def number_of_completed_todos(todos)
    todos.count { |todo| todo[:completed]}
  end

  def sort_lists(lists)
    lists.sort_by { |list| list_complete?(list) ? 1 : 0 }
  end

  def holder
    list[:todos].size > 0 && list[:todos].all? {|todo| todo[:completed] }
  end

  def find_idx_in_original(elem)
    @lists.find_index(elem)
  end
end