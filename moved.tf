moved {
  from = aws_s3_bucket.zesty_cur_bucket
  to   = aws_s3_bucket.zesty_cur_bucket[0]
}

moved {
  from = aws_s3_bucket_public_access_block.cur_bucket
  to   = aws_s3_bucket_public_access_block.cur_bucket[0]
}

moved {
  from = aws_s3_bucket_policy.cur_bucket_policy
  to   = aws_s3_bucket_policy.cur_bucket_policy[0]
}

moved {
  from = aws_cur_report_definition.zesty_cur
  to   = aws_cur_report_definition.zesty_cur[0]
}

moved {
  from = aws_iam_role.glue_crawler_role
  to   = aws_iam_role.glue_crawler_role[0]
}

moved {
  from = aws_iam_policy.glue_crawler_policy
  to   = aws_iam_policy.glue_crawler_policy[0]
}

moved {
  from = aws_iam_role_policy_attachment.attach_glue_policy
  to   = aws_iam_role_policy_attachment.attach_glue_policy[0]
}

moved {
  from = aws_glue_crawler.zesty_cur_crawler
  to   = aws_glue_crawler.zesty_cur_crawler[0]
}

moved {
  from = aws_glue_catalog_database.zesty_cur_db
  to   = aws_glue_catalog_database.zesty_cur_db[0]
}

moved {
  from = aws_glue_catalog_table.cur
  to   = aws_glue_catalog_table.cur[0]
}

moved {
  from = aws_athena_workgroup.zesty_athena
  to   = aws_athena_workgroup.zesty_athena[0]
}

moved {
  from = local_file.kompass_values
  to   = local_file.kompass_values[0]
}
