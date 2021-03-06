class Category < ActiveRecord::Base
	extend FriendlyId
  include PgSearch
  has_many :products

  friendly_id :name, use: :slugged
  validates_presence_of :name

  scope :with_products, -> { joins('LEFT OUTER JOIN products ON products.category_id = categories.id').where('products.category_id is not null').group('categories.id')}
  has_ancestry

  multisearchable :against => :name


  DEFAULT_URL = '/images/missing-categories.jpg'
  VALIDATE_SIZE = { :in => 0..5.megabytes, :message => 'Photo size too large. Please limit to 5 mb.' }
  has_attached_file :picture,
                    :styles => { large: '876x239#', medium: '270x270#', thumb: '100x100#' },
                    :default_url => DEFAULT_URL, :storage => :s3, :s3_credentials => Proc.new{|a| a.instance.s3_credentials}
  validates_attachment  :picture,
                        :content_type => { :content_type => /\Aimage\/.*\Z/},
                        :size => VALIDATE_SIZE


  def self.category_list
    category_order_array = ['Hardwood Floors','Doors','Porcelains','Bathroom','Walls']
    category_reorder_hash = {}

    category_order_array.each do |root|
      roo = roots.find_by_name(root)
      category_reorder_hash[roo.name] = roo.slug
    end

    return category_reorder_hash

  end

	def should_generate_new_friendly_id?
    slug.blank?
  end

	def s3_credentials
    {:bucket => ENV['s3_bucket'], :access_key_id => ENV['aws_access_key_id'], :secret_access_key => ENV['aws_access_secret']}
  end

    def parent_enum
    Category.where.not(id: id).map { |c| [ c.name, c.id ] }
  end

  def to_param
    (ancestors.pluck(:slug) << slug).join('/')
  end

  def self.find_by_ancestry_slug(slugs)
    self.friendly.find_by_slug(slugs.split('/').last)
  end
end
