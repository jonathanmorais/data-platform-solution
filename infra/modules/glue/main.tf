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

variable "cron" {
  type = string
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = "cleaned_${var.event.name}"
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "classification"      = "csv"
    "skip.header.line.count" = "1"
    "CrawlerSchemaSerializerVersion" = "1.0"
    "CrawlerSchemaDeserializerVersion"= "1.0"
    "columnsOrdered" = true
    "typeOfData" = "file"
    "delimiter" = ","
    "UPDATED_BY_CRAWLER" = aws_glue_crawler.events_crawler.name
  }

  storage_descriptor {

    location      = "s3://${var.bucket}/events/${var.event.scope}/${var.event.name}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "SimpleHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "serialization.format" = 1
        "field.delim" = ","
        "classification" = "csv"
      }
    }

    columns {
      name = "index"
      type = "string"
    }
    columns {
      name = "id"
      type = "string"
    }

    columns {
      name = "name"
      type = "string"
    }

    columns {
      name    = "abv"
      type    = "string"
    }

    columns {
      name    = "ibu"
      type    = "string"
    }

    columns {
      name    = "target_fg"
      type    = "string"
    }

    columns {
      name    = "target_og"
      type    = "string"
    }
    columns {
      name    = "ebc"
      type    = "string"
    }

    columns {
      name    = "srm"
      type    = "string"
    }

    columns {
      name    = "ph"
      type    = "string"
    }
  }

}

resource "aws_glue_crawler" "events_crawler" {
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name
  schedule      = "cron(${var.cron})"
  name          = "events_crawler"
  role          = aws_iam_role.glue_role.arn
  tags          = var.tags

  configuration = jsonencode(
    {
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas"
      }
      CrawlerOutput = {
        Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      }
      Version = 1
    }
  )

  s3_target {
    path = "s3://${var.bucket}/events/${var.event.scope}/${var.event.name}/"
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