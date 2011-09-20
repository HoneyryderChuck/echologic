class StatementData < ActiveRecord::Base
  belongs_to :statement
  
  # TODO: This is not used yet! This will be activated when it is possible to update files
#  has_attached_file :image, :default_url => "/images/default_:style_statement_image.png"
#  validates_attachment_size :image, :less_than => 5.megabytes
#  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/png', 'image/pjpeg', 'image/x-png', 'doc' ...]
#  before_post_process :image?
#  def image?
#    !(data_content_type =~ /^image.*/).nil?
#  end
end
