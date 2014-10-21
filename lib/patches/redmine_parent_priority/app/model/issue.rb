module ParentPriority
	module IssueModelPatch
		def self.included(base)
			base.send(:include, InstanceMethods)

			base.class_eval do
				unloadable

				def inherit_priority(issue, priority_id, user)
					return if issue.status.is_closed?
					return if issue.priority_id == priority_id
					issue.init_journal(user)
					issue.priority_id = priority_id
					issue.save(:validate => false)

					issue.children.each do |child|
						inherit_priority(child, priority_id, user)
					end
				end

				  # The code is based on original Redmine's code (read it LICENSE file, please)
				  # https://github.com/redmine/redmine/blob/78120536b15e723feacb1552396d85665010d8eb/app/models/issue.rb
				  def safe_attributes_with_parent_priority_unlock=(attrs, user=User.current)
				    return unless attrs.is_a?(Hash)

				    Rails.logger.info('qwee')
				    Rails.logger.info($affected)
				    $affected = Array.new if $affected.nil?
				    $affected.push(self.id)
				    $affected = $affected.compact

				    attrs = attrs.deep_dup
				
				    # Project and Tracker must be set before since new_statuses_allowed_to depends on it.
				    if (p = attrs.delete('project_id')) && safe_attribute?('project_id')
				      if allowed_target_projects(user).where(:id => p.to_i).exists?
				        self.project_id = p
				      end
				    end
				
				    if (t = attrs.delete('tracker_id')) && safe_attribute?('tracker_id')
				      self.tracker_id = t
				    end
				
				    if (s = attrs.delete('status_id')) && safe_attribute?('status_id')
				      if new_statuses_allowed_to(user).collect(&:id).include?(s.to_i)
				        self.status_id = s
				      end
				    end
				
				    attrs = delete_unsafe_attributes(attrs, user)
				    return if attrs.empty?
				
				    unless leaf?
				      attrs.reject! {|k,v| %w(done_ratio start_date due_date estimated_hours).include?(k)}
				      if attrs[:priority_id] != self.priority_id
				        self.children.each do |child|
				          inherit_priority(child, attrs[:priority_id], user)
				        end
				      end
				    end
				
				    if attrs['parent_issue_id'].present?
				      s = attrs['parent_issue_id'].to_s
				      unless (m = s.match(%r{\A#?(\d+)\z})) && (m[1] == parent_id.to_s || Issue.visible(user).exists?(m[1]))
				        @invalid_parent_issue_id = attrs.delete('parent_issue_id')
				      end
				    end
				
				    if attrs['custom_field_values'].present?
				      editable_custom_field_ids = editable_custom_field_values(user).map {|v| v.custom_field_id.to_s}
				      attrs['custom_field_values'].select! {|k, v| editable_custom_field_ids.include?(k.to_s)}
				    end
				
				    if attrs['custom_fields'].present?
				      editable_custom_field_ids = editable_custom_field_values(user).map {|v| v.custom_field_id.to_s}
				      attrs['custom_fields'].select! {|c| editable_custom_field_ids.include?(c['id'].to_s)}
				    end
				
				    # mass-assignment security bypass
				    assign_attributes attrs, :without_protection => true
				    $affected.pop(self.id)
				  end
				  def update_parent_attributes_with_parent_priority_unlock
				    update_parent_attributes_without_parent_priority_unlock unless $affected.include? parent_id
				  end

				alias_method_chain :update_parent_attributes, :parent_priority_unlock
				alias_method_chain :safe_attributes=,         :parent_priority_unlock
			end
		end

		module InstanceMethods
		end
	end
end

Issue.send(:include, ParentPriority::IssueModelPatch)

