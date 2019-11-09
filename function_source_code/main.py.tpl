import urllib.request, json
def gcs_slack_notification(event, context):
	message = "New Object Created: %s" % event["name"]
	data = {"text": message}
	req = urllib.request.Request("${slack_webhook_url}", headers={"Content-type": "application/json"}, data=bytes(json.dumps(data),encoding="utf8"), method="POST")
	res = urllib.request.urlopen(req)
	if res.status != 200:
		raise RuntimeError("[%s] : %s" % (str(res.status), res.read().decode("utf-8")))