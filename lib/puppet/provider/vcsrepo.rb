require 'tmpdir'
require 'digest/md5'
require 'fileutils'

# Abstract
class Puppet::Provider::Vcsrepo < Puppet::Provider

  def check_force
    if path_exists? and not path_empty? and working_copy_exists?
      if @resource.value(:force)
        notice "Removing %s to replace with desired repository." % @resource.value(:path)
        destroy
      else
        raise Puppet::Error, "Path %s exists and is not the desired repository." % @resource.value(:path)
      end
    end
  end

  private

  def set_ownership
    owner = @resource.value(:owner) || nil
    group = @resource.value(:group) || nil
    FileUtils.chown_R(owner, group, @resource.value(:path))
  end

  def path_exists?
    File.directory?(@resource.value(:path))
  end

  def path_empty?
    # Path is empty if the only entries are '.' and '..'
    d = Dir.new(@resource.value(:path))
    d.read # should return '.'
    d.read # should return '..'
    d.read.nil?
  end

  # Note: We don't rely on Dir.chdir's behavior of automatically returning the
  # value of the last statement -- for easier stubbing.
  def at_path(&block) #:nodoc:
    value = nil
    Dir.chdir(@resource.value(:path)) do
      value = yield
    end
    value
  end

  def tempdir
    @tempdir ||= File.join(Dir.tmpdir, 'vcsrepo-' + Digest::MD5.hexdigest(@resource.value(:path)))
  end

end
