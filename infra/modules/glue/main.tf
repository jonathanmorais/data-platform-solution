variable "event" {
  type = object({
    name    = string
    scope   = string
  })
}

variable "bucket" {
  type = string
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

  storage_descriptor {

    location      = "s3://${var.bucket}/events/${var.event.scope}/${var.event.name}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

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