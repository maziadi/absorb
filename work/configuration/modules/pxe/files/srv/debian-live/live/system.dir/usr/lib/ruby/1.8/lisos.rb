
require 'fileutils'
require 'yaml'

PERSISTENT_MOUNT="/live/persistent"
FILE_VERSION="/etc/version.yaml"

def get_cmdline(pattern)
        cmdline=File::new("/proc/cmdline", "r").readlines[0].split(" ")
        cmdline.each do |item|
                arg = item.split("=")
                return arg[1] if (arg[0]==pattern)
        end
        return nil
end

def sh(commands)
        system "#{commands}"
        exitStatus=$?
        if exitStatus!=0
                fail "Command failed with status (#{exitStatus}): [#{commands}]"
        end
end


def retryCmd(commands,nb,timeToSleep)
        exitStatus = 0
        nb.downto(1) do |i|
                system "#{commands}"
                exitStatus = $?
                if exitStatus == 0 then
                        return exitStatus
                else
                        sleep timeToSleep
                end
        end
        fail "Command failed with status (#{exitStatus}): [#{commands}]"
end


def mountPersistent(options = {})
	media=get_cmdline("live-media")
	if media.nil?
		puts "Cannot find persistent device"
		exit(-1)
	end
	media="#{media}2"

	FileUtils.mkdir_p "#{PERSISTENT_MOUNT}"
  if `mount`.scan("#{PERSISTENT_MOUNT}").size != 0
    sh "mount -o remount,rw #{PERSISTENT_MOUNT}"
  else
    $umount_persistent = true
    if `mount`.scan("#{media}").size != 0
      puts "#{media} if already mount, please umount before"
      exit -1
    end
    opt = ""
    opt = "-o ro" if options[:readonly]

	  sh "mount #{opt} #{media}  #{PERSISTENT_MOUNT}"
  end
	FileUtils.mkdir_p "#{PERSISTENT_MOUNT}/current"
	FileUtils.mkdir_p "#{PERSISTENT_MOUNT}/old"
end
def umountPersistent
	if $umount_persistent
    retryCmd("umount #{PERSISTENT_MOUNT}",2,2)
  else
    retryCmd("mount -o remount,ro #{PERSISTENT_MOUNT}",2,2)
  end
end

def loadLisosConfig()
  if File::file?("/etc/version.yaml")
	  return YAML::load(File::new("/etc/version.yaml"))
  else
	  return YAML::load(File::new("/etc/lisos_version"))
  end
end
