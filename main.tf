#
# Module Provider
#

provider "google" {
  region = "${var.region}"
}

data "google_client_config" "current" {}

#
# Render Cloud Function source code template to include Slack Webhook URL
#
  
data "template_file" "templated_code" {
  template = "${file("${path.module}/function_source_code/main.py.tpl")}"
  vars = {
    slack_webhook_url = "${var.slack_webhook_url}"
  }
}

resource "local_file" "output_file" {
    content     = "${data.template_file.templated_code.rendered}"
    filename = "${path.module}/templated_function_source_code/main.py"
}

#
# Create ZIP archive for Cloud Function source code
#

data "archive_file" "gcs_slack_notification_function_zip" {
  type = "zip"
  output_path = "${path.module}/gcs_slack_notification_function.zip"
  source_dir = "${path.module}/templated_function_source_code/"
}

#
# Deploy Cloud Function
#
 
resource "google_storage_bucket_object" "source_archive_object" {
  name   = "gcs_slack_notification_function.zip"
  bucket = "${var.source_archive_bucket}"
  source = "${path.module}/gcs_slack_notification_function.zip"
}

resource "google_cloudfunctions_function" "function" {
	name = "gcs-slack-notification-demo"
	runtime = "python37"
	description = "Triggers a Slack notification for new objects being created"
	available_memory_mb = "128"
	timeout = 60
	source_archive_bucket = "${var.source_archive_bucket}"
	source_archive_object = "${google_storage_bucket_object.source_archive_object.name}"
	entry_point = "gcs_slack_notification"
	event_trigger {
		event_type = "${var.event_type}"
		resource = "${var.resource}"
	}
}