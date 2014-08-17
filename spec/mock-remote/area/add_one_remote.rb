# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

class AddOneRemote < Citrus::AppRemote
  def do value, &block
    block.call nil, value + 1
  end

  def add_two value, &block
    block.call nil, value + 2
  end
end
