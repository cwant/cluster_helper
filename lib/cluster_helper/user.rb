require_relative 'concerns/like_a_user'

class ClusterHelper::User

  include LikeAUser

  attr_reader :username

  def initialize(username = nil)
    @username = if username.nil?
                  ENV['USER']
                else
                  username
                end
  end

end
