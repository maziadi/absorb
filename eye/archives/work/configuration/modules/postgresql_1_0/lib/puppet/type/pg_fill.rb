# This has to be a separate type to enable collecting
Puppet::Type.newtype(:pg_fill) do
  @doc = "Create tables in a postgresql database from external files."

  ensurable

  newparam(:name, :namevar=>true) do
    desc "The name of the table to add."
  end

  newparam(:database) do
    desc "The name of the database."

    defaultto :postgres
  end

  newparam(:external_file) do
    desc "The external file to use."
  end

  newparam(:check_table) do
    desc "check the existence of the table."
  end

  newparam(:check_column) do
    desc "check the existence of the column."

    munge do |column|
      case column
      when false, "nil", nil
        nil
      else
        column
      end
    end
  end

end
