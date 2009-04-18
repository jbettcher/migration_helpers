module PufferFish
  module MigrationHelpers
    def self.included(target)
      mod = self.const_get(ActiveRecord::Base.connection.class.name.split("::").last.gsub("Adapter",""))
      target.extend(mod::ClassMethods)
    end

    module Mysql
      module ClassMethods
        def add_foreign_key(fk_table, pk_table, opts={})
          pk_klass = Kernel.const_get(pk_table.to_s.classify)
          key_name = "#{fk_table}_#{pk_table.to_s.singularize}_id_fkey"
          execute("ALTER TABLE #{fk_table} ADD CONSTRAINT #{key_name} FOREIGN KEY (#{pk_table.to_s.singularize}_id) REFERENCES #{pk_table} (#{pk_klass.primary_key});")
        end

        def remove_foreign_key(fk_table, pk_table)
          key_name = "#{fk_table}_#{pk_table.to_s.singularize}_id_fkey"
          execute("ALTER TABLE #{fk_table} DROP FOREIGN KEY #{key_name};")
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