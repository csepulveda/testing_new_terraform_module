resource "aws_keyspaces_keyspace" "keyspace" {
  name = "keyspace"
}

#tables:
resource "aws_keyspaces_table" "keyspace-first-table" {
  keyspace_name = aws_keyspaces_keyspace.keyspace.name
  table_name    = "first_table"

  schema_definition {
    column {
      name = "message"
      type = "ascii"
    }

    partition_key {
      name = "message"
    }
  }
}