class TagTopic < ActiveRecord::Base
  validates :topic, presence: true

  has_many :taggings,
    primary_key: :id,
    foreign_key: :topic_id,
    class_name: :Tagging

  has_many :tagged_urls,
    through: :taggings,
    source: :url

  def popular_links
    pops = tagged_urls.sort_by { |url| url.num_clicks }.reverse.take(5)
    pops.map { |url| [url, url.num_clicks] }
  end

end
