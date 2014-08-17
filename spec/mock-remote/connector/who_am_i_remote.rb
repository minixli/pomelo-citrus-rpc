# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

class WhoAmIRemote < Citrus::AppRemote
  def do &block
    block.call nil, @app[:server_id]
  end
end
