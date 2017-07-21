
require File.expand_path("../../test_helper", __FILE__)

class ElasticSearch::ModelTest < ElasticSearch::TestCase
  def test_notify_index
    klass = Class.new(Comment) do
      include ElasticSearch::Model

      notify_index CommentIndex
    end

    comment = klass.new(message: "message")

    assert_difference "CommentIndex.total_entries" do
      comment.save!
    end

    assert_difference "CommentIndex.total_entries", -1 do
      comment.destroy
    end
  end
end

