const items = $input.all();

let report = {
  volumes: [],
  s3_buckets: [],
  security_groups: []
};

for (const item of items) {
  const data = item.json;

  // 1. Updated EBS Detection: Look for volumeId directly
  if (data.volumeId) {
    report.volumes.push(data);
  } 
  
  // 2. S3 Detection: Look for Bucket Name or ARN
  else if (data.BucketArn || (data.Name && data.CreationDate)) {
    report.s3_buckets.push(data);
  } 
  
  // 3. Security Group Detection: Look for SG name and network rules
  else if (data.name && (data.cidr || data.port)) {
    report.security_groups.push(data);
  }
}

return [{ json: report }];