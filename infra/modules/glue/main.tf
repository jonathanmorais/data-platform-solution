variable "event" {
  type = object({
    name    = string
    scope   = string
  })
}


variable "tags" {
  type = map(string)
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = "event_${var.event.scope}_${var.event.name}"
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
    "classification"      = "parquet"
  }

}

resource "aws_glue_catalog_database" "aws_glue_catalog_database" {
  name = "ml_platform_events"
}

output "table_name" {
  value = aws_glue_catalog_table.aws_glue_catalog_table.name
}

output "database_name" {
  value = aws_glue_catalog_database.aws_glue_catalog_database.name

}