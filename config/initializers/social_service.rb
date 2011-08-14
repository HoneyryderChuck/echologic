require 'social_service/acts_as_social'
require 'social_service/social_service'
require 'social_service/rpx_service'
require 'social_service/sharing_job'

ActiveRecord::Base.send :include, ActiveRecord::Acts::Social

SocialService.instance.service = RpxService.new(RPX_API_KEY, "https://#{RPX_APP_NAME}", nil)
SocialService.instance.sharing_providers=%w(facebook twitter yahoo! linkedin google)
SocialService.instance.default_echo_image='images/page/echo_o.png'