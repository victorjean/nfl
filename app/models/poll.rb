class Poll
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :user
  has_many :poll_options, :dependent => :destroy
  accepts_nested_attributes_for :poll_options, :allow_destroy => true, :reject_if => :all_blank
  attr_accessible :poll_options_attributes, :question, :week, :scoring, :note, :votes, :max_vote_options, :user_votes, :user, :subtitle
  validate :valid_poll
  validates :note, :length => {:maximum => 240}
  
  scope :week, ->(week){ where(week: week)}
    
  QUESTION_TYPES = ["Who should I start?",
                    "Who should I pick up?"]
                   
  SCORING_TYPES = ["Traditional",
                  "Performance",
                  "PPR"]
  
  field :question,          type: String
  field :subtitle,          type: String
  field :week,              type: Integer, default: DateHelper::get_week(Time.now)
  field :scoring,           type: String 
  field :note,              type: String
  #field :votes,             type: Integer, default: 0
  field :max_vote_options,  type: Integer, default: 1
  #field :user_votes,        type: Hash, default: {}
  field :expired,           type: Boolean
  
  def total_votes
    v = 0
    self.poll_options.each do |poll_option|
      v += poll_option.users.count
    end
    return v
  end
    
  def user_total_votes(user)
    v = 0
    self.poll_options.each do |poll_option|
      v += 1 if poll_option.voted?(user)
    end
    return v
  end
  
  def user_votes_left(user)
    self.max_vote_options - self.user_total_votes(user)
  end
  
  def can_vote?(user)
    self.max_vote_options - self.user_total_votes(user) > 0
  end  
  
  def voted?(user)
    self.user_votes_left(user) == 0
  end
  
  def editable?
    return self.total_votes == 0 && !self.expired?
  end
  
  def expired?
    if DateHelper::get_week(Time.now) > self.week
      self.expired = true
    end
    self.poll_options.each do |poll_option|
      self.expired = true if poll_option.expired?      
    end
    self.save
    self.expired
  end
  
  private
    def valid_poll
      if self.poll_options.length < 2
        errors[:valid_poll]= "You must provide at least 2 players."
      end
      if self.poll_options.length <= self.max_vote_options
        errors[:valid_poll]= "You must have less choices (#{self.poll_options.length}) than possible options (#{max_vote_options})."
      end
    end

    
  
end