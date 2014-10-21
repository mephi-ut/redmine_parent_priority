# encoding: UTF-8
require 'redmine'

require_dependency 'patches/redmine_parent_priority/app/model/issue'

Redmine::Plugin.register :redmine_parent_priority do
	name 'Redmine parent priority unlocking plugin'
	description 'A redmine plugin to unlock parent priority changing'
	url 'https://github.com/mephi-ut/redmine_parent_priority'
	author 'Dmitry Yu Okunev'
	author_url 'https://github.com/xaionaro'
	version '0.0.1'
end


