ActiveRecord::Base.class_eval do

  def self.relations_meta(combined_key, association_type)
    combined_key.singularize.camelize.constantize.reflect_on_all_associations(association_type).map{|r| [r.name, {foreign_key: r.options[:foreign_key], through: r.options[:through].to_s, class_name:  r.options[:source] || r.plural_name, table_name: r.options[:source]}]}.to_h
  end

  def self.with(params)
    self.find_with(self, self.table_name, params, self.table_name)
  end

  def self.find_with(relation, combined_key, params, current_table)
    params.keys.each do |key|      
      if params[key].is_a?(Hash)
        has_many_relations = relations_meta(combined_key, :has_many)
        has_one_relations = relations_meta(combined_key, :has_one)
        belongs_to_relations = relations_meta(combined_key, :belongs_to)
        has_and_belongs_to_many_relations = relations_meta(combined_key, :has_and_belongs_to_many)

        if has_many_relations.keys.include?(key)
          if(has_many_relations[key][:through].present?)
            join_scope = -> (rel) { rel.joins(%{
              inner join #{has_many_relations[key][:through]} 
                on #{has_many_relations[key][:through]}.#{current_table.singularize}_id = #{current_table}.id
              inner join #{has_many_relations[key][:class_name]}
                on #{has_many_relations[key][:class_name]}.#{has_many_relations[key][:through].singularize}_id = #{has_many_relations[key][:through]}.id
            })}
          else
            join_scope = -> (rel) { rel.joins(%{
              inner join #{has_many_relations[key][:class_name].underscore.pluralize} 
              on #{combined_key}.id = #{has_many_relations[key][:class_name].underscore.pluralize}.#{has_many_relations[key][:foreign_key] || "#{combined_key.singularize}_id"}
            })}
          end
          new_scope = -> (rel) { self.find_with(join_scope.call(relation), has_many_relations[key][:class_name].underscore.pluralize, params[key], has_many_relations[key][:class_name].underscore.pluralize) }
        elsif has_one_relations.keys.include?(key)
          join_scope = -> (rel) { rel.joins(%{
            inner join #{has_one_relations[key][:class_name].underscore.pluralize}
            on #{combined_key}.id = #{has_one_relations[key][:class_name].underscore.pluralize}.#{has_one_relations[key][:foreign_key] || "#{combined_key.singularize}_id"}
          })}
          new_scope = -> (rel) { self.find_with(join_scope.call(relation), has_one_relations[key][:class_name].underscore.pluralize, params[key], has_many_relations[key][:class_name].underscore.pluralize) }
        elsif belongs_to_relations.keys.include?(key)
          join_scope = -> (rel) { rel.joins(%{
            inner join #{belongs_to_relations[key][:class_name].underscore.pluralize}
            on #{combined_key}.#{belongs_to_relations[key][:class_name].underscore.singularize}_id = #{(belongs_to_relations[key][:source] || belongs_to_relations[key][:class_name])}.id
          })}
          new_scope = -> (rel) { self.find_with(join_scope.call(relation), belongs_to_relations[key][:class_name].underscore.pluralize, params[key], belongs_to_relations[key][:class_name].underscore.pluralize) }
        elsif has_and_belongs_to_many_relations.keys.include?(key)
          join_table = has_and_belongs_to_many_relations[key][:join_table] || [combined_key, key].sort.join('_')
          join_scope = -> (rel) { rel.joins(%{
            inner join #{join_table}
              on #{join_table}.#{combined_key.singularize}_id = #{combined_key}.id
            inner join #{has_and_belongs_to_many_relations[key][:class_name].underscore.pluralize}
              on #{join_table}.#{key.singularize}_id = #{has_and_belongs_to_many_relations[key][:class_name].underscore.pluralize}.id
          })}
          new_scope = -> (rel) { self.find_with(join_scope.call(relation), has_and_belongs_to_many_relations[key][:class_name].underscore.pluralize, params[key], has_and_belongs_to_many_relations[key][:class_name].underscore.pluralize) }
        end
          
      else
        new_scope = -> (rel) { rel.where( "#{combined_key}.#{key}" => params[key]) }
      end
      relation = new_scope.call(relation)
    end
    relation
  end
end