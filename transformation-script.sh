for (const item of $input.all()) {
  item.json.processed_at = new Date().toISOString();
  item.json.status = "DISPATCHED_TO_SLACK";
  item.json.original_severity = item.json.severity;
}
return $input.all();