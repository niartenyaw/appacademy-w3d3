class ShortenedUrl < ActiveRecord::Base
  validates :long_url, presence: true
  validates :user_id, presence: true

  belongs_to :submitter,
    primary_key: :id,
    foreign_key: :user_id,
    class_name: :User

  has_many :visits, dependent: :destroy,
    primary_key: :id,
    foreign_key: :url_id,
    class_name: :Visit

  has_many :visitors,
    Proc.new { distinct },
    through: :visits,
    source: :visitor

  has_many :tags,
    primary_key: :id,
    foreign_key: :url_id,
    class_name: :Tagging

  has_many :tagged_topics,
    through: :taggings,
    source: :topic

  def self.prune(n)
    old_urls = ShortenedUrl.all.where('id NOT IN (?)',
      Visit.all.where(
        { updated_at: ((n+60).minutes.ago..1.hour.ago) }
      ).map(&:url_id))
    old_urls.each { |url| url.destroy }
  end

  def self.random_code
    code = nil
    until code && !ShortenedUrl.exists?(:short_url => code)
      code = SecureRandom.urlsafe_base64(16 * 3 / 4, false)
    end
    code
  end

  def self.shorten_url(user, long_url)
    s_url = ShortenedUrl.new
    s_url.user_id = user.id

    s_url.no_spamming
    s_url.nonpremium_max

    s_url.long_url = long_url
    s_url.short_url = ShortenedUrl.random_code

    s_url.save
    s_url
  end

  def num_clicks
    visits.count
  end

  def num_uniques
    unique_visits.count
  end

  def unique_visits
    visitors.count
  end

  def num_recent_uniques
    unique_visits.where({ updated_at: (10.minutes.ago..Time.now.utc) }).count
  end

  def no_spamming
    user = User.find(user_id)
    urls_in_last_minute = user.submitted_urls.where({
      updated_at: (1.minutes.ago..Time.now.utc)
    }).count

    raise "You can't submit more than 5 URLs per minute" if urls_in_last_minute >= 5
  end

  def nonpremium_max
    user = User.find(user_id)
    return if user.premium
    raise "You need a premium account to submit more than 5 URLs" if user.submitted_urls.count >= 5
  end

end
