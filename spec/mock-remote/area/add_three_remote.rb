# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

class AddThreeRemote < Citrus::AppRemote
  def do value, &block
    block.call nil, value + 3
  end
end
