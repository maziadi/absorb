Puppet::Type.type(:pg_fill).provide(:default) do

  desc "A default pg_fill provider which just fails."

  def create
    return false
  end

  def destroy
    return false
  end

  def exists?
    fail('This is just the default provider for pg_fill, all it does is fail')
  end

end
