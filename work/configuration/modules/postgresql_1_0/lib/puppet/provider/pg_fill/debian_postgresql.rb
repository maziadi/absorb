Puppet::Type.type(:pg_fill).provide(:debian_postgresql) do

  desc "Create tables in postgresql databases from external files"

  defaultfor :operatingsystem => [:debian, :ubuntu]

  optional_commands :psql => 'psql'
  optional_commands :su => 'su'

  def create
    su("-", "postgres", "-c", "psql '%s' < %s" % [ @resource.value(:database), @resource.value(:external_file) ])
  end

  def destroy
    su("-", "postgres", "-c", "psql -c \"drop table %s\" '%s'" % [ @resource.value(:check_table), @resource.value(:database) ])
  end

  def exists?
    su_output_table = su("-", "postgres", "-c", "psql --quiet -A -t -c \"select 1 from information_schema.tables where table_schema='public' and table_name='%s';\" '%s'" % [@resource.value(:check_table), @resource.value(:database) ])
    return false if su_output_table.length == 0
    su_output_table.each do |line|
      if line == "1\n"
        if @resource.value(:check_column).nil?
          return true
        else
          su_output_column = su("-", "postgres", "-c", "psql --quiet -A -t -c \"select 1 from information_schema.columns where table_name='%s' and column_name='%s';\" '%s'" % [@resource.value(:check_table), @resource.value(:check_column), @resource.value(:database) ])
          return false if su_output_column.length == 0
          su_output_column.each do |line|
            if line == "1\n"
              return true
            else
              return false
            end
          end
        end
      end
    end
  end

end
