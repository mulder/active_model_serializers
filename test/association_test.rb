require "test_helper"

class AssociationTest < ActiveModel::TestCase
  def def_serializer(&block)
    Class.new(ActiveModel::Serializer, &block)
  end

  class Model
    def initialize(hash={})
      @attributes = hash
    end

    def read_attribute_for_serialization(name)
      @attributes[name]
    end

    def as_json(*)
      { :model => "Model" }
    end

    def method_missing(meth, *args)
      if meth.to_s =~ /^(.*)=$/
        @attributes[$1.to_sym] = args[0]
      elsif @attributes.key?(meth)
        @attributes[meth]
      else
        super
      end
    end
  end

  def setup
    @post = Model.new(:title => "New Post", :body => "Body")
    @comment = Model.new(:id => 1, :body => "ZOMG A COMMENT")
    @post.comments = [ @comment ]
    @post.comment = @comment

    @comment_serializer_class = def_serializer do
      attributes :body
    end

    @post_serializer_class = def_serializer do
      attributes :title, :body
    end

    @post_serializer = @post_serializer_class.new(@post, nil)

    @hash = {}
    @root_hash = {}
  end

  def include!(key, options={})
    @post_serializer.include! key, options.merge(
      :embed => :ids,
      :include => true,
      :hash => @root_hash,
      :node => @hash,
      :serializer => @comment_serializer_class
    )
  end

  class NoDefaults < AssociationTest
    def test_include_bang_has_many_associations
      include! :comments, :value => @post.comments

      assert_equal({
        :comments => [ 1 ]
      }, @hash)

      assert_equal({
        :comments => [
          { :body => "ZOMG A COMMENT" }
        ]
      }, @root_hash)
    end

    def test_include_bang_has_one_associations
      include! :comment, :value => @post.comment

      assert_equal({
        :comment => 1
      }, @hash)

      assert_equal({
        :comments => [{ :body => "ZOMG A COMMENT" }]
      }, @root_hash)
    end
  end

  class DefaultsTest < AssociationTest
    def test_with_default_has_many
      @post_serializer_class.class_eval do
        has_many :comments
      end

      include! :comments

      assert_equal({
        :comments => [ 1 ]
      }, @hash)

      assert_equal({
        :comments => [
          { :body => "ZOMG A COMMENT" }
        ]
      }, @root_hash)
    end
  end
end
