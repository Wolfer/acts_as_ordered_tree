require "active_record"
require "acts_as_ordered_tree/version"
require "acts_as_ordered_tree/class_methods"
require "acts_as_ordered_tree/instance_methods"
require "acts_as_ordered_tree/iterator"

module ActsAsOrderedTree
  # == Usage
  #   class Category < ActiveRecord::Base
  #     acts_as_ordered_tree :parent_column => :parent_id,
  #                          :position_column => :position,
  #                          :depth_column => :depth,
  #                          :counter_cache => :children_count
  #   end
  def acts_as_ordered_tree(options = {})
    options = {
      :parent_column   => :parent_id,
      :position_column => :position,
      :depth_column    => :depth
    }.merge(options)

    class_attribute :acts_as_ordered_tree_options, :instance_writer => false
    self.acts_as_ordered_tree_options = options

    # create associations
    has_many   :children,
               :class_name    => name,
               :foreign_key   => options[:parent_column],
               :order         => options[:position_column],
               :dependent     => :destroy,
               :inverse_of    => (:parent unless options[:polymorphic]),
               :before_add    => options[:before_add],
               :after_add     => options[:after_add],
               :before_remove => options[:before_remove],
               :after_remove  => options[:after_remove]

    belongs_to :parent,
               :class_name => name,
               :foreign_key => options[:parent_column],
               :counter_cache => options[:counter_cache],
               :inverse_of => (:children unless options[:polymorphic])

    define_model_callbacks :move, :reorder

    extend  Columns
    include Columns
    include ClassMethods
    include InstanceMethods

    # protect position&depth from mass-assignment
    attr_protected depth_column, position_column
  end # def acts_as_ordered_tree

  # Mixed into both classes and instances to provide easy access to the column names
  module Columns
    def parent_column
      acts_as_ordered_tree_options[:parent_column]
    end

    def position_column
      acts_as_ordered_tree_options[:position_column]
    end

    def depth_column
      acts_as_ordered_tree_options[:depth_column]
    end

    def children_counter_cache_column
      reflections[:parent].counter_cache_column.try(:to_sym)
    end
  end
end # module ActsAsOrderedTree

ActiveRecord::Base.extend(ActsAsOrderedTree)