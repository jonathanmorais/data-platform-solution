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
      name = "id"
      type = "int"
    }

    columns {
      name = "name"
      type = "string"
    }

    columns {
      name    = "abv"
      type    = "float"
    }

    columns {
      name    = "ibu"
      type    = "float"
    }

    columns {
      name    = "target_fg"
      type    = "int"
    }

    columns {
      name    = "target_og"
      type    = "int"
    }
    columns {
      name    = "ebc"
      type    = "float"
    }

    columns {
      name    = "srm"
      type    = "float"
    }

    columns {
      name    = "ph"
      type    = "float"
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