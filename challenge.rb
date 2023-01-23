require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @title = "List of files"
  @public = Dir.glob("public/*").map {|file| File.basename(file)}.sort
  @public.reverse! if params[:sort] == "desc"

  erb :home
end

# get "/public/ravens.txt" do 
#   @content = File.read("public/ravens.txt")

#   erb :file
# end

# get "/public/patriots.txt" do
#   @content = File.read("public/patriots.txt")

#   erb :file
# end

# get "/public/giants.txt" do
#   @content = File.read("public/giants.txt")

#   erb :file
# end

# get "/public/chiefs.txt" do
#   @content = File.read("public/chiefs.txt")

#   erb :file
# end

# get "/public/jets.txt" do 
#   @content = File.read("public/jets.txt")

#   erb :file
# end

# get "/public/eagles.txt" do 
#   @content = File.read("public/eagles.txt")

#   erb :file
# end