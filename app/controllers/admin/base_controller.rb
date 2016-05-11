class Admin::BaseController < ApplicationController

	# Cancan won't work here, so we use verify_admin
	before_filter :verify_admin

	def index
		value = Settings.find_by_var('users_csv')
		if value
			@latest_csv_date = value.updated_at.strftime("digisub-%Y-%m-%d-%H:%M:%S")
		else
			@latest_csv_date = nil
		end
	end

	def welcome_email
		@greeting = 'Hi'
		@issue = Issue.latest
		@issues = Issue.where(published: true).last(8).reverse
		@user = current_user

		respond_to do |format|
			format.mjml {
				render "user_mailer/user_signup_confirmation", :layout => false
			}
			format.text {
				render "user_mailer/user_signup_confirmation", :layout => false
			}
		end
	end

	def subscription_email
		@greeting = 'Hi'
		@issue = Issue.latest
		@issues = Issue.where(published: true).last(8).reverse
		@subscription = Subscription.first
		@user = @subscription.user

		if params[:subscription_type] == "free"
			@template = "user_mailer/free_subscription_confirmation"
		else
			@template = "user_mailer/subscription_confirmation"
		end

		respond_to do |format|
			format.mjml {
				render @template, :layout => false
			}
			format.text {
				render @template, :layout => false
			}
		end
	end

	def magazine_purchase_email
		@greeting = 'Hi'
		@issues = Issue.where(published: true).last(8).reverse
		@purchase = Purchase.first
		@issue = @purchase.issue
		@user = @purchase.user
		@template = "user_mailer/issue_purchase"

		respond_to do |format|
			format.mjml {
				render @template, :layout => false
			}
			format.text {
				render @template, :layout => false
			}
		end
	end

	private

	def verify_admin
		redirect_to root_url unless (current_user and current_user.admin?)
	end
	
end
