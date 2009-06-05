require 'ostruct'

module PufferFish
  module MigrationHelpers
    def self.included(target)
      mod = self.const_get(ActiveRecord::Base.connection.class.name.split("::").last.gsub("Adapter",""))
      target.extend(mod::ClassMethods)
    end
    
    def self.fetch_table_name(name, opts={})
      # Try to grab the ActiveRecord class first
      klass = Kernel.const_get(name.to_s.classify) rescue nil
      return klass.table_name if klass
      
      # OK just try to pluralize
      name.to_s.pluralize
    end
    
    def self.fetch_key_name(table_name, foreign=false, opt={})
      return opt[:foreign_key] if foreign && opt[:foreign_key]
      return opt[:primary_key] if !foreign && opt[:primary_key]
      if foreign
        "#{table_name.to_s.singularize}_id"
      else
        "id"
      end
    end
    
    def self.standardize_options(fk_table, pk_table, opts)
      keys = OpenStruct.new
      keys.primary_table_name = fetch_table_name(pk_table, opts)
      keys.foreign_table_name = fetch_table_name(fk_table, opts)
      keys.foreign_column_name = fetch_key_name(pk_table, true, opts)
      keys.primary_column_name = fetch_key_name(pk_table, false, opts)
      keys.key_name = "#{keys.foreign_table_name}_#{keys.foreign_column_name}_#{keys.primary_table_name}_fkey"
      keys
    end

    module Mysql
      module ClassMethods
        def add_foreign_key(fk_table, pk_table, opts={})
          keys = PufferFish::MigrationHelpers.standardize_options(fk_table, pk_table, opts)
          execute("ALTER TABLE #{keys.foreign_table_name} ADD CONSTRAINT #{keys.key_name} FOREIGN KEY (#{keys.foreign_column_name}) REFERENCES #{keys.primary_table_name} (#{keys.primary_column_name});")
        end

        def remove_foreign_key(fk_table, pk_table, opts={})
          keys = PufferFish::MigrationHelpers.standardize_options(fk_table, pk_table, opts)
          execute("ALTER TABLE #{keys.foreign_table_name} DROP FOREIGN KEY #{keys.key_name};")
        end
      end
    end

    module PostgreSQL
      module ClassMethods
        def add_foreign_key(fk_table, pk_table, opts={})
          fk = opts[:foreign_key] || "#{pk_table.to_s.singularize}_id"
          execute("ALTER TABLE #{fk_table} ADD FOREIGN KEY (#{fk}) REFERENCES #{pk_table};")
        end

        def remove_foreign_key(fk_table, pk_table)
          execute("ALTER TABLE #{fk_table} DROP CONSTRAINT #{fk_table}_#{pk_table.to_s.singularize}_id_fkey;")
        end
      end
    end
    
    module SQLite3
      module ClassMethods
        def add_foreign_key(fk_table, pk_table, opts={})
          # do nothing for now... this is just so that it works with sqlite3
        end

        def remove_foreign_key(fk_table, pk_table)
          # do nothing for now... this is just so that it works with sqlite3
        end
      end
    end
  end
end